"""Simple chunk storage for questionnaire data."""

import pickle
from pathlib import Path
from typing import List, Dict, Any
from ..models.dto import Chunk
from ..core.logging import get_logger

logger = get_logger(__name__)

# Simple in-memory storage
_chunk_storage: Dict[str, List[Chunk]] = {}

def store_chunks(startup_id: str, chunks: List[Chunk]) -> None:
    """Store chunks for a startup."""
    global _chunk_storage
    _chunk_storage[startup_id] = chunks
    
    # Also persist to disk
    storage_dir = Path("storage/chunks")
    storage_dir.mkdir(parents=True, exist_ok=True)
    
    file_path = storage_dir / f"{startup_id}.pkl"
    try:
        with open(file_path, 'wb') as f:
            pickle.dump(chunks, f)
        logger.info(f"Stored {len(chunks)} chunks for {startup_id}")
    except Exception as e:
        logger.error(f"Failed to persist chunks: {e}")

def get_chunks(startup_id: str) -> List[Chunk]:
    """Get chunks for a startup."""
    global _chunk_storage
    
    # Try memory first
    if startup_id in _chunk_storage:
        return _chunk_storage[startup_id]
    
    # Try loading from disk
    storage_dir = Path("storage/chunks")
    file_path = storage_dir / f"{startup_id}.pkl"
    
    if file_path.exists():
        try:
            with open(file_path, 'rb') as f:
                chunks = pickle.load(f)
                _chunk_storage[startup_id] = chunks
                return chunks
        except Exception as e:
            logger.error(f"Failed to load chunks: {e}")
    
    return []

def clear_chunks(startup_id: str) -> None:
    """Clear chunks for a startup."""
    global _chunk_storage
    if startup_id in _chunk_storage:
        del _chunk_storage[startup_id]
    
    storage_dir = Path("storage/chunks")
    file_path = storage_dir / f"{startup_id}.pkl"
    if file_path.exists():
        file_path.unlink()