"""Database service for persistent storage."""

from typing import List, Dict, Any, Optional
from datetime import datetime
import json
from dataclasses import dataclass
import json
from sqlalchemy import create_engine, Column, String, Float, JSON, DateTime, Text, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from contextlib import contextmanager

from ..core.config import get_settings
from ..core.logging import get_logger
from ..models.dto import AnalyzeResponse, DocumentChunk

logger = get_logger(__name__)
Base = declarative_base()


class StartupRecord(Base):
    """Startup analysis record."""
    __tablename__ = "startups"
    
    startup_id = Column(String, primary_key=True)
    name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Questionnaire data
    questionnaire_data = Column(JSON)  # All questionnaire responses
    
    # Analysis results
    score = Column(Float, default=70)  # Investment score
    risks = Column(JSON, default=list)  # Risk factors
    latest_score = Column(Float)
    latest_recommendation = Column(String)
    latest_analysis = Column(JSON)  # Full analysis response
    
    # KPIs
    arr = Column(Float)
    growth_rate = Column(Float)
    gross_margin = Column(Float)
    burn_rate = Column(Float)
    runway_months = Column(Integer)
    
    # Documents
    documents = Column(JSON)  # List of document IDs
    chunks_count = Column(Integer)
    
    # Q&A collected data
    questionnaire_responses = Column(JSON)
    data_collection_method = Column(String)  # "upload" | "questionnaire" | "both"


class DocumentRecord(Base):
    """Document storage record."""
    __tablename__ = "documents"
    
    document_id = Column(String, primary_key=True)
    startup_id = Column(String, index=True)
    filename = Column(String)
    content_type = Column(String)
    storage_path = Column(String)
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    
    # Processing status
    processed = Column(String, default="pending")  # pending|processing|completed|failed
    chunks = Column(JSON)  # Chunk IDs
    extra_metadata = Column(JSON)  # Renamed from metadata to avoid conflict


class QuestionnaireResponse(Base):
    """Questionnaire response storage."""
    __tablename__ = "questionnaire_responses"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    startup_id = Column(String, index=True)
    question_id = Column(String)
    question = Column(Text)
    answer = Column(Text)
    confidence = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Validation and enrichment
    validated = Column(String)  # For human validation
    enrichment_data = Column(JSON)  # External data sources


class DatabaseService:
    """Database operations service."""
    
    def __init__(self, connection_string: str = None):
        """Initialize database service.
        
        Args:
            connection_string: Database connection string
        """
        self.settings = get_settings()
        
        # Use provided connection string or settings
        if connection_string:
            self.engine = create_engine(connection_string)
        elif self.settings.DATABASE_URL:
            self.engine = create_engine(self.settings.DATABASE_URL)
        else:
            # Use SQLite with proper path
            from pathlib import Path
            db_path = Path(self.settings.SQLITE_PATH)
            db_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Use check_same_thread=False for SQLite to work with FastAPI
            self.engine = create_engine(
                f"sqlite:///{db_path}",
                connect_args={"check_same_thread": False},
                pool_pre_ping=True
            )
        
        # Create tables
        Base.metadata.create_all(self.engine)
        
        # Create session factory
        self.SessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=self.engine
        )
        
        logger.info(f"Database initialized: {self.engine.url}")
    
    @contextmanager
    def get_session(self) -> Session:
        """Get database session context manager."""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()
    
    def get_startup(self, startup_id: str) -> Optional[Dict[str, Any]]:
        """Get startup data by ID."""
        try:
            with self.get_session() as session:
                # Try to get from StartupRecord table
                record = session.query(StartupRecord).filter_by(startup_id=startup_id).first()
                if record:
                    return {
                        "startup_id": record.startup_id,
                        "questionnaire_responses": record.questionnaire_data or {},
                        "analysis_score": record.score or 70,
                        "top_risks": record.risks or [],
                        "updated_at": record.updated_at.isoformat() if record.updated_at else None
                    }
                return None
        except Exception as e:
            logger.error(f"Failed to get startup: {e}")
            return None
    
    def list_startups(self, limit: int = 10, offset: int = 0) -> List[Dict[str, Any]]:
        """List all startups."""
        try:
            with self.get_session() as session:
                records = session.query(StartupRecord).limit(limit).offset(offset).all()
                return [
                    {
                        "startup_id": r.startup_id,
                        "questionnaire_responses": r.questionnaire_data or {},
                        "analysis_score": r.score or 70,
                        "top_risks": r.risks or [],
                        "updated_at": r.updated_at.isoformat() if r.updated_at else None
                    }
                    for r in records
                ]
        except Exception as e:
            logger.error(f"Failed to list startups: {e}")
            return []
    
    def save_startup(self, startup_id: str, analysis: AnalyzeResponse) -> bool:
        """Save or update startup record.
        
        Args:
            startup_id: Startup identifier
            analysis: Analysis results
            
        Returns:
            Success status
        """
        with self.get_session() as session:
            record = session.query(StartupRecord).filter_by(
                startup_id=startup_id
            ).first()
            
            if not record:
                record = StartupRecord(startup_id=startup_id)
            
            # Update fields
            record.latest_score = analysis.score
            record.latest_recommendation = analysis.recommendation.value
            record.latest_analysis = analysis.dict()
            
            # Update KPIs
            if analysis.kpis:
                record.arr = analysis.kpis.arr
                record.growth_rate = analysis.kpis.growth_rate
                record.gross_margin = analysis.kpis.gross_margin
                record.burn_rate = analysis.kpis.burn_rate
                record.runway_months = analysis.kpis.runway_months
            
            session.add(record)
            return True
    
    
    def save_questionnaire_response(
        self,
        startup_id: str,
        responses: Dict[str, Any]
    ) -> bool:
        """Save all questionnaire responses at once.
        
        Args:
            startup_id: Startup identifier
            responses: Dictionary of all responses
            
        Returns:
            Success status
        """
        with self.get_session() as session:
            try:
                # Save or update startup record with questionnaire data
                record = session.query(StartupRecord).filter_by(
                    startup_id=startup_id
                ).first()
                
                if not record:
                    record = StartupRecord(
                        startup_id=startup_id,
                        name=responses.get('company_name', startup_id),  # Extract company name
                        questionnaire_data=responses,
                        questionnaire_responses=responses,  # Save to both fields for compatibility
                        score=70,  # Default score
                        # Extract key metrics directly
                        arr=float(responses.get('arr', 0)) if responses.get('arr') else None,
                        growth_rate=float(responses.get('growth_rate', 0)) if responses.get('growth_rate') else None,
                        gross_margin=float(responses.get('gross_margin', 0)) if responses.get('gross_margin') else None,
                        burn_rate=float(responses.get('burn_rate', 0)) if responses.get('burn_rate') else None,
                        runway_months=int(responses.get('runway', 0)) if responses.get('runway') else None
                    )
                    session.add(record)
                else:
                    record.name = responses.get('company_name', record.name or startup_id)
                    record.questionnaire_data = responses
                    record.questionnaire_responses = responses  # Save to both fields for compatibility
                    record.updated_at = datetime.utcnow()
                    # Update key metrics
                    record.arr = float(responses.get('arr', 0)) if responses.get('arr') else record.arr
                    record.growth_rate = float(responses.get('growth_rate', 0)) if responses.get('growth_rate') else record.growth_rate
                    record.gross_margin = float(responses.get('gross_margin', 0)) if responses.get('gross_margin') else record.gross_margin
                    record.burn_rate = float(responses.get('burn_rate', 0)) if responses.get('burn_rate') else record.burn_rate
                    record.runway_months = int(responses.get('runway', 0)) if responses.get('runway') else record.runway_months
                
                session.commit()
                return True
                
            except Exception as e:
                logger.error(f"Failed to save questionnaire: {e}")
                return False
    
    def save_single_questionnaire_response(
        self,
        startup_id: str,
        question_id: str,
        question: str,
        answer: str,
        confidence: float = 1.0
    ) -> bool:
        """Save questionnaire response.
        
        Args:
            startup_id: Startup identifier
            question_id: Question identifier
            question: Question text
            answer: Answer text
            confidence: Answer confidence
            
        Returns:
            Success status
        """
        try:
            with self.get_session() as session:
                # Check if response already exists
                existing = session.query(QuestionnaireResponse).filter_by(
                    startup_id=startup_id,
                    question_id=question_id
                ).first()
                
                if existing:
                    # Update existing response
                    existing.answer = answer
                    existing.confidence = confidence
                    existing.created_at = datetime.utcnow()
                else:
                    # Create new response
                    response = QuestionnaireResponse(
                        startup_id=startup_id,
                        question_id=question_id,
                        question=question,
                        answer=answer,
                        confidence=confidence
                    )
                    session.add(response)
                
                session.commit()
                return True
        except Exception as e:
            logger.error(f"Failed to save questionnaire response: {str(e)}")
            return False
    
    def get_questionnaire_responses(
        self,
        startup_id: str
    ) -> List[Dict[str, Any]]:
        """Get all questionnaire responses for startup.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            List of responses
        """
        with self.get_session() as session:
            responses = session.query(QuestionnaireResponse).filter_by(
                startup_id=startup_id
            ).all()
            
            return [
                {
                    "question_id": r.question_id,
                    "question": r.question,
                    "answer": r.answer,
                    "confidence": r.confidence,
                    "created_at": r.created_at
                }
                for r in responses
            ]


# Neo4j Alternative Implementation
class Neo4jService:
    """Neo4j graph database service for relationship modeling."""
    
    def __init__(self, uri: str = "bolt://localhost:7687", auth: tuple = ("neo4j", "password")):
        """Initialize Neo4j service.
        
        Args:
            uri: Neo4j connection URI
            auth: Authentication tuple (username, password)
        """
        try:
            from neo4j import GraphDatabase
            self.driver = GraphDatabase.driver(uri, auth=auth)
            logger.info("Connected to Neo4j")
        except ImportError:
            logger.warning("Neo4j driver not installed, using fallback")
            self.driver = None
    
    def create_startup_graph(self, startup_id: str, data: Dict[str, Any]):
        """Create startup knowledge graph.
        
        Creates nodes for:
        - Startup
        - Founders
        - Metrics
        - Competitors
        - Investors
        
        Args:
            startup_id: Startup identifier
            data: Startup data
        """
        if not self.driver:
            return
        
        with self.driver.session() as session:
            # Create startup node
            session.run(
                """
                MERGE (s:Startup {id: $id})
                SET s.name = $name, s.arr = $arr, s.updated = timestamp()
                """,
                id=startup_id,
                name=data.get("name", startup_id),
                arr=data.get("arr", 0)
            )
            
            # Create metric relationships
            if "metrics" in data:
                for metric_name, metric_value in data["metrics"].items():
                    session.run(
                        """
                        MATCH (s:Startup {id: $startup_id})
                        MERGE (m:Metric {name: $name})
                        MERGE (s)-[r:HAS_METRIC]->(m)
                        SET r.value = $value, r.updated = timestamp()
                        """,
                        startup_id=startup_id,
                        name=metric_name,
                        value=metric_value
                    )
    
    def find_similar_startups(
        self,
        startup_id: str,
        similarity_threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """Find similar startups using graph relationships.
        
        Args:
            startup_id: Startup identifier
            similarity_threshold: Similarity threshold
            
        Returns:
            List of similar startups
        """
        if not self.driver:
            return []
        
        with self.driver.session() as session:
            result = session.run(
                """
                MATCH (s1:Startup {id: $startup_id})-[:HAS_METRIC]->(m:Metric)
                <-[:HAS_METRIC]-(s2:Startup)
                WHERE s1 <> s2
                WITH s2, COUNT(m) as common_metrics
                WHERE common_metrics > 3
                RETURN s2.id as id, s2.name as name, common_metrics
                ORDER BY common_metrics DESC
                LIMIT 10
                """,
                startup_id=startup_id
            )
            
            return [
                {"id": record["id"], "name": record["name"], "similarity": record["common_metrics"]}
                for record in result
            ]
