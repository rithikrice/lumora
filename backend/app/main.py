"""AnalystAI Backend - Main FastAPI Application."""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import uvicorn

from .core.config import get_settings
from .core.logging import setup_logging, get_logger
from .core.errors import (
    AnalystAIException,
    analyst_exception_handler,
    validation_exception_handler,
    general_exception_handler
)
from .models.dto import HealthResponse

# Import API routers
from .api import health, ingest, analyze, export, questionnaire, advanced, video, ui

# Initialize logging
setup_logging()
logger = get_logger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    logger.info("Starting AnalystAI Backend")
    logger.info(f"Environment: {'Production' if settings.is_production else 'Development'}")
    logger.info(f"Vertex AI: {'Enabled' if settings.USE_VERTEX else 'Disabled'}")
    logger.info(f"BigQuery: {'Enabled' if settings.USE_BIGQUERY else 'Disabled'}")
    logger.info(f"Matching Engine: {'Enabled' if settings.USE_MATCHING_ENGINE else 'Disabled'}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down AnalystAI Backend")


# Create FastAPI app
app = FastAPI(
    title="AnalystAI Backend",
    description="AI-powered investment analysis platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register exception handlers
app.add_exception_handler(AnalystAIException, analyst_exception_handler)
app.add_exception_handler(ValueError, validation_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# Include API routers
app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(ingest.router, prefix="/v1", tags=["Ingestion"])
app.include_router(analyze.router, prefix="/v1", tags=["Analysis"])
app.include_router(export.router, prefix="/v1", tags=["Export"])
app.include_router(questionnaire.router, prefix="/v1", tags=["Questionnaire"])
app.include_router(advanced.router, prefix="/v1/advanced", tags=["Advanced Features"])
app.include_router(video.router, prefix="/v1", tags=["Video Analysis"])
app.include_router(ui.router, prefix="/v1/ui", tags=["UI Endpoints"])


@app.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint."""
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


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests."""
    logger.info(
        f"Request: {request.method} {request.url.path}",
        extra={
            "method": request.method,
            "path": request.url.path,
            "client": request.client.host if request.client else None
        }
    )
    
    response = await call_next(request)
    
    logger.info(
        f"Response: {response.status_code}",
        extra={
            "status_code": response.status_code,
            "path": request.url.path
        }
    )
    
    return response


def run():
    """Run the application."""
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=not settings.is_production,
        log_level=settings.LOG_LEVEL.lower()
    )


if __name__ == "__main__":
    run()
