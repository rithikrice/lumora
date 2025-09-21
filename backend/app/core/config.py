"""Configuration management for AnalystAI backend."""

from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings with environment variable support."""
    
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=True
    )
    
    # Google Cloud Settings
    GOOGLE_PROJECT_ID: str = "your-project"
    GOOGLE_LOCATION: str = "us-central1"
    GCP_BUCKET: str = "analystai-raw"
    
    # Feature Flags
    USE_VERTEX: bool = False
    USE_MATCHING_ENGINE: bool = False
    USE_BIGQUERY: bool = False
    
    # Model Configuration
    GEMINI_MODEL: str = "gemini-1.5-flash"  # Primary model for all standard tasks
    VERTEX_MODEL: str = "gemini-1.5-flash"  # Use Flash for Vertex AI too (Pro not available)
    EMBED_MODEL: str = "text-embedding-004"
    
    # Security
    API_KEY: str = "dev-secret"
    
    # Gemini Configuration
    GEMINI_API_KEY: Optional[str] = None  # For direct Gemini API access
    
    # Google API Integrations (for hackathon demo)
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None  # Service account file path
    GOOGLE_SHEETS_CREDENTIALS: Optional[str] = None  # Service account JSON
    GCS_BUCKET: Optional[str] = None  # Override default bucket
    
    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8080
    LOG_LEVEL: str = "INFO"
    
    # Application Settings
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB
    CHUNK_SIZE: int = 512  # tokens per chunk
    CHUNK_OVERLAP: int = 50  # overlap between chunks
    
    # Retrieval Settings
    VECTOR_K: int = 8  # top-k for vector search
    BM25_K: int = 8  # top-k for BM25 search
    
    # Scoring Thresholds
    INVEST_THRESHOLD: float = 0.75
    FOLLOW_THRESHOLD: float = 0.55
    
    # Gemini Temperature Settings
    NOTES_TEMPERATURE: float = 0.2
    REDTEAM_TEMPERATURE: float = 0.4
    QA_TEMPERATURE: float = 0.2
    
    # Database
    DATABASE_URL: Optional[str] = None  # If None, uses SQLite
    SQLITE_PATH: str = "data/analystai.db"
    
    # Neo4j (optional)
    NEO4J_URI: Optional[str] = None
    NEO4J_USERNAME: Optional[str] = None
    NEO4J_PASSWORD: Optional[str] = None
    
    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return any([self.USE_VERTEX, self.USE_BIGQUERY, self.USE_MATCHING_ENGINE])
    
    @property
    def gcs_bucket_url(self) -> str:
        """Get the full GCS bucket URL."""
        return f"gs://{self.GCP_BUCKET}"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
