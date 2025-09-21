"""Health check endpoints."""

from fastapi import APIRouter, Depends
from typing import Dict, Any

from ..models.dto import HealthResponse
from ..core.config import get_settings
from ..core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


@router.get("/", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Basic health check endpoint.
    
    Returns:
        Health status
    """
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        services={
            "api": True,
            "vertex": settings.USE_VERTEX,
            "bigquery": settings.USE_BIGQUERY,
            "matching_engine": settings.USE_MATCHING_ENGINE
        }
    )


@router.get("/ready", response_model=Dict[str, Any])
async def readiness_check() -> Dict[str, Any]:
    """Readiness check for deployment.
    
    Returns:
        Readiness status
    """
    checks = {
        "database": True,  # Placeholder
        "storage": True,   # Placeholder
        "ml_models": True  # Placeholder
    }
    
    all_ready = all(checks.values())
    
    return {
        "ready": all_ready,
        "checks": checks
    }


@router.get("/live", response_model=Dict[str, bool])
async def liveness_check() -> Dict[str, bool]:
    """Liveness check for deployment.
    
    Returns:
        Liveness status
    """
    return {"alive": True}
