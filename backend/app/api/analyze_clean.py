"""Analysis API endpoints - Gemini 2.0 Flash with full context."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
import json
import google.generativeai as genai

from ..models.dto import (
    AnalyzeRequest, AnalyzeResponse,
    CounterfactualRequest, CounterfactualResponse,
    AskRequest, AskResponse,
    StressTestRequest, StressTestResponse,
    RecommendationType,
    Evidence, DocumentType
)
from ..core.security import verify_api_key
from ..core.logging import get_logger, log_api_call
from ..core.config import get_settings
from ..services.analysis_gemini import analyze_startup_with_gemini
from ..services.generator import GeminiGenerator
from ..services.scoring import CounterfactualAnalyzer
from ..services.database import get_database_service

settings = get_settings()
router = APIRouter()
logger = get_logger(__name__)


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_startup(
    request: AnalyzeRequest,
    api_key: str = Depends(verify_api_key)
) -> AnalyzeResponse:
    """Analyze a startup using Gemini 2.0 Flash with full context.
    
    NO RAG - just send all data to Gemini's 2M token context!
    
    Args:
        request: Analysis request
        api_key: API key for authentication
        
    Returns:
        Analysis response with insights
        
    Raises:
        HTTPException: If analysis fails
    """
    log_api_call("/analyze", "POST", startup_id=request.startup_id)
    
    try:
        # Use Gemini 2.0 Flash with full context (no RAG!)
        logger.info(f"Analyzing {request.startup_id} with Gemini 2.0 Flash (full context)")
        
        analysis = await analyze_startup_with_gemini(
            request.startup_id,
            persona_weights=request.persona.dict() if request.persona else None
        )
        
        return analysis
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Analysis validation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Analysis failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {str(e)}"
        )


@router.post("/counterfactual", response_model=CounterfactualResponse)
async def counterfactual_analysis(
    request: CounterfactualRequest,
    api_key: str = Depends(verify_api_key)
) -> CounterfactualResponse:
    """Perform counterfactual analysis using Gemini.
    
    Args:
        request: Counterfactual request
        api_key: API key for authentication
        
    Returns:
        Counterfactual analysis results
    """
    log_api_call("/counterfactual", "POST", startup_id=request.startup_id)
    
    try:
        # Get startup data
        db = get_database_service()
        startup_data = db.get_startup(request.startup_id)
        
        if not startup_data:
            raise HTTPException(404, f"Startup {request.startup_id} not found")
        
        responses = startup_data.get("questionnaire_responses", {})
        current_score = startup_data.get("analysis_score", 70) / 100.0
        
        # Use Gemini for counterfactual analysis
        genai = GeminiGenerator()
        
        prompt = f"""Analyze how changing these metrics would impact the investment score:

Current metrics:
{json.dumps(responses, indent=2)}

Current score: {current_score * 100}/100

Proposed changes:
{json.dumps(request.delta or {}, indent=2)}

Return JSON with:
{{
  "original_score": {current_score},
  "new_score": float (0-1),
  "impact_analysis": {{"metric": "impact description", ...}},
  "key_insights": ["insight 1", ...]
}}"""
        
        response = await genai._generate(prompt)
        result = json.loads(response)
        
        return CounterfactualResponse(
            startup_id=request.startup_id,
            original_score=current_score,
            new_score=result.get("new_score", current_score),
            original_recommendation=RecommendationType.FOLLOW,
            new_recommendation=RecommendationType.INVEST if result.get("new_score", 0) > 0.75 else RecommendationType.FOLLOW,
            breakpoints={},
            impact_analysis=result.get("impact_analysis", {})
        )
        
    except Exception as e:
        logger.error(f"Counterfactual analysis failed: {str(e)}", exc_info=True)
        raise HTTPException(500, str(e))


@router.post("/ask", response_model=AskResponse)
async def ask_question(
    request: AskRequest,
    api_key: str = Depends(verify_api_key)
) -> AskResponse:
    """Answer questions about a startup using Gemini with full context.
    
    Args:
        request: Question request
        api_key: API key for authentication
        
    Returns:
        Answer with evidence
    """
    log_api_call("/ask", "POST", startup_id=request.startup_id)
    
    try:
        # Load full context
        from ..services.parsers_simple import load_startup_context
        
        db = get_database_service()
        context = load_startup_context(request.startup_id, db)
        
        if not context or len(context) < 50:
            raise HTTPException(404, "No data found for startup")
        
        # Use Gemini 2.5 Pro for Q&A
        import google.generativeai as genai_api
        genai_api.configure(api_key=settings.GEMINI_API_KEY)
        model = genai_api.GenerativeModel("gemini-2.5-pro")  # Using Gemini 2.5 Pro for better Q&A
        
        prompt = f"""Answer this question about the startup using ONLY the provided context.

QUESTION: {request.question}

CONTEXT:
{context}

Provide a direct, factual answer in 2-3 bullet points. Cite specific data from the context."""

        response = await model.generate_content_async(prompt)
        answer_text = response.text
        
        # Parse bullet points
        answer_bullets = [
            line.strip().lstrip('-•*').strip()
            for line in answer_text.split('\n')
            if line.strip() and not line.strip().startswith('#')
        ]
        
        if not answer_bullets:
            answer_bullets = [answer_text]
        
        # Create evidence
        evidence = [Evidence(
            id=f"{request.startup_id}_qa",
            type=DocumentType.TEXT,
            location="questionnaire",
            snippet=context[:200],
            confidence=0.9
        )]
        
        return AskResponse(
            startup_id=request.startup_id,
            question=request.question,
            answer=answer_bullets[:3],
            evidence=evidence,
            confidence=0.9
        )
        
    except Exception as e:
        logger.error(f"Q&A failed: {str(e)}", exc_info=True)
        raise HTTPException(500, str(e))

