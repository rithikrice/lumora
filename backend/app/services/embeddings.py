"""Embeddings service for text vectorization."""

from typing import List, Optional, Dict, Any
import numpy as np
from functools import lru_cache

from ..core.config import get_settings
from ..core.logging import get_logger
from ..core.errors import ExternalServiceError

logger = get_logger(__name__)


class EmbeddingService:
    """Base embedding service."""
    
    def __init__(self):
        """Initialize embedding service."""
        self.settings = get_settings()
        self.model_name = self.settings.EMBED_MODEL
        self.embedding_dim = 768  # Default dimension
    
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding for text.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        raise NotImplementedError
    
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for batch of texts.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        raise NotImplementedError


class VertexEmbeddingService(EmbeddingService):
    """Vertex AI embedding service."""
    
    def __init__(self):
        """Initialize Vertex AI embedding service."""
        super().__init__()
        self.embedding_dim = 768  # text-embedding-004 dimension
        
        if self.settings.USE_VERTEX:
            from google.cloud import aiplatform
            aiplatform.init(
                project=self.settings.GOOGLE_PROJECT_ID,
                location=self.settings.GOOGLE_LOCATION
            )
    
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding using Vertex AI.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        embeddings = await self.embed_batch([text])
        return embeddings[0] if embeddings else []
    
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for batch using Vertex AI.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        if not self.settings.USE_VERTEX:
            # Fallback to local embeddings
            return await LocalEmbeddingService().embed_batch(texts)
        
        try:
            from google.cloud import aiplatform
            from vertexai.language_models import TextEmbeddingModel
            
            # Initialize model
            model = TextEmbeddingModel.from_pretrained(self.model_name)
            
            # Generate embeddings
            embeddings = []
            
            # Process in batches (Vertex AI has batch size limits)
            batch_size = 5
            for i in range(0, len(texts), batch_size):
                batch_texts = texts[i:i + batch_size]
                
                # Get embeddings
                batch_embeddings = model.get_embeddings(batch_texts)
                
                # Extract vectors
                for embedding in batch_embeddings:
                    embeddings.append(embedding.values)
            
            return embeddings
            
        except Exception as e:
            logger.error(f"Vertex AI embedding error: {str(e)}")
            raise ExternalServiceError("Vertex AI", f"Embedding failed: {str(e)}")


class LocalEmbeddingService(EmbeddingService):
    """Local embedding service using sentence-transformers."""
    
    # SINGLETON PATTERN for performance - load model ONCE
    _shared_model = None
    _model_loading = False
    
    def __init__(self):
        """Initialize local embedding service."""
        super().__init__()
        self.model_name = "all-MiniLM-L6-v2"  # Lightweight model
        self.embedding_dim = 384
        # Use shared model instance
        self._load_model()
        self.model = LocalEmbeddingService._shared_model
    
    def _load_model(self):
        """Load the sentence transformer model (singleton for speed)."""
        if LocalEmbeddingService._shared_model is None and not LocalEmbeddingService._model_loading:
            try:
                LocalEmbeddingService._model_loading = True
                from sentence_transformers import SentenceTransformer
                logger.info(f"Loading embedding model ONCE: {self.model_name}")
                LocalEmbeddingService._shared_model = SentenceTransformer(self.model_name)
                logger.info(f"Model cached for all future requests")
            except ImportError:
                raise ExternalServiceError(
                    "sentence-transformers",
                    "Please install sentence-transformers package"
                )
            finally:
                LocalEmbeddingService._model_loading = False
    
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding using local model.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        embeddings = await self.embed_batch([text])
        return embeddings[0] if embeddings else []
    
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for batch using local model.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        self._load_model()
        
        if self.model is None:
            # Fallback to TF-IDF vectorizer if sentence-transformers not available
            return self._tfidf_embeddings(texts)
        
        try:
            # Generate embeddings
            embeddings = self.model.encode(texts, convert_to_tensor=False, show_progress_bar=False)
            
            # Convert to list format
            return embeddings.tolist()
            
        except Exception as e:
            logger.error(f"Local embedding error: {str(e)}")
            # Fallback to TF-IDF
            return self._tfidf_embeddings(texts)
    
    def _tfidf_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate TF-IDF embeddings as fallback.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        try:
            from sklearn.feature_extraction.text import TfidfVectorizer
            
            # Create or load vectorizer
            if not hasattr(self, 'tfidf_vectorizer'):
                self.tfidf_vectorizer = TfidfVectorizer(
                    max_features=self.embedding_dim,
                    stop_words='english',
                    ngram_range=(1, 2)
                )
                # Fit on the current texts (in production, would fit on larger corpus)
                self.tfidf_vectorizer.fit(texts)
            
            # Transform texts to vectors
            vectors = self.tfidf_vectorizer.transform(texts)
            
            # Convert sparse matrix to dense and pad/truncate to embedding_dim
            dense_vectors = vectors.toarray()
            
            # Ensure correct dimensionality
            if dense_vectors.shape[1] < self.embedding_dim:
                # Pad with zeros
                padding = np.zeros((len(texts), self.embedding_dim - dense_vectors.shape[1]))
                dense_vectors = np.hstack([dense_vectors, padding])
            elif dense_vectors.shape[1] > self.embedding_dim:
                # Truncate
                dense_vectors = dense_vectors[:, :self.embedding_dim]
            
            return dense_vectors.tolist()
            
        except Exception as e:
            logger.error(f"TF-IDF embedding failed: {str(e)}")
            # Last resort: return simple hash-based embeddings
            return self._hash_embeddings(texts)
    
    def _hash_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate simple hash-based embeddings as last resort.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        embeddings = []
        
        for text in texts:
            # Create a deterministic vector from text hash
            import hashlib
            
            # Generate multiple hash values for different dimensions
            vector = []
            for i in range(self.embedding_dim):
                # Create unique hash for each dimension
                hash_input = f"{text}_{i}".encode('utf-8')
                hash_value = hashlib.sha256(hash_input).hexdigest()
                
                # Convert hash to float in range [-1, 1]
                numeric_value = int(hash_value[:8], 16) / (2**32)
                normalized = (numeric_value - 0.5) * 2
                vector.append(normalized)
            
            embeddings.append(vector)
        
        return embeddings


class HybridEmbeddingService(EmbeddingService):
    """Hybrid embedding service with fallback."""
    
    def __init__(self):
        """Initialize hybrid embedding service."""
        super().__init__()
        self.vertex_service = VertexEmbeddingService()
        self.local_service = LocalEmbeddingService()
    
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding with fallback.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        try:
            if self.settings.USE_VERTEX:
                return await self.vertex_service.embed_text(text)
            else:
                return await self.local_service.embed_text(text)
        except Exception as e:
            logger.warning(f"Primary embedding failed, using fallback: {str(e)}")
            return await self.local_service.embed_text(text)
    
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings with fallback.
        
        Args:
            texts: List of texts to embed
            
        Returns:
            List of embedding vectors
        """
        try:
            if self.settings.USE_VERTEX:
                return await self.vertex_service.embed_batch(texts)
            else:
                return await self.local_service.embed_batch(texts)
        except Exception as e:
            logger.warning(f"Primary embedding failed, using fallback: {str(e)}")
            return await self.local_service.embed_batch(texts)


@lru_cache()
def get_embedding_service() -> EmbeddingService:
    """Get embedding service instance.
    
    HACKATHON OPTIMIZATION: Using local embeddings for speed.
    Vertex AI takes 8+ seconds per call - too slow for demos.
    
    Returns:
        Embedding service instance
    """
    # ALWAYS use local for speed - critical for hackathon success
    return LocalEmbeddingService()
    
    # Original (too slow for demos):
    # return HybridEmbeddingService()


async def embed_documents(
    documents: List[Dict[str, Any]],
    text_field: str = "text"
) -> List[Dict[str, Any]]:
    """Embed a list of documents.
    
    Args:
        documents: List of documents
        text_field: Field name containing text to embed
        
    Returns:
        Documents with embeddings added
    """
    service = get_embedding_service()
    
    # Extract texts
    texts = [doc.get(text_field, "") for doc in documents]
    
    # Generate embeddings
    embeddings = await service.embed_batch(texts)
    
    # Add embeddings to documents
    for doc, embedding in zip(documents, embeddings):
        doc["embedding"] = embedding
    
    return documents


def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Calculate cosine similarity between two vectors.
    
    Args:
        vec1: First vector
        vec2: Second vector
        
    Returns:
        Cosine similarity score
    """
    vec1 = np.array(vec1)
    vec2 = np.array(vec2)
    
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return float(dot_product / (norm1 * norm2))
