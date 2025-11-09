"""Firestore database service for persistent cloud storage."""

from typing import Dict, Any, Optional, List
from datetime import datetime
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from ..core.logging import get_logger
from ..models.dto import AnalyzeResponse

logger = get_logger(__name__)


class FirestoreService:
    """Firestore database service - persistent cloud storage."""
    
    def __init__(self):
        """Initialize Firestore client."""
        try:
            from ..core.config import get_settings
            settings = get_settings()
            
            # Try to use explicit credentials if provided
            import os
            if settings.GOOGLE_APPLICATION_CREDENTIALS:
                os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = settings.GOOGLE_APPLICATION_CREDENTIALS
                logger.info(f"Using GCP credentials from: {settings.GOOGLE_APPLICATION_CREDENTIALS}")
            elif os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
                logger.info(f"Using GCP credentials from environment: {os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')}")
            else:
                logger.warning("No explicit GCP credentials found, using Application Default Credentials")
            
            # Initialize Firestore client
            self.db = firestore.Client(project=settings.GOOGLE_PROJECT_ID)
            self.startups_collection = self.db.collection('startups')
            self.documents_collection = self.db.collection('documents')
            self.questionnaire_collection = self.db.collection('questionnaire_responses')
            logger.info(f"Firestore initialized successfully for project: {settings.GOOGLE_PROJECT_ID}")
        except Exception as e:
            logger.error(f"Failed to initialize Firestore: {e}", exc_info=True)
            raise
    
    def get_startup(self, startup_id: str) -> Optional[Dict[str, Any]]:
        """Get startup data by ID."""
        try:
            doc = self.startups_collection.document(startup_id).get()
            if doc.exists:
                data = doc.to_dict()
                # Convert Firestore timestamps to ISO strings
                if 'created_at' in data and data['created_at']:
                    data['created_at'] = data['created_at'].isoformat() if hasattr(data['created_at'], 'isoformat') else str(data['created_at'])
                if 'updated_at' in data and data['updated_at']:
                    data['updated_at'] = data['updated_at'].isoformat() if hasattr(data['updated_at'], 'isoformat') else str(data['updated_at'])
                
                # Return in expected format with profile
                return {
                    "startup_id": startup_id,
                    "name": data.get('name'),
                    "name_lower": data.get('name_lower'),
                    "profile": data.get('profile', {}),
                    "questionnaire_responses": data.get('questionnaire_data', data.get('questionnaire_responses', {})),
                    "documents": data.get('documents', []),
                    "analysis_score": data.get('score', 70),
                    "top_risks": data.get('risks', []),
                    "created_at": data.get('created_at'),
                    "updated_at": data.get('updated_at')
                }
            return None
        except Exception as e:
            logger.error(f"Failed to get startup {startup_id}: {e}")
            return None
    
    def find_startup_id(self, company_name: str) -> Optional[str]:
        """Return an existing startup_id for this company, if any."""
        if not company_name:
            return None
        name_lower = company_name.strip().lower()
        try:
            q = self.startups_collection.where(
                filter=FieldFilter("name_lower", "==", name_lower)
            ).limit(1)
            docs = list(q.stream())
            return docs[0].id if docs else None
        except Exception as e:
            logger.error(f"find_startup_id failed: {e}")
            return None


    def list_startups(self, limit: int = 10, offset: int = 0) -> List[Dict[str, Any]]:
        """List all startups with pagination."""
        try:
            # Firestore doesn't have offset, so we'll use limit only
            query = self.startups_collection.order_by('created_at', direction=firestore.Query.DESCENDING).limit(limit)
            
            docs = query.stream()
            results = []
            
            for doc in docs:
                data = doc.to_dict()
                results.append({
                    "startup_id": doc.id,
                    "questionnaire_responses": data.get('questionnaire_data', {}),
                    "analysis_score": data.get('score', 70),
                    "top_risks": data.get('risks', []),
                    "updated_at": data.get('updated_at').isoformat() if data.get('updated_at') else None
                })
            
            return results
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
        try:
            doc_ref = self.startups_collection.document(startup_id)
            
            # Get existing data
            existing = doc_ref.get()
            data = existing.to_dict() if existing.exists else {}
            
            # Update with analysis results
            data.update({
                'startup_id': startup_id,
                'latest_score': analysis.score,
                'latest_recommendation': analysis.recommendation.value,
                'latest_analysis': analysis.dict(),
                'score': analysis.score,
                'updated_at': datetime.utcnow(),
            })
            
            # Update KPIs if present
            if analysis.kpis:
                data.update({
                    'arr': analysis.kpis.arr,
                    'growth_rate': analysis.kpis.growth_rate,
                    'gross_margin': analysis.kpis.gross_margin,
                    'burn_rate': analysis.kpis.burn_rate,
                    'runway_months': analysis.kpis.runway_months,
                })
            
            # Set created_at if new
            if not existing.exists:
                data['created_at'] = datetime.utcnow()
            
            doc_ref.set(data, merge=True)
            logger.info(f"Saved startup {startup_id} to Firestore")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save startup {startup_id}: {e}")
            return False
    
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
        try:
            doc_ref = self.startups_collection.document(startup_id)
            
            # Get existing data
            existing = doc_ref.get()
            data = existing.to_dict() if existing.exists else {}
            
            # Update questionnaire data
            data.update({
                'startup_id': startup_id,
                'name': responses.get('company_name', data.get('name', startup_id)),
                'name_lower': str(responses.get('company_name', data.get('name', startup_id))).strip().lower(),
                'questionnaire_data': responses,
                'questionnaire_responses': responses,
                'updated_at': datetime.utcnow(),
            })
            
            # Extract and save key metrics
            if 'arr' in responses and responses['arr']:
                data['arr'] = float(responses['arr'])
            if 'growth_rate' in responses and responses['growth_rate']:
                data['growth_rate'] = float(responses['growth_rate'])
            if 'gross_margin' in responses and responses['gross_margin']:
                data['gross_margin'] = float(responses['gross_margin'])
            if 'burn_rate' in responses and responses['burn_rate']:
                data['burn_rate'] = float(responses['burn_rate'])
            if 'runway' in responses and responses['runway']:
                data['runway_months'] = int(responses['runway'])
            
            # Set score and created_at if new
            if not existing.exists:
                data['score'] = 70
                data['risks'] = []
                data['created_at'] = datetime.utcnow()
            
            doc_ref.set(data, merge=True)
            logger.info(f"Saved questionnaire for {startup_id} to Firestore")
            
            # Write-through to profile
            from .normalizer import normalize_from_questionnaire
            upserts = normalize_from_questionnaire(responses)
            upserts["__source"] = "questionnaire"
            self.save_structured_profile(startup_id, upserts)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to save questionnaire for {startup_id}: {e}")
            return False
    
    def save_single_questionnaire_response(
        self,
        startup_id: str,
        question_id: str,
        question: str,
        answer: str,
        confidence: float = 1.0
    ) -> bool:
        """Save single questionnaire response.
        
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
            # Create a unique document ID
            doc_id = f"{startup_id}_{question_id}"
            doc_ref = self.questionnaire_collection.document(doc_id)
            
            data = {
                'startup_id': startup_id,
                'question_id': question_id,
                'question': question,
                'answer': answer,
                'confidence': confidence,
                'created_at': datetime.utcnow(),
            }
            
            doc_ref.set(data, merge=True)
            logger.info(f"Saved questionnaire response {doc_id} to Firestore")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save questionnaire response: {e}")
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
        try:
            query = self.questionnaire_collection.where(
                filter=FieldFilter('startup_id', '==', startup_id)
            )
            
            docs = query.stream()
            results = []
            
            for doc in docs:
                data = doc.to_dict()
                results.append({
                    'question_id': data.get('question_id'),
                    'question': data.get('question'),
                    'answer': data.get('answer'),
                    'confidence': data.get('confidence'),
                    'created_at': data.get('created_at'),
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Failed to get questionnaire responses for {startup_id}: {e}")
            return []
    
    def save_structured_profile(self, startup_id: str, incoming: dict, source: str = "pitch_deck"):
        """Save structured profile data with merge support - SSoT write-through.
        
        This makes profile the single source of truth, while also preserving
        raw source data in questionnaire_responses or other buckets.
        
        Args:
            startup_id: Startup identifier
            incoming: Profile data to merge
            source: Source of the data ("pitch_deck", "checklist", "questionnaire")
            
        Returns:
            Merged profile dictionary
        """
        try:
            ref = self.startups_collection.document(startup_id)
            snap = ref.get()
            cur = snap.to_dict() if snap.exists else {}
            profile = cur.get("profile", {})
            
            # Merge with precedence: questionnaire > checklist > pitch_deck
            from .normalizer import merge_profile
            merged = merge_profile(profile, incoming, source)
            
            # Prepare payload - write SSoT
            payload = {
                "profile": merged,
                "name": merged.get("company_name", cur.get("name", startup_id)),
                "name_lower": str(merged.get("company_name", cur.get("name", startup_id))).strip().lower(),
                "updated_at": datetime.utcnow(),
            }
            
            # Keep raw sources for debug/backfill
            if source == "questionnaire":
                # Update questionnaire_responses
                existing_responses = cur.get("questionnaire_responses", {})
                existing_responses.update(incoming)
                payload["questionnaire_responses"] = existing_responses
                payload["questionnaire_data"] = existing_responses
            elif source in ["pitch_deck", "checklist"]:
                # Store raw extracted data for reference
                if source not in cur.get("questionnaire_responses", {}):
                    existing_responses = cur.get("questionnaire_responses", {})
                    existing_responses[source] = incoming
                    payload["questionnaire_responses"] = existing_responses
            
            if not snap.exists:
                payload["created_at"] = datetime.utcnow()
            
            ref.set(payload, merge=True)
            logger.info(f"Saved structured profile for {startup_id} from {source}")
            return merged
            
        except Exception as e:
            logger.error(f"save_structured_profile failed: {e}")
            raise
    
    def add_document_index(self, startup_id: str, doc: dict):
        """Add a document to the documents index.
        
        Args:
            startup_id: Startup identifier
            doc: Document metadata dictionary
        """
        try:
            ref = self.startups_collection.document(startup_id)
            # Get existing documents
            snap = ref.get()
            if snap.exists:
                existing = snap.to_dict()
                docs = existing.get("documents", [])
                # Prevent duplicates by document_id
                if not any(d.get("document_id") == doc.get("document_id") for d in docs):
                    docs.append(doc)
                    ref.set({"documents": docs}, merge=True)
            else:
                ref.set({"documents": [doc]}, merge=True)
            logger.info(f"Added document index for {startup_id}: {doc.get('document_id')}")
        except Exception as e:
            logger.error(f"add_document_index failed: {e}")
    
    def delete_startup(self, startup_id: str) -> bool:
        """Delete a startup and all associated data.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            Success status
        """
        try:
            # Delete startup document
            self.startups_collection.document(startup_id).delete()
            
            # Delete associated questionnaire responses
            query = self.questionnaire_collection.where(
                filter=FieldFilter('startup_id', '==', startup_id)
            )
            docs = query.stream()
            for doc in docs:
                doc.reference.delete()
            
            logger.info(f"✅ Deleted startup {startup_id} from Firestore")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete startup {startup_id}: {e}")
            return False
    
    # Context manager support
    def get_session(self):
        """Provide compatibility with SQLAlchemy-style session management."""
        class FirestoreSession:
            def __enter__(self):
                return self
            
            def __exit__(self, exc_type, exc_val, exc_tb):
                pass
            
            def commit(self):
                pass
            
            def rollback(self):
                pass
            
            def close(self):
                pass
        
        return FirestoreSession()

