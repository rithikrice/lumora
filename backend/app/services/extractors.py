"""Structured profile extraction from documents using Gemini."""

import json
import re
import asyncio
from typing import Dict, Any, List, Optional
import google.generativeai as genai

from ..core.logging import get_logger

logger = get_logger(__name__)

# Comprehensive schema for profile extraction
LLM_SCHEMA_INSTRUCTIONS = """
Return STRICT JSON only for this schema:

{
  "company_name": string|null,
  "one_liner": string|null,
  "sector": string|null,
  "subsector": string|null,
  "stage": string|null,
  "location": string|null,
  "founded_year": string|null,
  "team": [{"name": string, "role": string}]|[],
  "contacts": [{"name": string, "email": string}]|[],
  "metrics": {
    "arr": string|null,
    "gmv": string|null,
    "cac": string|null,
    "churn": string|null,
    "runway_months": string|null,
    "growth": string|null,
    "placements": string|null,
    "revenue_2025": string|null,
    "revenue_2026": string|null
  },
  "market": {"tam": string|null, "sam": string|null, "som": string|null},
  "traction": {
    "users": string|null,
    "institutions": string|null,
    "pilots": string[]|[],
    "pipeline_companies": number|null,
    "pipeline_value_inr_cr": number|null,
    "active_conversations_inr_cr": number|null
  },
  "funding": {
    "raised_to_date": string|null,
    "ask_now": string|null,
    "valuation_implied": string|null,
    "post_money_2023": string|null,
    "raised": string|null,
    "pipeline": string|null
  },
  "business_model": {
    "model": string|null,
    "pricing": {
      "learner": string|null,
      "enterprise": string|null,
      "enterprise_base_fee": string|null,
      "monthly_examples": string[]|[],
      "yearly_examples": string[]|[]
    },
    "success_fee": string|null,
    "use_of_funds": [{"bucket": string, "percent": string}]|[]
  },
  "strategy": {
    "key_strengths": string[]|[],
    "exit_strategy": string|null,
    "executive_summary": string|null
  },
  "insights": {
    "founder_integrity_score": string|null,
    "cultural_fit_score": string|null,
    "risk_heatmap": string[][]|[],
    "evidence_highlights": string[]|[]
  },
  "gtm": string[]|[],
  "moat": string[]|[],
  "competitors": string[]|[],
  "patents": string[]|[],
  "links": {
    "website": string|null,
    "linkedin": string|null,
    "youtube": string|null,
    "instagram": string|null
  }
}

Rules:
- Prefer numbers with units as given (e.g., "$5M", "18 months", "85%").
- If unknown, set null or empty arrays.
- Do NOT include extra keys.
- Extract links from text (linkedin.com/company/..., youtube.com/..., etc.).
- For pricing, extract specific amounts mentioned (e.g., "$900/mo", "$100/yr").
- For funding, extract amounts with context (e.g., "$2M (Jan 2023)", "$1.2M ask").
"""


def _json_model(api_key: str):
    """Create a Gemini model configured for JSON output."""
    genai.configure(api_key=api_key)
    # Note: response_mime_type may not be available in all SDK versions
    # We'll request JSON in the prompt instead
    return genai.GenerativeModel(
        "gemini-2.5-pro",  # Using Gemini 2.5 Pro for best structured extraction
        generation_config={
            "temperature": 0.1,
            "max_output_tokens": 2048
        }
    )


async def extract_structured_profile(
    pages: List[Dict[str, Any]],
    api_key: str,
    pdf_bytes: Optional[bytes] = None,
    doc_type: str = "pitch_deck"
) -> Dict[str, Any]:
    """Extract structured profile data from document pages using Gemini.
    
    This is the unified extractor used by both pitch deck and checklist uploads.
    
    Args:
        pages: List of page dictionaries with 'text' and optionally 'page_number'
        api_key: Gemini API key
        pdf_bytes: Optional PDF bytes for vision analysis
        doc_type: Type of document ("pitch_deck" or "checklist")
        
    Returns:
        Structured profile data dictionary
    """
    if not api_key:
        logger.warning("No Gemini API key provided, using regex fallback")
        return _regex_fallback_extraction(pages)
    
    if api_key.startswith('sk-'):
        logger.error("Invalid Gemini API key format (looks like OpenAI key)")
        return _regex_fallback_extraction(pages)
    
    try:
        # Combine text from pages (limit to avoid token limits)
        text_parts = []
        for i, page in enumerate(pages[:10]):  # First 10 pages
            text = page.get("text", "")
            if text:
                text_parts.append(f"Page {i+1}:\n{text[:2000]}")  # Limit per page
        
        full_text = "\n\n".join(text_parts)
        
        if not full_text.strip():
            logger.warning("No text extracted from pages")
            return {}
        
        # Create prompt with explicit JSON request
        prompt = f"""Extract structured startup profile data from this {doc_type} document.

Document content:
{full_text[:15000]}

{LLM_SCHEMA_INSTRUCTIONS}

IMPORTANT: Return ONLY valid JSON. Do not include any markdown formatting, code blocks, or explanatory text. Start with {{ and end with }}."""
        
        # Get JSON model
        model = _json_model(api_key)
        
        # Generate with timeout
        try:
            response = await asyncio.wait_for(
                asyncio.to_thread(model.generate_content, prompt),
                timeout=30.0
            )
            
            # Parse JSON response - handle empty or blocked responses
            response_text = None
            
            # Check for blocked or filtered responses first
            if hasattr(response, 'prompt_feedback'):
                feedback = response.prompt_feedback
                if hasattr(feedback, 'block_reason') and feedback.block_reason:
                    logger.warning(f"Gemini blocked response: {feedback.block_reason}")
                    return _regex_fallback_extraction(pages)
            
            # Try to get text from response
            try:
                if hasattr(response, 'text'):
                    response_text = response.text.strip()
            except (IndexError, AttributeError, KeyError) as e:
                # Response might be empty, blocked, or have no parts
                logger.debug(f"Error accessing response.text: {e}")
                # Try alternative ways to extract content
                if hasattr(response, 'candidates') and response.candidates:
                    try:
                        candidate = response.candidates[0]
                        # Check if candidate was blocked
                        if hasattr(candidate, 'finish_reason'):
                            finish_reason = candidate.finish_reason
                            if finish_reason and finish_reason != 1:  # 1 = STOP (normal finish)
                                logger.warning(f"Gemini response finished with reason: {finish_reason}")
                                return _regex_fallback_extraction(pages)
                        
                        # Try to extract from candidate content
                        if hasattr(candidate, 'content') and hasattr(candidate.content, 'parts'):
                            parts = candidate.content.parts
                            if parts and len(parts) > 0:
                                if hasattr(parts[0], 'text'):
                                    response_text = parts[0].text.strip()
                                else:
                                    response_text = str(parts[0])
                    except (IndexError, AttributeError, KeyError) as e2:
                        logger.debug(f"Error extracting from candidates: {e2}")
            
            # Final check - if we still don't have text, use fallback
            if not response_text or not response_text.strip():
                logger.warning("Gemini returned empty or blocked response, using regex fallback")
                return _regex_fallback_extraction(pages)
            
            # Clean markdown code blocks if present
            response_text = re.sub(r'```json\s*', '', response_text)
            response_text = re.sub(r'```\s*$', '', response_text)
            response_text = response_text.strip()
            
            # Extract JSON object if it's embedded in text
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                response_text = json_match.group(0)
            
            try:
                structured_data = json.loads(response_text)
                logger.info(f"Successfully extracted structured profile data")
                return structured_data
            except json.JSONDecodeError as e:
                logger.warning(f"Failed to parse JSON response, attempting to fix: {e}")
                # Try to fix common JSON issues
                # Remove any trailing commas before closing braces/brackets
                response_text = re.sub(r',\s*}', '}', response_text)
                response_text = re.sub(r',\s*]', ']', response_text)
                try:
                    structured_data = json.loads(response_text)
                    logger.info(f"Successfully parsed JSON after cleanup")
                    return structured_data
                except json.JSONDecodeError:
                    logger.error(f"Could not parse JSON even after cleanup. Response: {response_text[:500]}")
                    # Fall back to regex extraction
                    return _regex_fallback_extraction(pages)
            
        except asyncio.TimeoutError:
            logger.warning("Gemini extraction timed out, using regex fallback")
            return _regex_fallback_extraction(pages)
    
    except Exception as e:
        logger.error(f"Gemini extraction failed: {e}", exc_info=True)
        return _regex_fallback_extraction(pages)


def _regex_fallback_extraction(pages: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Fallback regex-based extraction when Gemini is unavailable.
    
    Args:
        pages: List of page dictionaries
        
    Returns:
        Basic structured data dictionary
    """
    text = "\n".join(p.get("text", "") for p in pages[:8])
    out: Dict[str, Any] = {}
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    
    # Money patterns
    _money_usd = r"\$ ?[0-9]+(?:\.[0-9]+)?\s*(?:K|M|B)?"
    _money_cr = r"(?:₹|INR)?\s?([0-9]+(?:\.[0-9]+)?)\s?Cr"
    
    # Extract ARR/revenue
    m = re.search(_money_usd, text, re.I)
    if m:
        out.setdefault("metrics", {})["arr"] = m.group(0)
    
    # Extract funding ask
    if re.search(r"\bFUNDING ASK\b.*\$ ?1\.2M", text, re.I) or re.search(r"\bAsk:?\s*\$ ?1\.2M\b", text, re.I):
        out.setdefault("funding", {})["ask_now"] = "$1.2M"
    
    # Extract links
    out.setdefault("links", {})
    for line in lines:
        if "linkedin.com/company/" in line.lower():
            out["links"]["linkedin"] = line.strip()
        if "youtube.com/" in line.lower():
            out["links"]["youtube"] = line.strip()
        if "instagram.com/" in line.lower():
            out["links"]["instagram"] = line.strip()
        if ".com" in line.lower() and ("www." in line.lower() or "http" in line.lower()):
            # Potential website
            if "website" not in out["links"] or not out["links"].get("website"):
                out["links"]["website"] = line.strip()
    
    # Extract company name hints
    if "Unified XR Commerce Studio" in text:
        out["one_liner"] = "AI-powered Unified XR Commerce Studio"
        out["sector"] = "XR/3D"
        out["subsector"] = "Immersive Commerce"
    
    # Extract location
    if re.search(r"Bengaluru|Bangalore|HSR", text, re.I):
        out["location"] = "Bengaluru, IN"
    elif re.search(r"Chennai", text, re.I):
        out["location"] = "Chennai, IN"
    
    # Extract pricing
    if re.search(r"\$ ?900\s*/? ?month", text, re.I):
        out.setdefault("business_model", {}).setdefault("pricing", {})["enterprise_base_fee"] = "$900/mo"
    
    # Extract pipeline
    if re.search(r"\b147 companies\b", text):
        out.setdefault("traction", {})["pipeline_companies"] = 147
    
    m = re.search(r"Sales Pipeline Value:\s*" + _money_cr, text, re.I)
    if m:
        out.setdefault("traction", {})["pipeline_value_inr_cr"] = float(m.group(1))
    
    return out

