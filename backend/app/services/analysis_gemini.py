"""Full-context analysis using Gemini 2.0 Flash (no RAG/chunking)."""

import json
import re
from typing import Dict, Any, List
from datetime import datetime

import google.generativeai as genai

from ..core.config import get_settings
from ..core.logging import get_logger
from ..models.dto import AnalyzeResponse, KPIMetrics, Risk, Evidence, DocumentType, RecommendationType
from ..services.database import get_database_service
from ..services.parsers_simple import load_startup_context

logger = get_logger(__name__)
settings = get_settings()


async def analyze_startup_with_gemini(startup_id: str, persona_weights: Dict[str, float] = None) -> AnalyzeResponse:
    """Perform comprehensive analysis using Gemini 2.0 Flash with full context.
    
    No RAG/chunking - just load everything and send to Gemini!
    
    Args:
        startup_id: Startup to analyze
        persona_weights: Optional persona weights
        
    Returns:
        Complete analysis
    """
    try:
        # Initialize Gemini 2.5 Pro for best analysis accuracy
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-pro")
        
        # Load full startup context
        db = get_database_service()
        context = load_startup_context(startup_id, db)
        
        if not context or len(context) < 100:
            raise ValueError("Insufficient startup data for analysis")
        
        # Get company name for personalization
        startup_data = db.get_startup(startup_id)
        responses = startup_data.get("questionnaire_responses", {}) if startup_data else {}
        company_name = responses.get("company_name", "the startup")
        
        # Build comprehensive analysis prompt
        prompt = f"""You are a senior venture capital investor analyzing {company_name} for potential investment.

STARTUP DATA:
{context}

TASK: Provide a comprehensive investment analysis with:

1. **Executive Summary** (3-5 bullet points)
   - Key strengths
   - Main concerns
   - Investment thesis

2. **KPI Metrics** (extract and analyze):
   - ARR (Annual Recurring Revenue)
   - Growth rate (%)
   - Gross margin (%)
   - Burn rate (monthly)
   - Runway (months)
   - CAC/LTV ratio
   - Net Revenue Retention (NRR)
   - Logo retention

3. **Risk Assessment** (top 5 risks with severity 1-5):
   - Market risks
   - Execution risks
   - Financial risks
   - Team risks
   - Competitive risks

4. **Investment Recommendation**:
   - INVEST (score >= 75)
   - FOLLOW (score 55-74)
   - PASS (score < 55)

5. **Investment Score** (0-100):
   Based on:
   - Market opportunity (30%)
   - Product/technology (25%)
   - Team (25%)
   - Traction/metrics (20%)

Return ONLY valid JSON with this exact structure:
{{
  "executive_summary": ["point 1", "point 2", ...],
  "kpis": {{
    "arr": number,
    "growth_rate": number,
    "gross_margin": number,
    "burn_rate": number,
    "runway_months": number,
    "cac_ltv_ratio": number,
    "nrr": number,
    "logo_retention": number
  }},
  "risks": [
    {{
      "label": "risk description",
      "severity": 1-5,
      "evidence_id": "source",
      "mitigation": "how to mitigate"
    }},
    ...
  ],
  "recommendation": "invest|follow|pass",
  "score": 0-100,
  "reasoning": "brief explanation of score"
}}

Be thorough but concise. Use actual data from the context."""

        # Generate analysis
        logger.info(f"Sending {len(context)} chars to Gemini 2.0 Flash for analysis...")
        
        response = await model.generate_content_async(
            prompt,
            generation_config={
                "temperature": 0.3,  # Factual, consistent
                "max_output_tokens": 8000,
            }
        )
        
        # Parse JSON response
        result_text = response.text
        
        # Clean markdown if present
        result_text = re.sub(r'```json\s*', '', result_text)
        result_text = re.sub(r'```\s*$', '', result_text.strip())
        
        try:
            analysis = json.loads(result_text)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response: {e}")
            logger.error(f"Response text: {result_text[:500]}")
            raise ValueError("Gemini returned invalid JSON")
        
        # Build KPIs
        kpis_data = analysis.get("kpis", {})
        kpis = KPIMetrics(
            arr=kpis_data.get("arr"),
            growth_rate=kpis_data.get("growth_rate"),
            gross_margin=kpis_data.get("gross_margin"),
            burn_rate=kpis_data.get("burn_rate"),
            runway_months=kpis_data.get("runway_months"),
            cac_ltv_ratio=kpis_data.get("cac_ltv_ratio"),
            nrr=kpis_data.get("nrr"),
            logo_retention=kpis_data.get("logo_retention")
        )
        
        # Build risks
        risks = []
        for risk_data in analysis.get("risks", [])[:5]:  # Top 5
            risks.append(Risk(
                label=risk_data.get("label", "Unknown risk"),
                severity=risk_data.get("severity", 3),
                evidence_id=risk_data.get("evidence_id", "gemini_analysis"),
                mitigation=risk_data.get("mitigation")
            ))
        
        # Build evidence
        evidence = [Evidence(
            id=f"{startup_id}_gemini_analysis",
            type=DocumentType.TEXT,
            location="questionnaire",
            snippet="Full context analysis by Gemini 2.0 Flash",
            confidence=0.95
        )]
        
        # Map recommendation
        rec_str = analysis.get("recommendation", "follow").lower()
        if rec_str == "invest":
            recommendation = RecommendationType.INVEST
        elif rec_str == "pass":
            recommendation = RecommendationType.PASS
        else:
            recommendation = RecommendationType.FOLLOW
        
        # Get score
        score = analysis.get("score", 70)
        if not isinstance(score, (int, float)):
            score = 70
        score = max(0, min(100, score))  # Clamp 0-100
        
        # Save analysis to database
        analyze_response = AnalyzeResponse(
            startup_id=startup_id,
            company_name=company_name,
            executive_summary=analysis.get("executive_summary", ["Analysis complete"]),
            kpis=kpis,
            risks=risks,
            recommendation=recommendation,
            score=score / 100.0,  # Normalize to 0-1
            investment_score=float(score),
            evidence=evidence,
            persona_scores={},
            timestamp=datetime.utcnow()
        )
        
        # Save to database
        db.save_startup(startup_id, analyze_response)
        
        logger.info(f"Analysis complete: {company_name} scored {score}/100")
        
        return analyze_response
        
    except Exception as e:
        logger.error(f"Gemini analysis failed: {e}")
        raise

