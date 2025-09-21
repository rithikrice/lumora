"""Document ingestion API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from ..models.dto import (
    UploadRequest, UploadResponse, DocumentChunk
)
from ..core.security import verify_api_key, generate_document_id, is_allowed_file_type, validate_file_size
from ..core.logging import get_logger, log_api_call
from ..core.errors import ProcessingError, ValidationError
from ..services.gcs import GCSService, decode_base64_content
from ..services.parsers import parse_document
from ..services.index import get_index
from ..services.retrieval import HybridRetriever
from ..services.chunk_store import store_chunks, get_chunks

router = APIRouter()
logger = get_logger(__name__)


@router.get("/debug/store")
async def debug_chunk_store(
    api_key: str = Depends(verify_api_key)
):
    """Debug endpoint to check chunk store contents."""
    # This would need to be implemented differently
    # For now, return empty debug info
    return {
        "total_startups": 0,
        "message": "Debug store not implemented"
    }


@router.get("/startups/{startup_id}")
async def get_startup_data(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
):
    """Get stored data for a startup.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Startup data including chunks
    """
    try:
        chunks = get_chunks(startup_id)
        if not chunks:
            raise HTTPException(status_code=404, detail="Startup not found")
        
        return {
            "startup_id": startup_id,
            "chunk_count": len(chunks),
            "chunks": [
                {
                    "id": chunk.chunk_id,
                    "content": chunk.text,  # DocumentChunk uses 'text' not 'content'
                    "type": chunk.type.value if hasattr(chunk.type, 'value') else str(chunk.type),
                    "metadata": chunk.metadata
                }
                for chunk in chunks[:10]  # Return first 10 chunks for debugging
            ]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving startup data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/upload", response_model=UploadResponse)
async def upload_document(
    request: UploadRequest,
    api_key: str = Depends(verify_api_key)
) -> UploadResponse:
    """Upload and process a document.
    
    Args:
        request: Upload request with file content
        api_key: API key for authentication
        
    Returns:
        Upload response with document ID
        
    Raises:
        HTTPException: If upload fails
    """
    log_api_call("/upload", "POST", startup_id=request.startup_id)
    
    try:
        # Validate file
        if not is_allowed_file_type(request.filename):
            raise ValidationError(f"File type not allowed: {request.filename}", "filename")
        
        # Decode content
        content = decode_base64_content(request.content_b64)
        
        # Validate size
        if not validate_file_size(len(content)):
            raise ValidationError("File size exceeds limit", "content_b64")
        
        # Generate document ID
        from ..core.security import hash_content
        content_hash = hash_content(content)
        document_id = generate_document_id(
            request.startup_id,
            request.filename,
            content_hash
        )
        
        # Upload to storage
        gcs_service = GCSService()
        storage_path, public_url = await gcs_service.upload_file(
            content=content,
            filename=request.filename,
            startup_id=request.startup_id
        )
        
        # Parse document into chunks
        chunks = await parse_document(
            content=content,
            filename=request.filename,
            startup_id=request.startup_id,
            document_id=document_id
        )
        
        # Store chunks in memory for retrieval
        if chunks:
            store_chunks(request.startup_id, chunks)
            
            # Also index for retrieval
            retriever = HybridRetriever(request.startup_id)
            await retriever.index_documents(chunks)
        
        logger.info(
            f"Document uploaded successfully: {document_id}",
            extra={
                "startup_id": request.startup_id,
                "document_id": document_id,
                "chunks_created": len(chunks)
            }
        )
        
        return UploadResponse(
            success=True,
            document_id=document_id,
            startup_id=request.startup_id,
            filename=request.filename,
            storage_path=storage_path,
            chunks_created=len(chunks),
            message=f"Document processed successfully with {len(chunks)} chunks"
        )
        
    except ProcessingError as e:
        logger.error(f"Document processing failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Failed to process document: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Upload failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Upload failed"
        )


@router.post("/webhook/gcs")
async def gcs_webhook(
    event: dict,
    api_key: str = Depends(verify_api_key)
):
    """Handle GCS upload webhook.
    
    Args:
        event: GCS event data
        api_key: API key for authentication
        
    Returns:
        Processing status
    """
    log_api_call("/webhook/gcs", "POST")
    
    try:
        # Extract file info from event
        bucket = event.get("bucket")
        name = event.get("name")
        
        if not bucket or not name:
            raise ValidationError("Missing bucket or name in event")
        
        # Extract startup_id from path (assumes format: startup_id/filename)
        parts = name.split("/")
        if len(parts) < 2:
            raise ValidationError(f"Invalid file path format: {name}")
        
        startup_id = parts[0]
        filename = parts[-1]
        
        # Download and process file
        gcs_service = GCSService()
        content = await gcs_service.download_file(name)
        
        # Generate document ID
        from ..core.security import hash_content
        content_hash = hash_content(content)
        document_id = generate_document_id(startup_id, filename, content_hash)
        
        # Parse and index
        chunks = await parse_document(
            content=content,
            filename=filename,
            startup_id=startup_id,
            document_id=document_id
        )
        
        if chunks:
            retriever = HybridRetriever(startup_id)
            await retriever.index_documents(chunks)
        
        logger.info(
            f"Webhook processed document: {document_id}",
            extra={
                "startup_id": startup_id,
                "document_id": document_id,
                "chunks_created": len(chunks)
            }
        )
        
        return {
            "success": True,
            "document_id": document_id,
            "chunks_created": len(chunks)
        }
        
    except Exception as e:
        logger.error(f"Webhook processing failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Webhook processing failed"
        )
