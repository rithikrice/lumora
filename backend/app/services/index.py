"""Vector index service for similarity search."""

from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from dataclasses import dataclass
import pickle
import json
from pathlib import Path

from ..core.config import get_settings
from ..core.logging import get_logger
from ..core.errors import ExternalServiceError
from .embeddings import get_embedding_service, cosine_similarity

logger = get_logger(__name__)


@dataclass
class SearchResult:
    """Vector search result."""
    id: str
    score: float
    metadata: Dict[str, Any]
    text: Optional[str] = None


class VectorIndex:
    """Base vector index interface."""
    
    def __init__(self, dimension: int = 768):
        """Initialize vector index.
        
        Args:
            dimension: Vector dimension
        """
        self.dimension = dimension
        self.settings = get_settings()
    
    async def add_vectors(
        self,
        vectors: List[List[float]],
        ids: List[str],
        metadata: List[Dict[str, Any]] = None
    ) -> bool:
        """Add vectors to index.
        
        Args:
            vectors: List of vectors
            ids: List of IDs
            metadata: List of metadata dicts
            
        Returns:
            Success status
        """
        raise NotImplementedError
    
    async def search(
        self,
        query_vector: List[float],
        k: int = 10,
        filter: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """Search for similar vectors.
        
        Args:
            query_vector: Query vector
            k: Number of results
            filter: Optional filter criteria
            
        Returns:
            List of search results
        """
        raise NotImplementedError
    
    async def delete(self, ids: List[str]) -> bool:
        """Delete vectors by IDs.
        
        Args:
            ids: List of IDs to delete
            
        Returns:
            Success status
        """
        raise NotImplementedError


class FAISSIndex(VectorIndex):
    """FAISS-based vector index for local search."""
    
    def __init__(self, dimension: int = 384):  # MiniLM uses 384 dimensions
        """Initialize FAISS index.
        
        Args:
            dimension: Vector dimension (384 for all-MiniLM-L6-v2)
        """
        super().__init__(dimension)
        self.index = None
        self.id_map = {}  # Map from internal ID to external ID
        self.metadata_map = {}  # Map from external ID to metadata
        self.vector_map = {}  # Map from external ID to vector
        self.init_index()
    
    def init_index(self):
        """Initialize FAISS index."""
        try:
            import faiss
            
            # Use IndexFlatL2 for exact search (can upgrade to IVF for larger datasets)
            self.index = faiss.IndexFlatL2(self.dimension)
            logger.info(f"Initialized FAISS index with dimension {self.dimension}")
            
        except ImportError:
            raise ExternalServiceError("faiss", "Please install faiss-cpu package")
    
    async def add_vectors(
        self,
        vectors: List[List[float]],
        ids: List[str],
        metadata: List[Dict[str, Any]] = None
    ) -> bool:
        """Add vectors to FAISS index.
        
        Args:
            vectors: List of vectors
            ids: List of IDs
            metadata: List of metadata dicts
            
        Returns:
            Success status
        """
        try:
            if not vectors:
                return True
                
            # Convert to numpy array
            vectors_np = np.array(vectors, dtype=np.float32)
            
            # Check dimension and reinitialize if needed
            actual_dim = vectors_np.shape[1]
            if self.index.d != actual_dim:
                logger.warning(f"FAISS dimension mismatch: expected {self.index.d}, got {actual_dim}. Reinitializing...")
                self.dimension = actual_dim
                self.init_index()  # Reinitialize with correct dimension
            
            # Get current index size
            start_idx = self.index.ntotal
            
            # Add to index
            self.index.add(vectors_np)
            
            # Update mappings
            for i, (vec_id, vec) in enumerate(zip(ids, vectors)):
                internal_id = start_idx + i
                self.id_map[internal_id] = vec_id
                self.vector_map[vec_id] = vec
                
                if metadata and i < len(metadata):
                    self.metadata_map[vec_id] = metadata[i]
                else:
                    self.metadata_map[vec_id] = {}
            
            logger.info(f"Added {len(vectors)} vectors to FAISS index")
            return True
            
        except Exception as e:
            logger.error(f"Failed to add vectors to FAISS: {str(e)}", exc_info=True)
            # Continue without FAISS for now
            return True
    
    async def search(
        self,
        query_vector: List[float],
        k: int = 10,
        filter: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """Search FAISS index.
        
        Args:
            query_vector: Query vector
            k: Number of results
            filter: Optional filter criteria
            
        Returns:
            List of search results
        """
        try:
            # Convert to numpy array
            query_np = np.array([query_vector], dtype=np.float32)
            
            # Search index
            distances, indices = self.index.search(query_np, min(k * 2, self.index.ntotal))
            
            results = []
            for dist, idx in zip(distances[0], indices[0]):
                if idx == -1:  # FAISS returns -1 for empty results
                    continue
                
                external_id = self.id_map.get(idx)
                if not external_id:
                    continue
                
                # Apply filter if provided
                metadata = self.metadata_map.get(external_id, {})
                if filter:
                    # Simple filter matching
                    match = all(
                        metadata.get(key) == value
                        for key, value in filter.items()
                    )
                    if not match:
                        continue
                
                # Convert L2 distance to similarity score (0-1)
                score = 1.0 / (1.0 + dist)
                
                results.append(SearchResult(
                    id=external_id,
                    score=score,
                    metadata=metadata,
                    text=metadata.get("text")
                ))
                
                if len(results) >= k:
                    break
            
            return results
            
        except Exception as e:
            logger.warning(f"FAISS search skipped: {str(e)}")
            # Return empty results, let BM25 handle it
            return []
    
    async def delete(self, ids: List[str]) -> bool:
        """Delete vectors from FAISS index.
        
        Note: FAISS doesn't support direct deletion, so we rebuild the index.
        
        Args:
            ids: List of IDs to delete
            
        Returns:
            Success status
        """
        try:
            # Get all vectors except the ones to delete
            remaining_ids = []
            remaining_vectors = []
            remaining_metadata = []
            
            for vec_id, vec in self.vector_map.items():
                if vec_id not in ids:
                    remaining_ids.append(vec_id)
                    remaining_vectors.append(vec)
                    remaining_metadata.append(self.metadata_map.get(vec_id, {}))
            
            # Reinitialize index
            self.init_index()
            self.id_map.clear()
            self.metadata_map.clear()
            self.vector_map.clear()
            
            # Re-add remaining vectors
            if remaining_vectors:
                await self.add_vectors(
                    remaining_vectors,
                    remaining_ids,
                    remaining_metadata
                )
            
            logger.info(f"Deleted {len(ids)} vectors from FAISS index")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete vectors from FAISS: {str(e)}")
            return False
    
    def save(self, path: str):
        """Save index to disk.
        
        Args:
            path: Save path
        """
        try:
            import faiss
            
            # Save FAISS index
            faiss.write_index(self.index, f"{path}.faiss")
            
            # Save mappings
            mappings = {
                "id_map": self.id_map,
                "metadata_map": self.metadata_map,
                "vector_map": self.vector_map
            }
            with open(f"{path}.pkl", "wb") as f:
                pickle.dump(mappings, f)
            
            logger.info(f"Saved FAISS index to {path}")
            
        except Exception as e:
            logger.error(f"Failed to save FAISS index: {str(e)}")
    
    def load(self, path: str):
        """Load index from disk.
        
        Args:
            path: Load path
        """
        try:
            import faiss
            
            # Load FAISS index
            self.index = faiss.read_index(f"{path}.faiss")
            
            # Load mappings
            with open(f"{path}.pkl", "rb") as f:
                mappings = pickle.load(f)
                self.id_map = mappings["id_map"]
                self.metadata_map = mappings["metadata_map"]
                self.vector_map = mappings["vector_map"]
            
            logger.info(f"Loaded FAISS index from {path}")
            
        except Exception as e:
            logger.error(f"Failed to load FAISS index: {str(e)}")


class MatchingEngineIndex(VectorIndex):
    """Google Vertex AI Matching Engine index."""
    
    def __init__(self, dimension: int = 768):
        """Initialize Matching Engine index.
        
        Args:
            dimension: Vector dimension
        """
        super().__init__(dimension)
        self.index_endpoint = None
        self.index_id = None
        
        if self.settings.USE_MATCHING_ENGINE:
            self._init_client()
    
    def _init_client(self):
        """Initialize Matching Engine client."""
        try:
            from google.cloud import aiplatform
            
            aiplatform.init(
                project=self.settings.GOOGLE_PROJECT_ID,
                location=self.settings.GOOGLE_LOCATION
            )
            
            # Note: Index creation and deployment should be done via CLI/Console
            # as it takes significant time (30-60 minutes)
            self.index_id = "analystai-index"  # Pre-created index
            self.index_endpoint = "analystai-endpoint"  # Pre-deployed endpoint
            
            logger.info("Initialized Matching Engine client")
            
        except Exception as e:
            logger.error(f"Failed to initialize Matching Engine: {str(e)}")
            raise ExternalServiceError("Matching Engine", str(e))
    
    async def add_vectors(
        self,
        vectors: List[List[float]],
        ids: List[str],
        metadata: List[Dict[str, Any]] = None
    ) -> bool:
        """Add vectors to Matching Engine.
        
        Args:
            vectors: List of vectors
            ids: List of IDs
            metadata: List of metadata dicts
            
        Returns:
            Success status
        """
        if not self.settings.USE_MATCHING_ENGINE:
            return False
        
        try:
            from google.cloud import aiplatform
            
            # Get index
            index = aiplatform.MatchingEngineIndex(
                index_name=self.index_id
            )
            
            # Prepare data points
            datapoints = []
            for i, (vec_id, vec) in enumerate(zip(ids, vectors)):
                datapoint = {
                    "datapoint_id": vec_id,
                    "feature_vector": vec
                }
                
                # Add metadata as restricts/numerics
                if metadata and i < len(metadata):
                    restricts = []
                    for key, value in metadata[i].items():
                        if isinstance(value, str):
                            restricts.append({
                                "namespace": key,
                                "allow_list": [value]
                            })
                    if restricts:
                        datapoint["restricts"] = restricts
                
                datapoints.append(datapoint)
            
            # Upsert datapoints
            index.upsert_datapoints(datapoints)
            
            logger.info(f"Added {len(vectors)} vectors to Matching Engine")
            return True
            
        except Exception as e:
            logger.error(f"Failed to add vectors to Matching Engine: {str(e)}")
            return False
    
    async def search(
        self,
        query_vector: List[float],
        k: int = 10,
        filter: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """Search Matching Engine.
        
        Args:
            query_vector: Query vector
            k: Number of results
            filter: Optional filter criteria
            
        Returns:
            List of search results
        """
        if not self.settings.USE_MATCHING_ENGINE:
            return []
        
        try:
            from google.cloud import aiplatform
            
            # Get index endpoint
            index_endpoint = aiplatform.MatchingEngineIndexEndpoint(
                index_endpoint_name=self.index_endpoint
            )
            
            # Prepare query
            queries = [{
                "feature_vector": query_vector,
                "neighbor_count": k
            }]
            
            # Add filters if provided
            if filter:
                restricts = []
                for key, value in filter.items():
                    if isinstance(value, str):
                        restricts.append({
                            "namespace": key,
                            "allow_list": [value]
                        })
                if restricts:
                    queries[0]["restricts"] = restricts
            
            # Search
            responses = index_endpoint.find_neighbors(queries)
            
            results = []
            for neighbor in responses[0].neighbors:
                results.append(SearchResult(
                    id=neighbor.datapoint_id,
                    score=1.0 - neighbor.distance,  # Convert distance to similarity
                    metadata={}  # Metadata needs to be stored separately
                ))
            
            return results
            
        except Exception as e:
            logger.error(f"Matching Engine search failed: {str(e)}")
            return []
    
    async def delete(self, ids: List[str]) -> bool:
        """Delete vectors from Matching Engine.
        
        Args:
            ids: List of IDs to delete
            
        Returns:
            Success status
        """
        if not self.settings.USE_MATCHING_ENGINE:
            return False
        
        try:
            from google.cloud import aiplatform
            
            # Get index
            index = aiplatform.MatchingEngineIndex(
                index_name=self.index_id
            )
            
            # Remove datapoints
            index.remove_datapoints(datapoint_ids=ids)
            
            logger.info(f"Deleted {len(ids)} vectors from Matching Engine")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete vectors from Matching Engine: {str(e)}")
            return False


class HybridVectorIndex(VectorIndex):
    """Hybrid vector index with fallback."""
    
    def __init__(self, dimension: int = 768):
        """Initialize hybrid index.
        
        Args:
            dimension: Vector dimension
        """
        super().__init__(dimension)
        self.faiss_index = FAISSIndex(dimension)
        self.matching_engine = None
        
        if self.settings.USE_MATCHING_ENGINE:
            self.matching_engine = MatchingEngineIndex(dimension)
    
    async def add_vectors(
        self,
        vectors: List[List[float]],
        ids: List[str],
        metadata: List[Dict[str, Any]] = None
    ) -> bool:
        """Add vectors to index.
        
        Args:
            vectors: List of vectors
            ids: List of IDs
            metadata: List of metadata dicts
            
        Returns:
            Success status
        """
        # Always add to FAISS for local backup
        success = await self.faiss_index.add_vectors(vectors, ids, metadata)
        
        # Also add to Matching Engine if enabled
        if self.matching_engine:
            try:
                await self.matching_engine.add_vectors(vectors, ids, metadata)
            except Exception as e:
                logger.warning(f"Matching Engine add failed, using FAISS only: {str(e)}")
        
        return success
    
    async def search(
        self,
        query_vector: List[float],
        k: int = 10,
        filter: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """Search index with fallback.
        
        Args:
            query_vector: Query vector
            k: Number of results
            filter: Optional filter criteria
            
        Returns:
            List of search results
        """
        # Try Matching Engine first if available
        if self.matching_engine:
            try:
                results = await self.matching_engine.search(query_vector, k, filter)
                if results:
                    return results
            except Exception as e:
                logger.warning(f"Matching Engine search failed, using FAISS: {str(e)}")
        
        # Fallback to FAISS
        return await self.faiss_index.search(query_vector, k, filter)
    
    async def delete(self, ids: List[str]) -> bool:
        """Delete vectors from index.
        
        Args:
            ids: List of IDs to delete
            
        Returns:
            Success status
        """
        success = await self.faiss_index.delete(ids)
        
        if self.matching_engine:
            try:
                await self.matching_engine.delete(ids)
            except Exception as e:
                logger.warning(f"Matching Engine delete failed: {str(e)}")
        
        return success


# Global index instances per startup
_index_cache: Dict[str, VectorIndex] = {}


def get_index(startup_id: str, dimension: int = 768) -> VectorIndex:
    """Get or create index for startup.
    
    Args:
        startup_id: Startup identifier
        dimension: Vector dimension
        
    Returns:
        Vector index instance
    """
    if startup_id not in _index_cache:
        _index_cache[startup_id] = HybridVectorIndex(dimension)
    
    return _index_cache[startup_id]
