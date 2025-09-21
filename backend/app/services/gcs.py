"""Google Cloud Storage service for file management."""

import io
import base64
from typing import Optional, Tuple
from pathlib import Path

from ..core.config import get_settings
from ..core.logging import get_logger
from ..core.errors import ExternalServiceError
from ..core.security import sanitize_filename, hash_content

logger = get_logger(__name__)


class GCSService:
    """Google Cloud Storage service."""
    
    def __init__(self):
        """Initialize GCS service."""
        self.settings = get_settings()
        self.bucket_name = self.settings.GCP_BUCKET
        self.client = None
        self.bucket = None
        
        # Always use local storage for hackathon
        # GCS is optional and only for production scale
        self.client = None
        self.bucket = None
        logger.info("Using local storage (perfect for hackathon demo)")
    
    def _init_client(self):
        """Initialize GCS client."""
        try:
            from google.cloud import storage
            
            self.client = storage.Client(
                project=self.settings.GOOGLE_PROJECT_ID
            )
            
            # Get or create bucket
            try:
                self.bucket = self.client.bucket(self.bucket_name)
                if not self.bucket.exists():
                    self.bucket.create(
                        location=self.settings.GOOGLE_LOCATION
                    )
                    logger.info(f"Created GCS bucket: {self.bucket_name}")
            except Exception as e:
                logger.warning(f"Could not verify/create bucket: {str(e)}")
                
        except ImportError:
            logger.warning("Google Cloud Storage not available in offline mode")
    
    async def upload_file(
        self,
        content: bytes,
        filename: str,
        startup_id: str,
        content_type: Optional[str] = None
    ) -> Tuple[str, str]:
        """Upload file to GCS.
        
        Args:
            content: File content
            filename: Original filename
            startup_id: Startup identifier
            content_type: MIME type
            
        Returns:
            Tuple of (storage path, public URL)
        """
        # Sanitize filename
        safe_filename = sanitize_filename(filename)
        
        # Generate storage path
        content_hash = hash_content(content)[:8]
        storage_path = f"{startup_id}/{content_hash}_{safe_filename}"
        
        if self.client and self.bucket:
            try:
                # Upload to GCS
                blob = self.bucket.blob(storage_path)
                
                blob.upload_from_string(
                    content,
                    content_type=content_type or 'application/octet-stream'
                )
                
                # Make publicly accessible (optional)
                # blob.make_public()
                
                public_url = blob.public_url
                logger.info(f"Uploaded file to GCS: {storage_path}")
                
                return storage_path, public_url
                
            except Exception as e:
                logger.error(f"GCS upload failed: {str(e)}")
                raise ExternalServiceError("GCS", f"Upload failed: {str(e)}")
        else:
            # Local storage fallback
            local_dir = Path("data/uploads") / startup_id
            local_dir.mkdir(parents=True, exist_ok=True)
            
            local_path = local_dir / safe_filename
            local_path.write_bytes(content)
            
            logger.info(f"Saved file locally: {local_path}")
            return str(local_path), f"file://{local_path}"
    
    async def download_file(self, storage_path: str) -> bytes:
        """Download file from GCS.
        
        Args:
            storage_path: Storage path
            
        Returns:
            File content
        """
        if self.client and self.bucket:
            try:
                blob = self.bucket.blob(storage_path)
                content = blob.download_as_bytes()
                
                logger.info(f"Downloaded file from GCS: {storage_path}")
                return content
                
            except Exception as e:
                logger.error(f"GCS download failed: {str(e)}")
                raise ExternalServiceError("GCS", f"Download failed: {str(e)}")
        else:
            # Local storage fallback
            local_path = Path(storage_path)
            if local_path.exists():
                return local_path.read_bytes()
            else:
                raise FileNotFoundError(f"File not found: {storage_path}")
    
    async def delete_file(self, storage_path: str) -> bool:
        """Delete file from GCS.
        
        Args:
            storage_path: Storage path
            
        Returns:
            Success status
        """
        if self.client and self.bucket:
            try:
                blob = self.bucket.blob(storage_path)
                blob.delete()
                
                logger.info(f"Deleted file from GCS: {storage_path}")
                return True
                
            except Exception as e:
                logger.error(f"GCS delete failed: {str(e)}")
                return False
        else:
            # Local storage fallback
            local_path = Path(storage_path)
            if local_path.exists():
                local_path.unlink()
                return True
            return False
    
    async def list_files(self, prefix: str) -> list:
        """List files with prefix.
        
        Args:
            prefix: Path prefix
            
        Returns:
            List of file paths
        """
        files = []
        
        if self.client and self.bucket:
            try:
                blobs = self.bucket.list_blobs(prefix=prefix)
                files = [blob.name for blob in blobs]
                
            except Exception as e:
                logger.error(f"GCS list failed: {str(e)}")
        else:
            # Local storage fallback
            local_dir = Path("data/uploads")
            if local_dir.exists():
                files = [
                    str(p.relative_to(local_dir))
                    for p in local_dir.glob(f"{prefix}*")
                ]
        
        return files


def decode_base64_content(content_b64: str) -> bytes:
    """Decode base64 content.
    
    Args:
        content_b64: Base64 encoded content
        
    Returns:
        Decoded bytes
    """
    try:
        # Handle data URLs
        if ',' in content_b64:
            content_b64 = content_b64.split(',')[1]
        
        # Decode
        return base64.b64decode(content_b64)
        
    except Exception as e:
        logger.error(f"Base64 decode failed: {str(e)}")
        raise ValueError(f"Invalid base64 content: {str(e)}")
