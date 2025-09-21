"""Evidence mapping and citation service."""

from typing import List, Dict, Any, Tuple
import re

from ..models.dto import Evidence, DocumentChunk
from ..core.logging import get_logger

logger = get_logger(__name__)


def map_citations_to_evidence(
    text: str,
    evidence_map: Dict[str, Evidence]
) -> List[Tuple[str, str]]:
    """Map citation IDs to evidence.
    
    Args:
        text: Text with [chunk:id] citations
        evidence_map: Map of chunk IDs to evidence
        
    Returns:
        List of (text_segment, evidence_id) tuples
    """
    pattern = r'([^\[]+)\[chunk:([^\]]+)\]'
    matches = re.findall(pattern, text)
    
    mapped = []
    for segment, chunk_id in matches:
        if chunk_id in evidence_map:
            mapped.append((segment.strip(), chunk_id))
    
    return mapped


def extract_snippets(
    chunks: List[DocumentChunk],
    max_length: int = 200
) -> Dict[str, str]:
    """Extract snippets from chunks.
    
    Args:
        chunks: Document chunks
        max_length: Maximum snippet length
        
    Returns:
        Map of chunk ID to snippet
    """
    snippets = {}
    
    for chunk in chunks:
        text = chunk.text
        if len(text) > max_length:
            snippet = text[:max_length] + "..."
        else:
            snippet = text
        snippets[chunk.chunk_id] = snippet
    
    return snippets
