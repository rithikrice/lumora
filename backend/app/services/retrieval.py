"""Hybrid retrieval service combining vector and BM25 search."""

from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from collections import defaultdict
import math

from ..models.dto import DocumentChunk, Evidence, DocumentType
from ..core.config import get_settings
from ..core.logging import get_logger
from .embeddings import get_embedding_service
from .index import get_index, SearchResult

logger = get_logger(__name__)


class BM25Retriever:
    """BM25 keyword-based retrieval."""
    
    def __init__(self, k1: float = 1.2, b: float = 0.75):
        """Initialize BM25 retriever.
        
        Args:
            k1: Term frequency saturation parameter
            b: Length normalization parameter
        """
        self.k1 = k1
        self.b = b
        self.doc_freqs = defaultdict(int)
        self.doc_lens = {}
        self.avg_doc_len = 0
        self.total_docs = 0
        self.inverted_index = defaultdict(set)
        self.documents = {}
    
    def index_documents(self, documents: List[DocumentChunk]):
        """Index documents for BM25 search.
        
        Args:
            documents: List of document chunks
        """
        # Handle both Chunk and DocumentChunk types
        if documents:
            if hasattr(documents[0], 'chunk_id'):
                # It's a Chunk object
                self.documents = {doc.chunk_id: doc for doc in documents}
            else:
                # It's a DocumentChunk object
                self.documents = {doc.id: doc for doc in documents}
        else:
            self.documents = {}
        self.total_docs = len(documents)
        
        # Calculate document frequencies and lengths
        total_len = 0
        for doc in documents:
            # Handle both Chunk and DocumentChunk
            text = doc.text if hasattr(doc, 'text') else doc.content if hasattr(doc, 'content') else ""
            tokens = self._tokenize(text)
            doc_len = len(tokens)
            # Get document ID
            doc_id = doc.chunk_id if hasattr(doc, 'chunk_id') else doc.id if hasattr(doc, 'id') else str(id(doc))
            self.doc_lens[doc_id] = doc_len
            total_len += doc_len
            
            # Update document frequencies
            unique_tokens = set(tokens)
            for token in unique_tokens:
                self.doc_freqs[token] += 1
                self.inverted_index[token].add(doc_id)
        
        self.avg_doc_len = total_len / self.total_docs if self.total_docs > 0 else 0
    
    def search(self, query: str, k: int = 10) -> List[Tuple[str, float]]:
        """Search documents using BM25.
        
        Args:
            query: Search query
            k: Number of results
            
        Returns:
            List of (doc_id, score) tuples
        """
        query_tokens = self._tokenize(query)
        scores = defaultdict(float)
        
        for token in query_tokens:
            if token in self.inverted_index:
                idf = self._calculate_idf(token)
                
                for doc_id in self.inverted_index[token]:
                    doc = self.documents[doc_id]
                    tf = self._calculate_tf(token, doc.text)
                    doc_len = self.doc_lens[doc_id]
                    
                    # BM25 score calculation
                    norm = 1 - self.b + self.b * (doc_len / self.avg_doc_len)
                    score = idf * (tf * (self.k1 + 1)) / (tf + self.k1 * norm)
                    scores[doc_id] += score
        
        # Sort by score
        sorted_scores = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        return sorted_scores[:k]
    
    def _tokenize(self, text: str) -> List[str]:
        """Advanced tokenization with stopword removal.
        
        Args:
            text: Text to tokenize
            
        Returns:
            List of tokens
        """
        import re
        
        # Common stopwords
        stopwords = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
            'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
            'could', 'should', 'may', 'might', 'must', 'can', 'shall', 'it', 'this',
            'that', 'these', 'those', 'i', 'you', 'he', 'she', 'we', 'they', 'them'
        }
        
        # Convert to lowercase and split on non-alphanumeric
        tokens = re.findall(r'\b\w+\b', text.lower())
        
        # Remove stopwords and very short tokens
        tokens = [t for t in tokens if t not in stopwords and len(t) > 2]
        
        return tokens
    
    def _calculate_idf(self, token: str) -> float:
        """Calculate IDF for a token.
        
        Args:
            token: Token
            
        Returns:
            IDF score
        """
        doc_freq = self.doc_freqs[token]
        if doc_freq == 0:
            return 0
        return math.log((self.total_docs - doc_freq + 0.5) / (doc_freq + 0.5))
    
    def _calculate_tf(self, token: str, text: str) -> int:
        """Calculate term frequency.
        
        Args:
            token: Token
            text: Document text
            
        Returns:
            Term frequency
        """
        tokens = self._tokenize(text)
        return tokens.count(token)


class HybridRetriever:
    """Hybrid retrieval combining vector and BM25 search."""
    
    def __init__(self, startup_id: str):
        """Initialize hybrid retriever.
        
        Args:
            startup_id: Startup identifier
        """
        self.startup_id = startup_id
        self.settings = get_settings()
        self.embedding_service = get_embedding_service()
        self.vector_index = get_index(startup_id)
        self.bm25_retriever = BM25Retriever()
        self.documents = {}
        
        # Load existing chunks from store
        from ..services.chunk_store import get_chunks
        existing_chunks = get_chunks(startup_id)
        if existing_chunks:
            self.documents = {chunk.chunk_id: chunk for chunk in existing_chunks}
            self.bm25_retriever.index_documents(existing_chunks)
            logger.info(f"Loaded {len(existing_chunks)} existing chunks for {startup_id}")
    
    async def index_documents(self, documents: List[DocumentChunk]):
        """Index documents for retrieval.
        
        Args:
            documents: List of document chunks
        """
        # Handle both Chunk and DocumentChunk types
        if documents:
            if hasattr(documents[0], 'chunk_id'):
                # It's a Chunk object
                self.documents = {doc.chunk_id: doc for doc in documents}
            else:
                # It's a DocumentChunk object
                self.documents = {doc.id: doc for doc in documents}
        else:
            self.documents = {}
        
        # Index for BM25
        self.bm25_retriever.index_documents(documents)
        
        # Index for vector search
        texts = []
        ids = []
        for doc in documents:
            if hasattr(doc, 'text'):
                texts.append(doc.text)
            elif hasattr(doc, 'content'):
                texts.append(doc.content)
            
            if hasattr(doc, 'chunk_id'):
                ids.append(doc.chunk_id)
            elif hasattr(doc, 'id'):
                ids.append(doc.id)
        metadata = []
        for doc in documents:
            meta = {}
            if hasattr(doc, 'text'):
                meta['text'] = doc.text
            elif hasattr(doc, 'content'):
                meta['text'] = doc.content
            
            if hasattr(doc, 'type'):
                meta['type'] = doc.type.value if hasattr(doc.type, 'value') else str(doc.type)
            
            if hasattr(doc, 'source'):
                meta['source'] = doc.source
            
            if hasattr(doc, 'metadata'):
                meta['metadata'] = doc.metadata
            
            metadata.append(meta)
        
        # Generate embeddings
        embeddings = await self.embedding_service.embed_batch(texts)
        
        # Add to vector index
        await self.vector_index.add_vectors(embeddings, ids, metadata)
        
        logger.info(f"Indexed {len(documents)} documents for startup {self.startup_id}")
    
    async def retrieve(
        self,
        query: str,
        k: int = 10,
        filter: Optional[Dict[str, Any]] = None
    ) -> List[Evidence]:
        """Retrieve relevant documents using hybrid search.
        
        Args:
            query: Search query
            k: Number of results
            filter: Optional filter criteria
            
        Returns:
            List of evidence items
        """
        evidence_list = []
        
        # Ensure we have documents indexed
        if not self.documents:
            logger.warning(f"No documents indexed for startup {self.startup_id}")
            return evidence_list
        
        try:
            # Get vector search results
            query_embedding = await self.embedding_service.embed_text(query)
            vector_results = await self.vector_index.search(
                query_embedding,
                k=self.settings.VECTOR_K,
                filter=filter
            )
        except Exception as e:
            logger.warning(f"Vector search failed: {str(e)}")
            vector_results = []
        
        try:
            # Get BM25 results
            bm25_results = self.bm25_retriever.search(query, k=self.settings.BM25_K)
        except Exception as e:
            logger.warning(f"BM25 search failed: {str(e)}")
            bm25_results = []
        
        # If both searches failed, return all documents with low scores
        if not vector_results and not bm25_results:
            logger.warning("Both search methods failed, returning all documents")
            for doc_id, doc in list(self.documents.items())[:k]:
                evidence = self._create_evidence(doc, 0.1)
                evidence_list.append(evidence)
            return evidence_list
        
        # Merge and re-rank results
        merged_results = self._merge_results(vector_results, bm25_results)
        
        # Convert to Evidence objects
        for doc_id, score in merged_results[:k]:
            if doc_id in self.documents:
                doc = self.documents[doc_id]
                evidence = self._create_evidence(doc, score)
                evidence_list.append(evidence)
        
        # If we don't have enough results, add more documents
        if len(evidence_list) < k:
            added_ids = {e.id for e in evidence_list}
            for doc_id, doc in self.documents.items():
                if doc_id not in added_ids:
                    evidence = self._create_evidence(doc, 0.1)
                    evidence_list.append(evidence)
                    if len(evidence_list) >= k:
                        break
        
        return evidence_list
    
    def _merge_results(
        self,
        vector_results: List[SearchResult],
        bm25_results: List[Tuple[str, float]]
    ) -> List[Tuple[str, float]]:
        """Merge and re-rank results from different retrievers.
        
        Args:
            vector_results: Vector search results
            bm25_results: BM25 search results
            
        Returns:
            Merged and re-ranked results
        """
        # Normalize scores
        vector_scores = {r.id: r.score for r in vector_results}
        bm25_scores = dict(bm25_results)
        
        # Normalize to 0-1 range
        if vector_scores:
            max_vector = max(vector_scores.values())
            vector_scores = {k: v/max_vector for k, v in vector_scores.items()}
        
        if bm25_scores:
            max_bm25 = max(bm25_scores.values())
            if max_bm25 > 0:
                bm25_scores = {k: v/max_bm25 for k, v in bm25_scores.items()}
            else:
                bm25_scores = {k: 0.5 for k in bm25_scores.keys()}
        
        # Combine scores (weighted average)
        vector_weight = 0.7
        bm25_weight = 0.3
        
        combined_scores = {}
        all_ids = set(vector_scores.keys()) | set(bm25_scores.keys())
        
        for doc_id in all_ids:
            v_score = vector_scores.get(doc_id, 0)
            b_score = bm25_scores.get(doc_id, 0)
            combined_scores[doc_id] = vector_weight * v_score + bm25_weight * b_score
        
        # Sort by combined score
        sorted_results = sorted(
            combined_scores.items(),
            key=lambda x: x[1],
            reverse=True
        )
        
        return sorted_results
    
    def _create_evidence(self, doc: DocumentChunk, score: float) -> Evidence:
        """Create evidence from document chunk.
        
        Args:
            doc: Document chunk
            score: Relevance score
            
        Returns:
            Evidence object
        """
        # Determine location format
        location = ""
        if doc.type == DocumentType.SLIDE:
            page = doc.metadata.get('page', 1)
            location = f"p{page}"
        elif doc.type == DocumentType.TRANSCRIPT:
            timestamp = doc.metadata.get('timestamp', '00:00')
            location = f"t={timestamp}"
        else:
            location = doc.source
        
        # Create snippet (first 200 chars)
        snippet = doc.text[:200] + "..." if len(doc.text) > 200 else doc.text
        
        return Evidence(
            id=doc.chunk_id if hasattr(doc, 'chunk_id') else doc.id if hasattr(doc, 'id') else str(id(doc)),
            type=doc.type,
            location=location,
            snippet=snippet,
            confidence=min(1.0, score)  # Cap at 1.0 to prevent validation errors
        )
