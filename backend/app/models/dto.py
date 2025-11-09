"""Data Transfer Objects for AnalystAI API."""

from typing import Dict, List, Optional, Any, Literal
from pydantic import BaseModel, Field, validator
from datetime import datetime
from enum import Enum


class RecommendationType(str, Enum):
    """Investment recommendation types."""
    INVEST = "invest"
    FOLLOW = "follow"
    PASS = "pass"


class DocumentType(str, Enum):
    """Document content types."""
    SLIDE = "slide"
    TRANSCRIPT = "transcript"
    URL = "url"
    TEXT = "text"


class ExportFormat(str, Enum):
    """Export format types."""
    GDOC = "gdoc"
    PDF = "pdf"
    JSON = "json"
    HTML = "html"


class Chunk(BaseModel):
    """Document chunk for retrieval."""
    chunk_id: str
    content: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    embedding: List[float] = Field(default_factory=list)


class UploadRequest(BaseModel):
    """Request model for document upload."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    filename: str = Field(..., min_length=1, max_length=255)
    content_b64: str = Field(..., description="Base64 encoded file content")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)
    
    @validator('startup_id')
    def validate_startup_id(cls, v):
        """Ensure startup_id is alphanumeric with hyphens."""
        if not all(c.isalnum() or c in '-_' for c in v):
            raise ValueError("startup_id must be alphanumeric with hyphens/underscores only")
        return v


class UploadResponse(BaseModel):
    """Response model for document upload."""
    success: bool
    document_id: str
    startup_id: str
    filename: str
    storage_path: Optional[str] = None
    chunks_created: int = 0
    message: str = "Upload successful"


class PersonaWeights(BaseModel):
    """Persona scoring weights."""
    growth: float = Field(0.4, ge=0, le=1)
    unit_econ: float = Field(0.4, ge=0, le=1)
    founder: float = Field(0.2, ge=0, le=1)
    
    @validator('founder', always=True)
    def validate_sum(cls, v, values):
        """Ensure weights sum to 1.0."""
        total = values.get('growth', 0) + values.get('unit_econ', 0) + v
        if abs(total - 1.0) > 0.001:
            raise ValueError(f"Weights must sum to 1.0, got {total}")
        return v


class AnalyzeRequest(BaseModel):
    """Request model for startup analysis."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    persona: PersonaWeights = Field(default_factory=PersonaWeights)
    include_peers: bool = Field(False, description="Include peer comparison")
    include_stress: bool = Field(False, description="Include stress test scenarios")


class Risk(BaseModel):
    """Risk assessment model."""
    label: str
    severity: int = Field(..., ge=1, le=5)
    evidence_id: str
    mitigation: Optional[str] = None


class Evidence(BaseModel):
    """Evidence citation model."""
    id: str
    type: DocumentType
    location: str = Field(..., description="Page number (p12) or timestamp (t=03:21)")
    snippet: str = Field(..., max_length=500)
    confidence: float = Field(1.0, ge=0, le=1)


class KPIMetrics(BaseModel):
    """Key Performance Indicators."""
    arr: Optional[float] = None
    growth_rate: Optional[float] = None
    gross_margin: Optional[float] = None
    cac_ltv_ratio: Optional[float] = None
    burn_rate: Optional[float] = None
    runway_months: Optional[int] = None
    logo_retention: Optional[float] = None
    nrr: Optional[float] = None


class AnalyzeResponse(BaseModel):
    """Response model for startup analysis."""
    startup_id: str
    company_name: Optional[str] = None  # Company name from questionnaire
    executive_summary: List[str]
    kpis: KPIMetrics
    risks: List[Risk]
    recommendation: RecommendationType
    score: float = Field(..., ge=0, le=1)
    investment_score: float = Field(..., ge=0, le=100)  # Score as percentage
    evidence: List[Evidence]
    persona_scores: Dict[str, float] = Field(default_factory=dict)
    peer_comparison: Optional[Dict[str, Any]] = None
    stress_test: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class CounterfactualRequest(BaseModel):
    """Request model for counterfactual analysis."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    current_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    target_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    delta: Optional[Dict[str, float]] = Field(None, description="KPI changes to simulate")
    scenarios: Optional[List[Dict[str, Any]]] = Field(None, description="Multiple scenarios to test")
    target_recommendation: Optional[RecommendationType] = None
    persona_weights: Optional[Dict[str, float]] = None


class CounterfactualResponse(BaseModel):
    """Response model for counterfactual analysis."""
    startup_id: str
    current_score: Optional[float] = None  # Alias for original_score
    original_score: float
    new_score: float
    original_recommendation: RecommendationType
    new_recommendation: RecommendationType
    breakpoints: Dict[str, float] = Field(..., description="Minimum changes needed")
    delta_applied: Optional[Dict[str, float]] = None
    impact_analysis: Dict[str, str]
    scenarios: Optional[List[Dict[str, Any]]] = []  # For test compatibility


class AskRequest(BaseModel):
    """Request model for Q&A."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    question: str = Field(..., min_length=1, max_length=1000)
    max_chunks: int = Field(10, ge=1, le=20)


class AskResponse(BaseModel):
    """Response model for Q&A."""
    startup_id: str
    question: str
    answer: List[str] = Field(..., description="Answer in bullet points")
    evidence: List[Evidence]
    confidence: float = Field(..., ge=0, le=1)


class ExportRequest(BaseModel):
    """Request model for report export."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    format: ExportFormat = ExportFormat.GDOC
    include_evidence: bool = True
    include_appendix: bool = True


class ExportResponse(BaseModel):
    """Response model for report export."""
    startup_id: str
    format: ExportFormat
    document_url: Optional[str] = None
    document_id: Optional[str] = None
    success: bool
    message: str


class StressTestRequest(BaseModel):
    """Request model for stress testing."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    scenario: Literal["revenue_shock", "funding_delay", "custom"] = "revenue_shock"
    custom_params: Optional[Dict[str, float]] = None


class StressTestResponse(BaseModel):
    """Response model for stress testing."""
    startup_id: str
    scenario: str
    original_metrics: KPIMetrics
    stressed_metrics: KPIMetrics
    runway_change: int = Field(..., description="Change in runway (months)")
    dilution_impact: float = Field(..., description="Additional dilution required")
    risk_level: Literal["low", "medium", "high", "critical"]


class DocumentChunk(BaseModel):
    """Document chunk for processing."""
    id: str
    startup_id: str
    type: DocumentType
    source: str
    text: str
    embedding: Optional[List[float]] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class HealthResponse(BaseModel):
    """Health check response."""
    status: Literal["healthy", "degraded", "unhealthy"] = "healthy"
    version: str = "1.0.0"
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    services: Dict[str, bool] = Field(default_factory=dict)
