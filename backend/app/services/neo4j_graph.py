"""Neo4j Knowledge Graph for Startup Relationships."""

from typing import Dict, List, Optional, Any
from neo4j import GraphDatabase, AsyncGraphDatabase
import asyncio
import json
from ..core.config import get_settings
from ..core.logging import get_logger

logger = get_logger(__name__)


class StartupKnowledgeGraph:
    """Neo4j-based knowledge graph for startup ecosystem analysis."""
    
    def __init__(self):
        """Initialize Neo4j connection."""
        self.settings = get_settings()
        self.driver = None
        
        # Only initialize if Neo4j is configured
        if self.settings.NEO4J_URI:
            try:
                # Use the configured username (instance ID for Aura Free)
                self.driver = AsyncGraphDatabase.driver(
                    self.settings.NEO4J_URI,
                    auth=(self.settings.NEO4J_USERNAME, self.settings.NEO4J_PASSWORD)
                )
                logger.info("Neo4j Knowledge Graph initialized")
            except Exception as e:
                logger.warning(f"Neo4j not available: {e}")
                self.driver = None
    
    async def create_startup_node(
        self,
        startup_id: str,
        data: Dict[str, Any]
    ) -> bool:
        """Create professional startup node with comprehensive data and relationships."""
        if not self.driver:
            return False
            
        # Extract all available metrics for comprehensive node
        arr = data.get('arr', 0)
        growth_rate = data.get('growth_rate', 0)
        burn_rate = data.get('burn_rate', 0)
        team_size = data.get('team_size', 0)
        
        # Professional node creation with all attributes
        query = """
        MERGE (s:Startup {id: $startup_id})
        SET s.name = $name,
            s.display_name = $display_name,
            s.industry = $industry,
            s.sub_industry = $sub_industry,
            s.business_model = $business_model,
            s.arr = $arr,
            s.growth_rate = $growth_rate,
            s.burn_rate = $burn_rate,
            s.runway_months = $runway_months,
            s.gross_margin = $gross_margin,
            s.founded = $founded,
            s.team_size = $team_size,
            s.customer_count = $customer_count,
            s.ltv_cac_ratio = $ltv_cac_ratio,
            s.funding_stage = $funding_stage,
            s.total_raised = $total_raised,
            s.valuation = $valuation,
            s.headquarters = $headquarters,
            s.markets = $markets,
            s.technologies = $technologies,
            s.updated_at = timestamp(),
            s.data_completeness = $data_completeness,
            s.analysis_confidence = $analysis_confidence
        
        // Calculate derived metrics
        WITH s
        SET s.efficiency_score = CASE 
            WHEN s.burn_rate > 0 THEN s.arr / (s.burn_rate * 12) 
            ELSE 1.0 
        END,
        s.growth_efficiency = CASE
            WHEN s.burn_rate > 0 THEN s.growth_rate / s.burn_rate
            ELSE s.growth_rate
        END
        
        RETURN s
        """
        
        async with self.driver.session() as session:
            try:
                # Professional parameter mapping with comprehensive data
                await session.run(
                    query,
                    startup_id=startup_id,
                    name=data.get('company_name', startup_id),
                    display_name=data.get('company_name', 'Unknown'),
                    industry=data.get('industry', 'Technology'),
                    sub_industry=data.get('sub_industry', 'SaaS'),
                    business_model=data.get('business_model', 'B2B'),
                    arr=float(data.get('arr') or 0),
                    growth_rate=float(data.get('growth_rate') or 0),
                    burn_rate=float(data.get('burn_rate') or 0),
                    runway_months=int(data.get('runway_months') or 18),
                    gross_margin=float(data.get('gross_margin') or 75),
                    founded=int(data.get('founded') or 2020),
                    team_size=int(data.get('team_size') or 0),
                    customer_count=int(data.get('customer_count') or 0),
                    ltv_cac_ratio=float(data.get('ltv_cac_ratio') or 3),
                    funding_stage=data.get('funding_stage', 'Seed'),
                    total_raised=float(data.get('total_raised') or 0),
                    valuation=float(data.get('valuation') or 0),
                    headquarters=data.get('headquarters', 'US'),
                    markets=data.get('markets', ['Global']),
                    technologies=data.get('technologies', ['AI', 'ML']),
                    data_completeness=float(data.get('data_completeness', 0.7)),
                    analysis_confidence=float(data.get('analysis_confidence', 0.8))
                )
                
                # Create advanced relationships after node creation
                await self._create_advanced_relationships(session, startup_id, data)
                
                logger.info(f"Created professional startup node with advanced relationships: {startup_id}")
                return True
            except Exception as e:
                logger.error(f"Failed to create startup node: {e}")
                return False
    
    async def _create_advanced_relationships(self, session, startup_id: str, data: Dict[str, Any]):
        """Create sophisticated graph relationships using multiple algorithms."""
        
        # 1. Similarity relationships with multi-factor scoring
        similarity_query = """
        MATCH (s:Startup {id: $startup_id})
        MATCH (other:Startup)
        WHERE other.id <> s.id
        
        // Calculate multi-dimensional similarity
        WITH s, other,
             // Financial similarity (logarithmic scale for ARR comparison)
             CASE 
                 WHEN s.arr > 0 AND other.arr > 0 THEN
                     1.0 - (abs(log10(s.arr + 1) - log10(other.arr + 1)) / 3.0)
                 ELSE 0.3
             END * 0.35 as financial_sim,
             
             // Growth trajectory similarity
             CASE
                 WHEN s.growth_rate > 0 AND other.growth_rate > 0 THEN
                     1.0 - (abs(s.growth_rate - other.growth_rate) / (s.growth_rate + other.growth_rate))
                 ELSE 0.2
             END * 0.25 as growth_sim,
             
             // Industry and business model alignment
             CASE
                 WHEN s.industry = other.industry AND s.sub_industry = other.sub_industry THEN 1.0
                 WHEN s.industry = other.industry THEN 0.7
                 ELSE 0.2
             END * 0.2 as industry_sim,
             
             // Stage and maturity similarity
             CASE 
                 WHEN s.funding_stage = other.funding_stage THEN 1.0
                 WHEN (s.funding_stage = 'Series A' AND other.funding_stage = 'Seed') OR
                      (s.funding_stage = 'Seed' AND other.funding_stage = 'Series A') THEN 0.6
                 ELSE 0.2
             END * 0.1 as stage_sim,
             
             // Efficiency metrics similarity
             CASE
                 WHEN s.efficiency_score > 0 AND other.efficiency_score > 0 THEN
                     1.0 - abs(s.efficiency_score - other.efficiency_score) / 2.0
                 ELSE 0.3
             END * 0.1 as efficiency_sim
        
        WITH s, other, 
             financial_sim + growth_sim + industry_sim + stage_sim + efficiency_sim as total_similarity,
             financial_sim, growth_sim, industry_sim, stage_sim, efficiency_sim
        WHERE total_similarity > 0.4
        
        MERGE (s)-[sim:SIMILAR_TO]->(other)
        SET sim.score = total_similarity,
            sim.financial_component = financial_sim,
            sim.growth_component = growth_sim,
            sim.industry_component = industry_sim,
            sim.stage_component = stage_sim,
            sim.efficiency_component = efficiency_sim,
            sim.updated_at = timestamp()
        """
        
        try:
            await session.run(similarity_query, startup_id=startup_id)
        except Exception as e:
            logger.error(f"Failed to create similarity relationships: {e}")
        
        # 2. Competitive relationships with intensity scoring
        competition_query = """
        MATCH (s:Startup {id: $startup_id})
        MATCH (competitor:Startup)
        WHERE competitor.id <> s.id
          AND competitor.industry = s.industry
          AND (
              // Direct competition: similar ARR range
              (competitor.arr > s.arr * 0.5 AND competitor.arr < s.arr * 2.0) OR
              // Market overlap
              size([m IN s.markets WHERE m IN competitor.markets]) > 0 OR
              // Technology overlap
              size([t IN s.technologies WHERE t IN competitor.technologies]) > 0
          )
        
        WITH s, competitor,
             size([m IN s.markets WHERE m IN competitor.markets]) as market_overlap,
             size([t IN s.technologies WHERE t IN competitor.technologies]) as tech_overlap,
             CASE
                 WHEN s.arr > 0 AND competitor.arr > 0 THEN
                     abs(s.arr - competitor.arr) / (s.arr + competitor.arr)
                 ELSE 0.5
             END as arr_distance
        
        MERGE (s)-[comp:COMPETES_WITH]->(competitor)
        SET comp.intensity = CASE
                WHEN market_overlap > 1 AND arr_distance < 0.3 THEN 'high'
                WHEN market_overlap > 0 OR arr_distance < 0.5 THEN 'medium'
                ELSE 'low'
            END,
            comp.market_overlap_count = market_overlap,
            comp.tech_overlap_count = tech_overlap,
            comp.arr_ratio = CASE WHEN competitor.arr > 0 THEN s.arr / competitor.arr ELSE null END,
            comp.relative_position = CASE
                WHEN s.arr > competitor.arr * 1.5 THEN 'leader'
                WHEN s.arr < competitor.arr * 0.67 THEN 'follower'
                ELSE 'peer'
            END,
            comp.updated_at = timestamp()
        """
        
        try:
            await session.run(competition_query, startup_id=startup_id)
        except Exception as e:
            logger.error(f"Failed to create competitive relationships: {e}")
        
        # 3. Market and ecosystem relationships
        ecosystem_query = """
        MATCH (s:Startup {id: $startup_id})
        WITH s
        UNWIND s.markets as market_name
        MERGE (m:Market {name: market_name})
        MERGE (s)-[op:OPERATES_IN]->(m)
        SET op.primary = (market_name = s.markets[0])
        WITH s
        UNWIND s.technologies as tech_name
        MERGE (t:Technology {name: tech_name})
        MERGE (s)-[uses:USES]->(t)
        SET uses.core = (tech_name IN ['AI', 'ML', 'Blockchain'])
        WITH s
        MERGE (stage:FundingStage {name: s.funding_stage})
        MERGE (s)-[:AT_STAGE]->(stage)
        WITH s
        MERGE (loc:Location {name: s.headquarters})
        MERGE (s)-[:HEADQUARTERED_IN]->(loc)
        """
        
        try:
            await session.run(ecosystem_query, startup_id=startup_id)
        except Exception as e:
            logger.error(f"Failed to create ecosystem relationships: {e}")
    
    async def create_investor_relationship(
        self,
        startup_id: str,
        investor_name: str,
        investment_data: Dict[str, Any]
    ) -> bool:
        """Create investor relationship."""
        if not self.driver:
            return False
            
        query = """
        MATCH (s:Startup {id: $startup_id})
        MERGE (i:Investor {name: $investor_name})
        MERGE (i)-[r:INVESTED_IN]->(s)
        SET r.amount = $amount,
            r.date = $date,
            r.round = $round
        RETURN r
        """
        
        async with self.driver.session() as session:
            try:
                await session.run(
                    query,
                    startup_id=startup_id,
                    investor_name=investor_name,
                    amount=investment_data.get('amount', 0),
                    date=investment_data.get('date', ''),
                    round=investment_data.get('round', 'Seed')
                )
                return True
            except Exception as e:
                logger.error(f"Failed to create investor relationship: {e}")
                return False
    
    async def create_competitor_relationship(
        self,
        startup_id: str,
        competitor_id: str,
        similarity_score: float
    ) -> bool:
        """Create competitor relationship based on similarity."""
        if not self.driver:
            return False
            
        query = """
        MATCH (s1:Startup {id: $startup_id})
        MATCH (s2:Startup {id: $competitor_id})
        MERGE (s1)-[r:COMPETES_WITH]-(s2)
        SET r.similarity = $similarity
        RETURN r
        """
        
        async with self.driver.session() as session:
            try:
                await session.run(
                    query,
                    startup_id=startup_id,
                    competitor_id=competitor_id,
                    similarity=similarity_score
                )
                return True
            except Exception as e:
                logger.error(f"Failed to create competitor relationship: {e}")
                return False
    
    async def find_similar_startups(
        self,
        startup_id: str,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Find similar startups using graph traversal."""
        if not self.driver:
            return []
            
        query = """
        MATCH (s:Startup {id: $startup_id})
        MATCH (s)-[:COMPETES_WITH]-(competitor:Startup)
        RETURN competitor.id as id,
               competitor.name as name,
               competitor.arr as arr,
               competitor.growth_rate as growth_rate
        ORDER BY competitor.arr DESC
        LIMIT $limit
        """
        
        async with self.driver.session() as session:
            try:
                result = await session.run(
                    query,
                    startup_id=startup_id,
                    limit=limit
                )
                return [dict(record) async for record in result]
            except Exception as e:
                logger.error(f"Failed to find similar startups: {e}")
                return []
    
    async def find_investor_network(
        self,
        startup_id: str,
        depth: int = 2
    ) -> List[Dict[str, Any]]:
        """Find investor network up to specified depth."""
        if not self.driver:
            return []
            
        query = """
        MATCH (s:Startup {id: $startup_id})
        MATCH path = (s)<-[:INVESTED_IN*1..2]-(investor:Investor)
        WITH DISTINCT investor
        OPTIONAL MATCH (investor)-[:INVESTED_IN]->(portfolio:Startup)
        WHERE portfolio.id <> $startup_id
        RETURN investor.name as investor,
               COLLECT(DISTINCT portfolio.name) as portfolio
        LIMIT 20
        """
        
        async with self.driver.session() as session:
            try:
                result = await session.run(
                    query,
                    startup_id=startup_id,
                    depth=depth
                )
                return [dict(record) async for record in result]
            except Exception as e:
                logger.error(f"Failed to find investor network: {e}")
                return []
    
    async def calculate_market_position(
        self,
        startup_id: str
    ) -> Dict[str, Any]:
        """Calculate market position based on graph relationships."""
        if not self.driver:
            return {"position": "unknown", "competitors": 0, "investors": 0}
            
        query = """
        MATCH (s:Startup {id: $startup_id})
        OPTIONAL MATCH (s)-[:COMPETES_WITH]-(competitor)
        OPTIONAL MATCH (s)<-[:INVESTED_IN]-(investor)
        WITH s, COUNT(DISTINCT competitor) as competitor_count,
             COUNT(DISTINCT investor) as investor_count
        RETURN s.arr as arr,
               s.growth_rate as growth_rate,
               competitor_count,
               investor_count
        """
        
        async with self.driver.session() as session:
            try:
                result = await session.run(query, startup_id=startup_id)
                record = await result.single()
                
                if record:
                    data = dict(record)
                    # Calculate position based on metrics
                    position = "challenger"
                    if data['competitor_count'] > 5:
                        position = "competitive"
                    if data['investor_count'] > 3:
                        position = "well-funded"
                    if data.get('growth_rate', 0) > 100:
                        position = "high-growth"
                    
                    return {
                        "position": position,
                        "competitors": data['competitor_count'],
                        "investors": data['investor_count'],
                        "metrics": {
                            "arr": data.get('arr', 0),
                            "growth_rate": data.get('growth_rate', 0)
                        }
                    }
                
                return {"position": "unknown", "competitors": 0, "investors": 0}
                
            except Exception as e:
                logger.error(f"Failed to calculate market position: {e}")
                return {"position": "error", "competitors": 0, "investors": 0}
    
    async def close(self):
        """Close Neo4j connection."""
        if self.driver:
            await self.driver.close()


# Global instance
_graph_instance: Optional[StartupKnowledgeGraph] = None

def get_knowledge_graph() -> StartupKnowledgeGraph:
    """Get or create knowledge graph instance."""
    global _graph_instance
    if _graph_instance is None:
        _graph_instance = StartupKnowledgeGraph()
    return _graph_instance
