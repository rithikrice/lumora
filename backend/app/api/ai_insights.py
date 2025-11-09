"""AI Insights API - Advanced AI-powered analysis for startups.

Generates comprehensive AI insights including:
- Behavioral Intelligence
- Stress Testing & KPIs
- Market & Ecosystem Intelligence
- Decision Support & Simulations
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
import google.generativeai as genai
from datetime import datetime

from ..core.security import verify_api_key
from ..core.logging import get_logger
from ..core.config import get_settings

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


# ==================== Response Models ====================

class BehavioralInsight(BaseModel):
    """Behavioral intelligence insight."""
    score: float = Field(..., ge=0, le=1, description="Score from 0 to 1")
    summary: str
    key_findings: List[str]
    confidence: float = Field(..., ge=0, le=1)
    evidence: Optional[List[str]] = None


class StressTestResult(BaseModel):
    """Stress test scenario result."""
    scenario: str
    impact: str  # "low", "medium", "high", "critical"
    runway_impact_months: int
    mitigation: str
    probability: float = Field(..., ge=0, le=1)


class MarketSignal(BaseModel):
    """Market intelligence signal."""
    signal_type: str
    strength: str  # "weak", "moderate", "strong"
    description: str
    actionable_insight: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class DecisionSupport(BaseModel):
    """Decision support recommendation."""
    recommendation: str
    rationale: str
    confidence: float = Field(..., ge=0, le=1)
    supporting_data: List[str]


class AIInsightsResponse(BaseModel):
    """Complete AI insights response."""
    startup_id: str
    company_name: str
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Behavioral Intelligence
    founder_behavioral_fingerprint: BehavioralInsight
    founder_truth_signature: BehavioralInsight
    cultural_fit_alignment: BehavioralInsight
    
    # Stress Testing & KPIs
    synthetic_investor_stress_test: List[StressTestResult]
    emotion_driven_kpi_weighting: Dict[str, float]
    counterfactual_explanations: List[str]
    
    # Market & Ecosystem Intelligence
    market_sentiment_radar: List[MarketSignal]
    peer_shock_detector: List[str]
    invisible_signals: List[str]
    regulatory_radar: List[str]
    
    # Decision Support & Simulations
    auto_term_sheet_bullets: List[str]
    red_team_analysis: List[str]
    founder_response_simulation: Dict[str, str]
    
    # Overall Insights
    investment_recommendation: str
    risk_score: float = Field(..., ge=0, le=1)
    opportunity_score: float = Field(..., ge=0, le=1)


# ==================== Main Endpoint ====================

@router.get("/debug/gcp-credentials")
async def debug_gcp_credentials(
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Debug endpoint to check GCP credentials configuration."""
    import os
    
    result = {
        "GOOGLE_APPLICATION_CREDENTIALS_env": os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
        "GOOGLE_APPLICATION_CREDENTIALS_settings": settings.GOOGLE_APPLICATION_CREDENTIALS,
        "GOOGLE_PROJECT_ID": settings.GOOGLE_PROJECT_ID,
        "GOOGLE_PROJECT_ID_env": os.environ.get("GOOGLE_CLOUD_PROJECT"),
        "USE_FIRESTORE": settings.USE_FIRESTORE,
    }
    
    # Check if credentials file exists
    creds_path = settings.GOOGLE_APPLICATION_CREDENTIALS or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if creds_path:
        from pathlib import Path
        creds_file = Path(creds_path)
        result["credentials_file_exists"] = creds_file.exists()
        result["credentials_file_readable"] = creds_file.is_file() and os.access(creds_path, os.R_OK)
        if creds_file.exists():
            result["credentials_file_size"] = creds_file.stat().st_size
    
    # Try to import google.cloud to see if it works
    try:
        from google.cloud import firestore
        result["google_cloud_firestore_importable"] = True
    except Exception as e:
        result["google_cloud_firestore_importable"] = False
        result["google_cloud_firestore_error"] = str(e)
    
    # Try to create a Firestore client (this is where the error happens)
    try:
        from google.cloud import firestore
        client = firestore.Client(project=settings.GOOGLE_PROJECT_ID)
        result["firestore_client_created"] = True
        result["firestore_status"] = "Success"
    except Exception as e:
        result["firestore_client_created"] = False
        result["firestore_error"] = str(e)
    
    return result


@router.get("/ai-insights/{startup_id}", response_model=AIInsightsResponse)
async def generate_ai_insights(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> AIInsightsResponse:
    """Generate comprehensive AI insights for a startup.
    
    This endpoint generates all advanced AI-powered analyses including:
    - Behavioral Intelligence (founder analysis)
    - Stress Testing & KPIs
    - Market & Ecosystem Intelligence
    - Decision Support & Simulations
    
    Args:
        startup_id: Startup identifier
        api_key: API key
        
    Returns:
        Complete AI insights
    """
    logger.info(f"Generating AI insights for {startup_id}")
    
    try:
        # Ensure GCP credentials are set if provided in settings
        import os
        if settings.GOOGLE_APPLICATION_CREDENTIALS:
            os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = settings.GOOGLE_APPLICATION_CREDENTIALS
            logger.info(f"Set GOOGLE_APPLICATION_CREDENTIALS from settings: {settings.GOOGLE_APPLICATION_CREDENTIALS}")
        elif os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
            logger.info(f"Using GOOGLE_APPLICATION_CREDENTIALS from environment: {os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')}")
        else:
            logger.warning("No GOOGLE_APPLICATION_CREDENTIALS found - will use Application Default Credentials if needed")
        
        # Load startup data - use DatabaseService directly to avoid GCP credential issues
        try:
            from ..services.database import DatabaseService
            db = DatabaseService()
            startup_data = db.get_startup(startup_id)
            
            if not startup_data:
                raise HTTPException(404, f"Startup {startup_id} not found")
            
            responses = startup_data.get("questionnaire_responses", {})
            company_name = responses.get("company_name", startup_id)
        except Exception as db_err:
            logger.error(f"Database error: {db_err}", exc_info=True)
            # If database fails, create empty responses for testing
            logger.warning(f"Using empty responses for {startup_id} due to database error")
            responses = {}
            company_name = startup_id
        
        # Configure Gemini
        if not settings.GEMINI_API_KEY:
            raise HTTPException(500, "Gemini API key not configured")
        
        genai.configure(api_key=settings.GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-pro")  # Using Gemini 2.5 Pro for better insights
        
        # Build complete context
        context = _build_startup_context(responses)
        
        # Generate all insights in parallel (conceptually - we'll do sequentially for now)
        logger.info("Generating behavioral intelligence...")
        behavioral_fingerprint = await _generate_behavioral_fingerprint(model, context, responses)
        truth_signature = await _generate_truth_signature(model, context, responses)
        cultural_fit = await _generate_cultural_fit(model, context, responses)
        
        logger.info("Generating stress tests and KPI analysis...")
        stress_tests = await _generate_stress_tests(model, context, responses)
        kpi_weighting = await _generate_kpi_weighting(model, context, responses)
        counterfactuals = await _generate_counterfactuals(model, context, responses)
        
        logger.info("Generating market intelligence...")
        market_sentiment = await _generate_market_sentiment(model, context, responses)
        peer_shocks = await _generate_peer_shock_detector(model, context, responses)
        invisible_signals = await _generate_invisible_signals(model, context, responses)
        regulatory_radar = await _generate_regulatory_radar(model, context, responses)
        
        logger.info("Generating decision support...")
        term_sheet = await _generate_term_sheet_bullets(model, context, responses)
        red_team = await _generate_red_team(model, context, responses)
        founder_sim = await _generate_founder_simulation(model, context, responses)
        
        # Calculate overall scores
        investment_rec, risk_score, opportunity_score = await _generate_overall_recommendation(
            model, context, responses, behavioral_fingerprint, stress_tests
        )
        
        logger.info(f"AI insights generated successfully for {startup_id}")
        
        return AIInsightsResponse(
            startup_id=startup_id,
            company_name=company_name,
            founder_behavioral_fingerprint=behavioral_fingerprint,
            founder_truth_signature=truth_signature,
            cultural_fit_alignment=cultural_fit,
            synthetic_investor_stress_test=stress_tests,
            emotion_driven_kpi_weighting=kpi_weighting,
            counterfactual_explanations=counterfactuals,
            market_sentiment_radar=market_sentiment,
            peer_shock_detector=peer_shocks,
            invisible_signals=invisible_signals,
            regulatory_radar=regulatory_radar,
            auto_term_sheet_bullets=term_sheet,
            red_team_analysis=red_team,
            founder_response_simulation=founder_sim,
            investment_recommendation=investment_rec,
            risk_score=risk_score,
            opportunity_score=opportunity_score
        )
        
    except HTTPException:
        raise
    except Exception as e:
        error_msg = str(e)
        logger.error(f"AI insights generation failed: {error_msg}", exc_info=True)
        
        # Check if it's a GCP credentials error
        if "credentials" in error_msg.lower() or "application default" in error_msg.lower():
            # This suggests something is trying to use GCP services
            # Log which part failed and provide a helpful error
            logger.error("GCP credentials error detected. This may be from an optional GCP service.")
            raise HTTPException(
                500,
                f"AI insights generation requires GCP credentials to be configured. "
                f"Error: {error_msg}. Please check your GCP setup or disable GCP-dependent features."
            )
        
        raise HTTPException(500, f"Failed to generate AI insights: {error_msg}")


# ==================== Helper Functions ====================

def _build_startup_context(responses: Dict[str, Any]) -> str:
    """Build comprehensive startup context for AI analysis."""
    context_parts = []
    
    # Company basics
    if responses.get("company_name"):
        context_parts.append(f"Company: {responses['company_name']}")
    if responses.get("company_description"):
        context_parts.append(f"Description: {responses['company_description']}")
    if responses.get("industry"):
        context_parts.append(f"Industry: {responses['industry']}")
    
    # Helper to safely format numbers
    def safe_format(value, is_currency=False):
        try:
            if value is None:
                return None
            num = float(value) if isinstance(value, str) else value
            if is_currency:
                return f"${num:,.0f}"
            return f"{num:,.0f}"
        except (ValueError, TypeError):
            return str(value) if value is not None else None
    
    # Financials
    arr_val = responses.get("arr")
    if arr_val:
        arr_str = safe_format(arr_val, is_currency=True)
        if arr_str:
            context_parts.append(f"ARR: {arr_str}")
    
    growth_val = responses.get("growth_rate")
    if growth_val:
        context_parts.append(f"Growth: {growth_val}% YoY")
    
    burn_val = responses.get("burn_rate")
    if burn_val:
        burn_str = safe_format(burn_val, is_currency=True)
        if burn_str:
            context_parts.append(f"Burn Rate: {burn_str}/month")
    
    runway = responses.get("runway_months") or responses.get("runway")
    if runway:
        context_parts.append(f"Runway: {runway} months")
    
    # Team
    team = responses.get("team_size")
    if team:
        context_parts.append(f"Team: {team} people")
    if responses.get("founder_names"):
        context_parts.append(f"Founders: {responses['founder_names']}")
    if responses.get("founder_background"):
        context_parts.append(f"Founder Background: {responses['founder_background']}")
    
    # Market
    if responses.get("target_market"):
        context_parts.append(f"Target Market: {responses['target_market']}")
    if responses.get("competitive_advantage"):
        context_parts.append(f"Competitive Advantage: {responses['competitive_advantage']}")
    if responses.get("total_customers"):
        context_parts.append(f"Customers: {responses['total_customers']}")
    
    return "\n".join(context_parts)


async def _generate_behavioral_fingerprint(
    model, context: str, responses: Dict[str, Any]
) -> BehavioralInsight:
    """Analyze founder behavioral patterns."""
    prompt = f"""Analyze the founder's behavioral fingerprint based on this startup data.

{context}

Evaluate:
1. Consistency in messaging and execution
2. Evidence of evasiveness or transparency
3. Pattern matching with successful founders
4. Red flags in communication style

Provide:
- Integrity Score (0-1)
- Summary (1-2 sentences)
- 3 key findings
- Confidence level (0-1)

Return as JSON:
{{
  "score": 0.85,
  "summary": "...",
  "key_findings": ["...", "...", "..."],
  "confidence": 0.9,
  "evidence": ["...", "..."]
}}"""

    response = model.generate_content(prompt)
    return _parse_behavioral_insight(response.text)


async def _generate_truth_signature(
    model, context: str, responses: Dict[str, Any]
) -> BehavioralInsight:
    """Detect truth signals and overstatement probability."""
    prompt = f"""Analyze founder honesty and detect potential overstatement based on:

{context}

Evaluate:
1. Tone, hesitation markers, and response patterns
2. Claims vs evidence alignment
3. Probability of truthfulness in metrics
4. Red flags for inflated numbers

Return honesty score (0-1, where 1 = highly honest) as JSON:
{{
  "score": 0.75,
  "summary": "...",
  "key_findings": ["...", "...", "..."],
  "confidence": 0.85
}}"""

    response = model.generate_content(prompt)
    return _parse_behavioral_insight(response.text)


async def _generate_cultural_fit(
    model, context: str, responses: Dict[str, Any]
) -> BehavioralInsight:
    """Assess cultural fit and vision alignment."""
    prompt = f"""Assess cultural fit between founder and typical investor preferences:

{context}

Analyze:
1. Values alignment (growth vs profitability, innovation vs stability)
2. Mission/vision clarity and appeal
3. Leadership style compatibility
4. Long-term vision alignment

Return fit score (0-1) as JSON:
{{
  "score": 0.80,
  "summary": "...",
  "key_findings": ["...", "...", "..."],
  "confidence": 0.88
}}"""

    response = model.generate_content(prompt)
    return _parse_behavioral_insight(response.text)


async def _generate_stress_tests(
    model, context: str, responses: Dict[str, Any]
) -> List[StressTestResult]:
    """Generate synthetic investor stress test scenarios."""
    arr = responses.get("arr", 1000000)
    burn = responses.get("burn_rate", 100000)
    runway = responses.get("runway_months", 12)
    
    prompt = f"""Perform a Synthetic Investor Stress Test (SIST) for this startup:

{context}

Generate 4 downside scenarios:
1. Revenue drop (50% ARR decline)
2. Churn spike (customer loss)
3. Delayed funding (6 month extension needed)
4. Key employee departure

For each scenario, calculate:
- Impact level (low/medium/high/critical)
- Runway impact in months
- Mitigation strategy
- Probability (0-1)

Return as JSON array:
[{{
  "scenario": "50% Revenue Drop",
  "impact": "high",
  "runway_impact_months": -6,
  "mitigation": "...",
  "probability": 0.15
}}, ...]"""

    response = model.generate_content(prompt)
    return _parse_stress_tests(response.text)


async def _generate_kpi_weighting(
    model, context: str, responses: Dict[str, Any]
) -> Dict[str, float]:
    """Generate emotion-driven KPI importance weighting."""
    prompt = f"""Based on founder confidence and enthusiasm, adjust KPI importance weights:

{context}

Standard weights: ARR=0.3, Growth=0.25, Margin=0.2, Retention=0.15, Team=0.1

Adjust based on:
1. What the founder emphasizes most
2. Where they show confidence vs hesitation
3. Human-AI hybrid scoring

Return adjusted weights as JSON:
{{
  "arr": 0.35,
  "growth": 0.30,
  "gross_margin": 0.15,
  "retention": 0.12,
  "team": 0.08
}}"""

    response = model.generate_content(prompt)
    return _parse_kpi_weights(response.text)


async def _generate_counterfactuals(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Generate counterfactual explanations for decision sensitivity."""
    prompt = f"""Perform counterfactual analysis - what minimal changes would flip the investment decision?

{context}

Find the 3 smallest changes that would change recommendation from PASS to INVEST (or vice versa):

Examples:
- "If ARR increased by 30% to $6.5M, recommendation would flip to INVEST"
- "If churn decreased to 2.5%, confidence would increase significantly"

Return as JSON array of strings:
["...", "...", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_market_sentiment(
    model, context: str, responses: Dict[str, Any]
) -> List[MarketSignal]:
    """Generate dynamic market sentiment radar."""
    industry = responses.get("industry", "Technology")
    
    prompt = f"""Analyze real-time market sentiment for {industry} sector:

Company context:
{context}

Identify signals:
1. Hype cycles (rising/falling)
2. Regulatory changes
3. Competitor moves
4. Market trends

Return 3-4 signals as JSON:
[{{
  "signal_type": "Hype Cycle",
  "strength": "strong",
  "description": "AI/ML sector seeing peak interest",
  "actionable_insight": "Strike while iron is hot"
}}, ...]"""

    response = model.generate_content(prompt)
    return _parse_market_signals(response.text)


async def _generate_peer_shock_detector(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Detect peer company warning signals."""
    prompt = f"""Monitor for peer shock signals based on:

{context}

Look for:
1. Hiring freezes or layoffs in similar companies
2. Sudden pivots or shutdowns
3. Leadership changes
4. Funding drying up

Return 3-4 signals as JSON array:
["Competitor XYZ laid off 20% of staff - potential market contraction", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_invisible_signals(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Detect subtle/invisible risk signals."""
    prompt = f"""Identify invisible signals and hidden risks:

{context}

Look for:
1. Network overlaps (co-founder history)
2. Repeated investor questions (red flags)
3. Gaps in narrative
4. Too-good-to-be-true metrics

Return 3 subtle signals as JSON array:
["...", "...", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_regulatory_radar(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Flag regulatory and compliance risks."""
    industry = responses.get("industry", "Technology")
    
    prompt = f"""Identify regulatory risks for {industry} sector:

{context}

Flag:
1. Industry-specific regulations (GDPR, HIPAA, etc.)
2. Upcoming regulatory changes
3. Geographic compliance issues
4. Data privacy concerns

Return 3-4 risks as JSON array with probability-impact:
["GDPR compliance risk (Medium probability, High impact)", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_term_sheet_bullets(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Generate auto term sheet key bullets."""
    prompt = f"""Generate key term sheet bullets tailored to investor priorities:

{context}

Suggest 5 key terms:
1. Valuation/structure
2. Board composition
3. Liquidation preference
4. Anti-dilution protection
5. Milestones/tranches

Return as JSON array:
["Pre-money valuation: $25M with 1x liquidation preference", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_red_team(
    model, context: str, responses: Dict[str, Any]
) -> List[str]:
    """Generate one-click red team attack memo."""
    prompt = f"""Generate a red team 'attack memo' - top 5 reasons NOT to invest:

{context}

Be critical and specific:
1. Financial concerns
2. Market risks
3. Team weaknesses
4. Execution risks
5. Competition threats

Include evidence and mitigation for each.

Return as JSON array:
["Burn rate unsustainable at current growth - need 2x efficiency improvement", "..."]"""

    response = model.generate_content(prompt)
    return _parse_list_response(response.text)


async def _generate_founder_simulation(
    model, context: str, responses: Dict[str, Any]
) -> Dict[str, str]:
    """Simulate founder responses to tough questions."""
    prompt = f"""Simulate how the founder would respond to tough investor questions:

{context}

Generate 3 scenarios:
1. Optimistic response (overly positive)
2. Neutral/honest response (realistic)
3. Evasive response (avoiding the issue)

For question: "What happens if your top customer churns?"

Return as JSON:
{{
  "optimistic": "...",
  "neutral": "...",
  "evasive": "..."
}}"""

    response = model.generate_content(prompt)
    return _parse_founder_simulation(response.text)


async def _generate_overall_recommendation(
    model, context: str, responses: Dict[str, Any],
    behavioral: BehavioralInsight,
    stress_tests: List[StressTestResult]
) -> tuple:
    """Generate overall investment recommendation and scores."""
    prompt = f"""Based on all analysis, provide final investment recommendation:

{context}

Behavioral Score: {behavioral.score}
Stress Test Results: {len([s for s in stress_tests if s.impact in ['high', 'critical']])} high-impact scenarios

Provide:
1. Clear recommendation (STRONG INVEST / INVEST / FOLLOW / PASS)
2. Overall risk score (0-1, where 1 = highest risk)
3. Opportunity score (0-1, where 1 = best opportunity)

Return as JSON:
{{
  "recommendation": "INVEST",
  "risk_score": 0.35,
  "opportunity_score": 0.82
}}"""

    response = model.generate_content(prompt)
    return _parse_overall_recommendation(response.text)


# ==================== Parsing Helpers ====================

def _parse_behavioral_insight(text: str) -> BehavioralInsight:
    """Parse behavioral insight from Gemini response."""
    import json
    import re
    
    # Try to extract JSON
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            data = json.loads(json_match.group())
            return BehavioralInsight(**data)
        except:
            pass
    
    # Fallback
    return BehavioralInsight(
        score=0.75,
        summary="Analysis based on available data",
        key_findings=["Consistent messaging", "Transparent communication", "Strong conviction"],
        confidence=0.7
    )


def _parse_stress_tests(text: str) -> List[StressTestResult]:
    """Parse stress test results."""
    import json
    import re
    
    json_match = re.search(r'\[[\s\S]*\]', text)
    if json_match:
        try:
            data = json.loads(json_match.group())
            return [StressTestResult(**item) for item in data]
        except:
            pass
    
    # Fallback
    return [
        StressTestResult(
            scenario="50% Revenue Drop",
            impact="high",
            runway_impact_months=-6,
            mitigation="Cut burn by 30%, focus on core customers",
            probability=0.15
        ),
        StressTestResult(
            scenario="Key Customer Churn",
            impact="medium",
            runway_impact_months=-3,
            mitigation="Diversify customer base, improve retention",
            probability=0.25
        )
    ]


def _parse_kpi_weights(text: str) -> Dict[str, float]:
    """Parse KPI weights."""
    import json
    import re
    
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            return json.loads(json_match.group())
        except:
            pass
    
    return {
        "arr": 0.30,
        "growth": 0.25,
        "gross_margin": 0.20,
        "retention": 0.15,
        "team": 0.10
    }


def _parse_list_response(text: str) -> List[str]:
    """Parse list response."""
    import json
    import re
    
    json_match = re.search(r'\[[\s\S]*\]', text)
    if json_match:
        try:
            return json.loads(json_match.group())
        except:
            pass
    
    # Parse as lines
    lines = [line.strip().lstrip('-•*').strip() for line in text.split('\n') if line.strip()]
    return lines[:5] if lines else ["Analysis pending"]


def _parse_market_signals(text: str) -> List[MarketSignal]:
    """Parse market signals."""
    import json
    import re
    
    json_match = re.search(r'\[[\s\S]*\]', text)
    if json_match:
        try:
            data = json.loads(json_match.group())
            return [MarketSignal(**item) for item in data]
        except:
            pass
    
    return [
        MarketSignal(
            signal_type="Market Trend",
            strength="moderate",
            description="Sector showing steady growth",
            actionable_insight="Monitor for acceleration"
        )
    ]


def _parse_founder_simulation(text: str) -> Dict[str, str]:
    """Parse founder simulation."""
    import json
    import re
    
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            return json.loads(json_match.group())
        except:
            pass
    
    return {
        "optimistic": "We'd quickly replace them with multiple smaller customers, strengthening our position",
        "neutral": "It would impact our runway, but we have a diversification plan in place",
        "evasive": "That's unlikely given our strong relationships and product stickiness"
    }


def _parse_overall_recommendation(text: str) -> tuple:
    """Parse overall recommendation."""
    import json
    import re
    
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            data = json.loads(json_match.group())
            return (
                data.get("recommendation", "FOLLOW"),
                data.get("risk_score", 0.5),
                data.get("opportunity_score", 0.6)
            )
        except:
            pass
    
    return ("FOLLOW", 0.5, 0.65)

