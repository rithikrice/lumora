"""Security utilities for AnalystAI."""

from typing import Optional
from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
import hashlib
import hmac
import secrets
from functools import lru_cache

from .config import get_settings
from .errors import AuthenticationError
from .logging import get_logger

logger = get_logger(__name__)

# API Key header
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: Optional[str] = Security(api_key_header)) -> str:
    """Verify API key from request header.
    
    Args:
        api_key: API key from header
        
    Returns:
        Validated API key
        
    Raises:
        AuthenticationError: If API key is invalid
    """
    settings = get_settings()
    
    if not api_key:
        logger.warning("Missing API key in request")
        raise AuthenticationError("Missing API key")
    
    # Constant-time comparison to prevent timing attacks
    if not secrets.compare_digest(api_key, settings.API_KEY):
        logger.warning(f"Invalid API key attempted: {api_key[:8]}...")
        raise AuthenticationError("Invalid API key")
    
    return api_key


def hash_content(content: bytes) -> str:
    """Generate SHA-256 hash of content.
    
    Args:
        content: Content to hash
        
    Returns:
        Hex digest of hash
    """
    return hashlib.sha256(content).hexdigest()


def generate_document_id(startup_id: str, filename: str, content_hash: str) -> str:
    """Generate unique document ID.
    
    Args:
        startup_id: Startup identifier
        filename: Original filename
        content_hash: Hash of content
        
    Returns:
        Unique document ID
    """
    # Combine components
    components = f"{startup_id}:{filename}:{content_hash[:8]}"
    
    # Generate short hash
    doc_hash = hashlib.sha256(components.encode()).hexdigest()[:12]
    
    return f"{startup_id}-{doc_hash}"


def generate_chunk_id(document_id: str, chunk_index: int) -> str:
    """Generate unique chunk ID.
    
    Args:
        document_id: Parent document ID
        chunk_index: Index of chunk
        
    Returns:
        Unique chunk ID
    """
    return f"{document_id}-chunk-{chunk_index:04d}"


def sanitize_filename(filename: str) -> str:
    """Sanitize filename for storage.
    
    Args:
        filename: Original filename
        
    Returns:
        Sanitized filename
    """
    # Remove path components
    import os
    filename = os.path.basename(filename)
    
    # Replace dangerous characters
    dangerous_chars = ['/', '\\', '..', '~', '|', '>', '<', ':', '*', '?', '"', "'"]
    for char in dangerous_chars:
        filename = filename.replace(char, '_')
    
    # Limit length
    name, ext = os.path.splitext(filename)
    if len(name) > 100:
        name = name[:100]
    
    return f"{name}{ext}"


def validate_startup_id(startup_id: str) -> bool:
    """Validate startup ID format.
    
    Args:
        startup_id: Startup identifier
        
    Returns:
        True if valid
    """
    if not startup_id or len(startup_id) > 100:
        return False
    
    # Allow alphanumeric, hyphens, and underscores
    return all(c.isalnum() or c in '-_' for c in startup_id)


@lru_cache(maxsize=128)
def is_allowed_file_type(filename: str) -> bool:
    """Check if file type is allowed.
    
    Args:
        filename: Filename to check
        
    Returns:
        True if allowed
    """
    allowed_extensions = {
        '.pdf', '.txt', '.md', '.docx', '.pptx',
        '.png', '.jpg', '.jpeg', '.gif', '.webp',
        '.mp3', '.mp4', '.wav', '.webm'
    }
    
    import os
    _, ext = os.path.splitext(filename.lower())
    return ext in allowed_extensions


def validate_file_size(content_size: int) -> bool:
    """Validate file size.
    
    Args:
        content_size: Size in bytes
        
    Returns:
        True if within limits
    """
    settings = get_settings()
    return 0 < content_size <= settings.MAX_FILE_SIZE


class RateLimiter:
    """Simple in-memory rate limiter."""
    
    def __init__(self, max_requests: int = 100, window_seconds: int = 60):
        """Initialize rate limiter.
        
        Args:
            max_requests: Maximum requests per window
            window_seconds: Time window in seconds
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = {}
    
    def is_allowed(self, key: str) -> bool:
        """Check if request is allowed.
        
        Args:
            key: Client identifier (e.g., API key)
            
        Returns:
            True if allowed
        """
        import time
        current_time = time.time()
        
        # Clean old entries
        self.requests = {
            k: v for k, v in self.requests.items()
            if current_time - v[-1] < self.window_seconds
        }
        
        # Check rate limit
        if key not in self.requests:
            self.requests[key] = [current_time]
            return True
        
        # Filter requests within window
        recent_requests = [
            t for t in self.requests[key]
            if current_time - t < self.window_seconds
        ]
        
        if len(recent_requests) < self.max_requests:
            recent_requests.append(current_time)
            self.requests[key] = recent_requests
            return True
        
        return False


# Global rate limiter instance
rate_limiter = RateLimiter()
