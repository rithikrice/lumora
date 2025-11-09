"""Financial modeling and projections API."""

import json
from fastapi import APIRouter, Depends, HTTPException
from typing import Dict, Any, List
from pydantic import BaseModel
import google.generativeai as genai

from ..core.security import verify_api_key
from ..core.logging import get_logger
from ..core.config import get_settings
from ..services.database import get_database_service

logger = get_logger(__name__)
router = APIRouter()
settings = get_settings()


class FinanceModelRequest(BaseModel):
    """Request for financial model."""
    startup_id: str
    years: int = 5
    scenarios: List[str] = ["base", "optimistic", "pessimistic"]


class NewsSignalsResponse(BaseModel):
    """News and market signals."""
    signals: List[Dict[str, Any]]
    summary: str


class GroundedQuery(BaseModel):
    """Request for grounded search."""
    startup_id: str
    query: str
    use_profile: bool = True
    use_pitch_deck: bool = True
    use_checklist: bool = True
    top_k: int = 6


@router.post("/finance/model")
async def generate_financial_model(
    request: FinanceModelRequest,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Generate financial projections using Gemini.
    
    Uses Google's Gemini to create realistic financial projections
    based on current metrics and growth assumptions.
    
    Args:
        request: Model parameters
        api_key: API key
        
    Returns:
        Financial projections
    """
    try:
        # Get startup data
        db = get_database_service()
        startup_data = db.get_startup(request.startup_id)
        
        if not startup_data:
            raise HTTPException(404, "Startup not found")
        
        responses = startup_data.get("questionnaire_responses", {})
        
        # Extract current metrics
        current_arr = responses.get("arr", 1000000)
        growth_rate = responses.get("growth_rate", 100)
        burn_rate = responses.get("burn_rate", 200000)
        gross_margin = responses.get("gross_margin", 70)
        
        # Use Gemini to generate realistic projections (fallback if API key fails)
        if not settings.GEMINI_API_KEY:
            logger.warning("Gemini API key not configured, using simple projections")
            return _generate_simple_projections(request, responses)
            
        genai.configure(api_key=settings.GEMINI_API_KEY)
        
        # Use stable fast model for finance projections
        model_name = "gemini-2.5-flash"  # Stable, fast, widely available
        logger.info(f"Using Gemini model: {model_name}")
        model = genai.GenerativeModel(model_name)
        
        prompt = f"""Generate {request.years}-year financial projections for a startup with these metrics:
ARR: ${current_arr:,}, Growth: {growth_rate}% YoY, Burn: ${burn_rate:,}/mo, Margin: {gross_margin}%

Provide 3 scenarios: {', '.join(request.scenarios)}

Return ONLY valid JSON in this exact format:
{{
  "scenarios": {{
    "base": [{{"year": 2025, "revenue": 1000000, "profit": 200000}}],
    "optimistic": [{{"year": 2025, "revenue": 1500000, "profit": 400000}}],
    "pessimistic": [{{"year": 2025, "revenue": 750000, "profit": 100000}}]
  }},
  "key_insights": ["Insight 1", "Insight 2"]
}}"""

        # Set generation config for faster responses
        generation_config = genai.types.GenerationConfig(
            temperature=0.7,
            max_output_tokens=1500,  # Reduced for faster response
        )
        
        logger.info("Calling Gemini API for financial projections...")
        
        # Use asyncio timeout to prevent hanging
        import asyncio
        try:
            response = await asyncio.wait_for(
                asyncio.to_thread(model.generate_content, prompt, generation_config=generation_config),
                timeout=30.0
            )
        except asyncio.TimeoutError:
            logger.warning("Gemini API call timed out after 30 seconds")
            raise TimeoutError("Gemini API call timed out")
        
        # Parse JSON response safely
        import re

        def _safe_response_text(resp) -> str:
            """Safely extract text from Gemini response without relying on resp.text."""
            try:
                return resp.text  # Fast path
            except Exception as e:
                logger.warning(f"response.text failed: {e}")
                try:
                    # Assemble from candidates -> content -> parts
                    if hasattr(resp, "candidates") and resp.candidates:
                        cand0 = resp.candidates[0]
                        parts = getattr(getattr(cand0, "content", None), "parts", []) or []
                        texts = []
                        for p in parts:
                            # SDK may expose part.text or dict-like
                            t = getattr(p, "text", None)
                            if not t and isinstance(p, dict):
                                t = p.get("text")
                            if t:
                                texts.append(t)
                        if texts:
                            return "".join(texts)
                except Exception as e2:
                    logger.warning(f"Failed to assemble text from candidates: {e2}")
            return ""

        raw_text = _safe_response_text(response)
        if not raw_text:
            raise ValueError("Empty response from Gemini model")

        # Remove markdown fences if present (start/end), robustly
        text = re.sub(r"```(?:json)?\s*", "", raw_text).strip()
        text = re.sub(r"\s*```\s*", "", text).strip()

        # Try JSON parse; if it fails, extract the largest JSON object substring
        try:
            projections = json.loads(text)
        except json.JSONDecodeError:
            # Extract substring between first '{' and last '}'
            start = text.find('{')
            end = text.rfind('}')
            if start != -1 and end != -1 and end > start:
                fallback_json = text[start:end+1]
                projections = json.loads(fallback_json)
            else:
                raise
        
        return {
            "startup_id": request.startup_id,
            "current_metrics": {
                "arr": current_arr,
                "growth_rate": growth_rate,
                "burn_rate": burn_rate,
                "gross_margin": gross_margin
            },
            "projections": projections,
            "generated_at": "2025-10-22T12:00:00Z"
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini response: {e}")
        # Return simple fallback projections
        return _generate_simple_projections(request, responses)
    except TimeoutError as e:
        logger.error(f"Gemini API timeout: {e}")
        # Return simple fallback projections
        return _generate_simple_projections(request, responses)
    except Exception as e:
        logger.error(f"Finance model error: {e}", exc_info=True)
        # Try to return fallback projections instead of failing completely
        try:
            return _generate_simple_projections(request, responses)
        except:
            raise HTTPException(500, f"Failed to generate projections: {str(e)}")


def _generate_simple_projections(request, responses):
    """Fallback simple projections."""
    try:
        current_arr = responses.get("arr", 1000000) if responses else 1000000
        growth_rate_pct = responses.get("growth_rate", 100) if responses else 100
        growth_rate = growth_rate_pct / 100
        burn_rate = responses.get("burn_rate", 200000) if responses else 200000
        gross_margin = responses.get("gross_margin", 70) if responses else 70
        
        scenarios = {
            "base": [],
            "optimistic": [],
            "pessimistic": []
        }
        
        for scenario_name in ["base", "optimistic", "pessimistic"]:
            # Adjust growth for scenario
            if scenario_name == "optimistic":
                adjusted_growth = growth_rate * 1.5
            elif scenario_name == "pessimistic":
                adjusted_growth = growth_rate * 0.5
            else:
                adjusted_growth = growth_rate
            
            # Project years
            arr = current_arr
            for year in range(request.years):
                arr = arr * (1 + adjusted_growth)
                scenarios[scenario_name].append({
                    "year": 2025 + year,
                    "revenue": int(arr),
                    "growth_rate": round(adjusted_growth * 100, 1)
                })
        
        return {
            "startup_id": request.startup_id,
            "current_metrics": {
                "arr": current_arr,
                "growth_rate": growth_rate_pct,
                "burn_rate": burn_rate,
                "gross_margin": gross_margin
            },
            "projections": {
                "scenarios": scenarios
            },
            "generated_at": "2025-10-31T12:00:00Z",
            "note": "Simple mathematical projections (Gemini unavailable)"
        }
    except Exception as e:
        logger.error(f"Fallback projections error: {e}")
        return {
            "startup_id": request.startup_id,
            "projections": {
                "scenarios": {"base": [], "optimistic": [], "pessimistic": []}
            },
            "error": "Unable to generate projections"
        }


@router.get("/news/signals")
async def get_news_signals(
    sector: str = "Technology",
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get market signals from TechCrunch and Yahoo Finance.
    
    Scrapes latest tech news and market trends relevant to the sector.
    
    Args:
        sector: Industry sector
        api_key: API key
        
    Returns:
        News signals and summary
    """
    try:
        signals = []
        news_items = []
        
        # TechCrunch RSS feed
        try:
            import feedparser
            logger.info("Fetching TechCrunch RSS...")
            tc_feed = feedparser.parse("https://techcrunch.com/feed/")
            
            if hasattr(tc_feed, 'entries') and tc_feed.entries:
                for entry in tc_feed.entries[:5]:
                    news_items.append({
                        "source": "TechCrunch",
                        "title": entry.title,
                        "link": entry.link,
                        "published": entry.get("published", ""),
                        "summary": entry.get("summary", "")[:200]
                    })
                    signals.append({
                        "type": "news",
                        "text": f"TechCrunch: {entry.title}",
                        "sentiment": "neutral"
                    })
                logger.info(f"Fetched {len(news_items)} TechCrunch articles")
            else:
                logger.warning("TechCrunch feed returned no entries")
        except Exception as e:
            logger.error(f"TechCrunch fetch failed: {e}", exc_info=True)
        
        # Yahoo Finance - use yfinance for market data
        try:
            import yfinance as yf
            logger.info("Fetching Yahoo Finance data...")
            
            # Get tech sector ETF as proxy
            ticker = yf.Ticker("XLK")  # Technology Select Sector SPDR
            hist = ticker.history(period="5d")
            
            if not hist.empty:
                current_price = hist['Close'].iloc[-1]
                prev_price = hist['Close'].iloc[-2] if len(hist) > 1 else current_price
                change_pct = ((current_price - prev_price) / prev_price) * 100
                
                signals.append({
                    "type": "market",
                    "text": f"Tech sector (XLK) at ${current_price:.2f} ({change_pct:+.2f}%)",
                    "sentiment": "positive" if change_pct > 0 else "negative"
                })
                logger.info(f"Yahoo Finance: XLK at ${current_price:.2f}")
            else:
                logger.warning("Yahoo Finance returned empty data")
        except Exception as e:
            logger.error(f"Yahoo Finance fetch failed: {e}", exc_info=True)
        
        # Generate summary with Gemini if API key available
        summary = "Market data collected successfully. " + (f"{len(news_items)} news articles found." if news_items else "No recent news.")
        if settings.GEMINI_API_KEY:
            try:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                model = genai.GenerativeModel("gemini-2.5-flash")  # Stable fast model
                
                prompt = f"""Analyze these market signals for the {sector} sector and provide a 2-sentence summary:

News: {len(news_items)} articles
Market: Tech sector {"up" if len(signals) > 0 and signals[-1].get("sentiment") == "positive" else "mixed"}

Focus on investment implications."""
                
                response = model.generate_content(prompt)
                summary = response.text
            except Exception as e:
                logger.warning(f"Gemini summary failed: {e}")
        
        # Return collected data
        return {
            "signals": signals,
            "news": news_items,
            "summary": summary,
            "sector": sector
        }
        
    except Exception as e:
        logger.error(f"News signals error: {e}")
        return {
            "signals": [],
            "summary": "Market signals currently unavailable.",
            "sector": sector
        }


@router.get("/search/grounded")
async def grounded_search(
    query: str,
    startup_id: str = None,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Perform grounded search with optional startup context.
    
    This unified API can work in two modes:
    1. General mode: Answer any question without startup context
    2. Context mode: Answer questions with startup-specific data when startup_id is provided
    
    Args:
        query: Search query or question
        startup_id: Optional startup ID for context-aware answers
        api_key: API key
        
    Returns:
        Grounded answer with citations and context
    """
    try:
        if not settings.GEMINI_API_KEY:
            raise HTTPException(
                status_code=500,
                detail="Gemini API key not configured. Please set GEMINI_API_KEY in environment."
            )
        
        # Reuse the same context-packet pipeline as POST grounded search
        from ..services.grounding import build_context_packets, answer_with_gemini
        
        packets = []
        if startup_id:
            packets = build_context_packets(
                startup_id=startup_id,
                query=query,
                top_k_pages=6,
                use_profile=True,
                use_pitch=True,
                use_checklist=True
            )
        
        if startup_id and not packets:
            raise HTTPException(
                status_code=404,
                detail=f"No context found for startup {startup_id}. Please upload pitch deck, checklist, or complete questionnaire."
            )
        
        result = answer_with_gemini(query, packets)
        
        return {
            "startup_id": startup_id,
            "query": query,
            "answer": result.get("answer", str(result)),
            "citations": result.get("citations", []),
            "confidence": result.get("confidence", "medium"),
            "missing": result.get("missing", []),
            "context_used": [{"type": p.get("type"), "page": p.get("page")} for p in packets] if packets else []
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Grounded search error: {e}", exc_info=True)
        raise HTTPException(500, f"Search failed: {str(e)}")


# Remove all code below until the next router definition
# The following orphaned code caused the issue:

if False:  # Dead code block to preserve line numbers temporarily
    def _orphaned():
        company_name = None
        pass  # Removed dead code


@router.post("/search/grounded", deprecated=True)
async def grounded_search_post(
    body: GroundedQuery,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Grounded search endpoint - answers questions strictly from startup context.
    
    Uses profile (SSoT) + relevant pages from pitch deck and checklist.
    Returns clean citations and prevents hallucinations.
    
    Args:
        body: Grounded query request
        api_key: API key for authentication
        
    Returns:
        Answer with citations, confidence, and context used
    """
    try:
        from ..services.grounding import build_context_packets, answer_with_gemini
        
        packets = build_context_packets(
            startup_id=body.startup_id,
            query=body.query,
            top_k_pages=body.top_k,
            use_profile=body.use_profile,
            use_pitch=body.use_pitch_deck,
            use_checklist=body.use_checklist
        )
        
        if not packets:
            raise HTTPException(
                status_code=404,
                detail=f"No context found for startup {body.startup_id}. Please upload pitch deck, checklist, or complete questionnaire."
            )
        
        result = answer_with_gemini(body.query, packets)
        
        return {
            "startup_id": body.startup_id,
            "query": body.query,
            "result": result,
            "context_used": [{"type": p["type"], "page": p.get("page")} for p in packets]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Grounded search failed: {e}", exc_info=True)
        raise HTTPException(500, f"Grounded search failed: {str(e)}")


@router.get("/debug/startup/{startup_id}")
async def debug_startup_data(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Debug endpoint to inspect startup data in database.
    
    This endpoint helps diagnose why context isn't being loaded properly.
    """
    try:
        from ..services.database import DatabaseService
        db = DatabaseService()
        startup_data = db.get_startup(startup_id)
        
        if not startup_data:
            return {
                "startup_id": startup_id,
                "found": False,
                "message": "Startup not found in database"
            }
        
        responses = startup_data.get("questionnaire_responses", {})
        
        return {
            "startup_id": startup_id,
            "found": True,
            "responses_type": str(type(responses)),
            "responses_is_dict": isinstance(responses, dict),
            "responses_is_list": isinstance(responses, list),
            "responses_count": len(responses) if isinstance(responses, (dict, list)) else 0,
            "response_keys": list(responses.keys()) if isinstance(responses, dict) else None,
            "sample_responses": dict(list(responses.items())[:10]) if isinstance(responses, dict) else None,
            "all_responses": responses if isinstance(responses, dict) else str(responses)[:500],
            "analysis_score": startup_data.get("analysis_score"),
        }
    except Exception as e:
        logger.error(f"Debug error: {e}", exc_info=True)
        return {
            "startup_id": startup_id,
            "error": str(e)
        }


@router.post("/ask/grounded")
async def grounded_ask(
    request: Dict[str, Any],
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """POST version of grounded search - unified ask API with or without startup context.
    
    This is the main API for asking questions. It intelligently handles:
    1. General questions (no startup_id)
    2. Startup-specific questions (with startup_id)
    
    Request Body:
        {
            "question": "What is the company's ARR?",
            "startup_id": "optional-startup-id"
        }
    
    Returns:
        Contextual answer with citations
    """
    try:
        question = request.get("question")
        startup_id = request.get("startup_id")
        
        if not question:
            raise HTTPException(400, "Question is required")
        
        # Use the same grounded search logic
        return await grounded_search(
            query=question,
            startup_id=startup_id,
            api_key=api_key
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Grounded ask error: {e}", exc_info=True)
        raise HTTPException(500, f"Ask failed: {str(e)}")

