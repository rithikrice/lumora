"""Custom exceptions and error handlers for AnalystAI."""

from typing import Any, Dict, Optional
from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import ValidationError
import logging

logger = logging.getLogger(__name__)


class AnalystAIException(Exception):
    """Base exception for AnalystAI."""
    
    def __init__(
        self,
        message: str,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.details = details or {}


class AuthenticationError(AnalystAIException):
    """Authentication failed."""
    
    def __init__(self, message: str = "Authentication failed"):
        super().__init__(
            message=message,
            status_code=status.HTTP_401_UNAUTHORIZED
        )


class AuthorizationError(AnalystAIException):
    """Authorization failed."""
    
    def __init__(self, message: str = "Insufficient permissions"):
        super().__init__(
            message=message,
            status_code=status.HTTP_403_FORBIDDEN
        )


class ResourceNotFoundError(AnalystAIException):
    """Resource not found."""
    
    def __init__(self, resource: str, identifier: str):
        super().__init__(
            message=f"{resource} with id '{identifier}' not found",
            status_code=status.HTTP_404_NOT_FOUND,
            details={"resource": resource, "identifier": identifier}
        )


class ValidationError(AnalystAIException):
    """Validation error."""
    
    def __init__(self, message: str, field: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"field": field} if field else {}
        )


class ProcessingError(AnalystAIException):
    """Document processing error."""
    
    def __init__(self, message: str, document_type: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"document_type": document_type} if document_type else {}
        )


class ExternalServiceError(AnalystAIException):
    """External service error."""
    
    def __init__(self, service: str, message: str):
        super().__init__(
            message=f"External service error ({service}): {message}",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            details={"service": service}
        )


class QuotaExceededError(AnalystAIException):
    """Quota exceeded error."""
    
    def __init__(self, resource: str, limit: int):
        super().__init__(
            message=f"Quota exceeded for {resource}. Limit: {limit}",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            details={"resource": resource, "limit": limit}
        )


class InsufficientEvidenceError(AnalystAIException):
    """Insufficient evidence for analysis."""
    
    def __init__(self, required_docs: int, found_docs: int):
        super().__init__(
            message=f"Insufficient evidence for analysis. Required: {required_docs}, Found: {found_docs}",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"required_docs": required_docs, "found_docs": found_docs}
        )


async def analyst_exception_handler(request: Request, exc: AnalystAIException) -> JSONResponse:
    """Handle AnalystAI exceptions.
    
    Args:
        request: FastAPI request
        exc: AnalystAI exception
        
    Returns:
        JSON response with error details
    """
    logger.error(
        f"AnalystAI error: {exc.message}",
        extra={
            "path": request.url.path,
            "method": request.method,
            "status_code": exc.status_code,
            "details": exc.details
        }
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.message,
                "type": exc.__class__.__name__,
                "details": exc.details
            }
        }
    )


async def validation_exception_handler(request: Request, exc: ValidationError) -> JSONResponse:
    """Handle Pydantic validation errors.
    
    Args:
        request: FastAPI request
        exc: Validation error
        
    Returns:
        JSON response with validation errors
    """
    logger.warning(
        f"Validation error: {str(exc)}",
        extra={
            "path": request.url.path,
            "method": request.method
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "message": "Validation error",
                "type": "ValidationError",
                "details": exc.errors() if hasattr(exc, 'errors') else str(exc)
            }
        }
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle general exceptions.
    
    Args:
        request: FastAPI request
        exc: Exception
        
    Returns:
        JSON response with error message
    """
    logger.error(
        f"Unhandled error: {str(exc)}",
        exc_info=True,
        extra={
            "path": request.url.path,
            "method": request.method
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "message": "An internal server error occurred",
                "type": "InternalServerError"
            }
        }
    )
