"""Grounded Q&A service - answers questions strictly from startup context."""

import re
import json
from typing import List, Dict, Any, Optional
import google.generativeai as genai

from ..core.config import get_settings
from ..core.logging import get_logger
from ..services.database import get_database_service

logger = get_logger(__name__)
settings = get_settings()


def _json_model():
    """Create a Gemini model configured for JSON output."""
    if not settings.GEMINI_API_KEY:
        return None
    
    genai.configure(api_key=settings.GEMINI_API_KEY)
    return genai.GenerativeModel(
        "gemini-2.5-flash",
        generation_config={
            "temperature": 0.1,
            "max_output_tokens": 2048
        }
    )


def _select_relevant_pages(pages: List[Dict[str, Any]], query: str, k: int) -> List[Dict[str, Any]]:
    """Very light relevance scoring (no external deps)."""
    toks = [t for t in re.findall(r"\w+", query.lower()) if len(t) > 2]
    scored = []
    
    for p in pages:
        txt = (p.get("text") or "").lower()
        score = sum(txt.count(t) for t in toks)
        scored.append((score, p))
    
    scored.sort(key=lambda x: x[0], reverse=True)
    top = [p for s, p in scored[:k] if s > 0]
    return top or [p for _, p in scored[:k]]  # fallback


def _safe_get_pitch(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Tolerate both legacy ('questionnaire_responses.pitch_deck') and new ('pitch_deck' bucket)."""
    qr = (doc.get("questionnaire_responses") or {})
    return doc.get("pitch_deck") or qr.get("pitch_deck") or {}


def _safe_get_checklist(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Tolerate both legacy and new checklist storage."""
    qr = (doc.get("questionnaire_responses") or {})
    return doc.get("checklist") or qr.get("checklist") or {}


def build_context_packets(
    startup_id: str,
    query: str,
    top_k_pages: int = 6,
    use_profile: bool = True,
    use_pitch: bool = True,
    use_checklist: bool = True
) -> List[Dict[str, Any]]:
    """Build context packets from profile, pitch deck, and checklist.
    
    Args:
        startup_id: Startup identifier
        query: User query for relevance scoring
        top_k_pages: Number of most relevant pages to include
        use_profile: Whether to include profile data
        use_pitch: Whether to include pitch deck pages
        use_checklist: Whether to include checklist pages
        
    Returns:
        List of context packets with type, page, and text
    """
    db = get_database_service()
    doc = db.get_startup(startup_id) or {}
    packets: List[Dict[str, Any]] = []
    
    # Add profile (SSoT)
    if use_profile and doc.get("profile"):
        packets.append({
            "type": "profile",
            "payload": doc["profile"]
        })
    
    # Add relevant pitch deck pages
    if use_pitch:
        pitch = _safe_get_pitch(doc)
        pages = pitch.get("pages") or []
        sel = _select_relevant_pages(pages, query, top_k_pages)
        for p in sel:
            packets.append({
                "type": "pitch_deck",
                "page": p.get("page_number"),
                "text": (p.get("text") or "")[:2000]  # cap per pack
            })
    
    # Add relevant checklist pages
    if use_checklist:
        checklist = _safe_get_checklist(doc)
        pages = checklist.get("pages") or []
        sel = _select_relevant_pages(pages, query, top_k_pages)
        for p in sel:
            packets.append({
                "type": "checklist",
                "page": p.get("page_number"),
                "text": (p.get("text") or "")[:2000]
            })
    
    return packets


def answer_with_gemini(query: str, packets: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Answer query using Gemini with provided context packets.
    
    Args:
        query: User question
        packets: Context packets from build_context_packets
        
    Returns:
        Answer with citations, confidence, and missing fields
    """
    if not settings.GEMINI_API_KEY:
        return {
            "answer": "LLM disabled: missing GEMINI_API_KEY",
            "citations": [],
            "confidence": "low",
            "missing": []
        }
    
    model = _json_model()
    if not model:
        return {
            "answer": "LLM model not available",
            "citations": [],
            "confidence": "low",
            "missing": []
        }
    
    # Build a compact, citation-friendly context
    context_lines = []
    for i, p in enumerate(packets, 1):
        if p["type"] == "profile":
            context_lines.append(f"[{i}] source=profile json={json.dumps(p['payload'])[:4000]}")
        else:
            page = p.get("page")
            short = (p.get("text") or "")[:1200]
            context_lines.append(f"[{i}] source={p['type']} page={page}\n{short}")
    
    instruction = """
You are an analyst. Answer the user question using ONLY the provided context packs.

If the answer is not present, say you cannot find it in the provided context.

Return STRICT JSON:

{
  "answer": string,
  "citations": [{"source": "profile|pitch_deck|checklist", "page": int|null, "snippet": string}],
  "confidence": "high|medium|low",
  "missing": [string]   // fields you looked for but did not find
}

Rules:
- Cite the specific pack(s) used. For profile use page=null.
- Do not fabricate numbers or facts not present in the packs.
- If information is missing, list it in the "missing" array.
"""
    
    prompt = f"{instruction}\n\nQUESTION: {query}\n\nCONTEXT:\n" + "\n\n".join(context_lines)
    
    try:
        response = model.generate_content(prompt)
        
        # Parse response
        response_text = None
        try:
            if hasattr(response, 'text'):
                response_text = response.text.strip()
        except (IndexError, AttributeError, KeyError):
            # Try alternative extraction
            if hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and hasattr(candidate.content, 'parts'):
                    parts = candidate.content.parts
                    if parts and len(parts) > 0:
                        if hasattr(parts[0], 'text'):
                            response_text = parts[0].text.strip()
        
        if not response_text:
            return {
                "answer": "Unable to extract response from model",
                "citations": [],
                "confidence": "low",
                "missing": []
            }
        
        # Clean markdown if present
        response_text = re.sub(r'```json\s*', '', response_text)
        response_text = re.sub(r'```\s*$', '', response_text.strip())
        
        # Extract JSON object if embedded
        json_match = re.search(r'\{[\s\S]*\}', response_text)
        if json_match:
            response_text = json_match.group(0)
        
        # Try to parse JSON with multiple fallback strategies
        result = None
        
        def repair_json(txt):
            """Attempt to repair common JSON issues."""
            # Fix trailing commas
            txt = re.sub(r',\s*}', '}', txt)
            txt = re.sub(r',\s*]', ']', txt)
            # Fix missing commas between objects/arrays
            txt = re.sub(r'}\s*{', '},{', txt)
            txt = re.sub(r']\s*\[', '],[', txt)
            # Fix missing commas between fields (common issue)
            # Pattern: "key": value "key" -> "key": value, "key"
            txt = re.sub(r'("\s*:\s*[^,}\]]+)\s*(")', r'\1,\2', txt)
            # Fix missing commas after closing quotes before new keys
            txt = re.sub(r'("\s*)\s*(")', r'\1,\2', txt)
            # Fix unquoted keys (be careful not to break strings)
            txt = re.sub(r'([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:', r'\1"\2":', txt)
            # Fix single quotes to double quotes (but not inside strings)
            # This is tricky, so we'll be conservative
            txt = re.sub(r"'([^']*)':", r'"\1":', txt)
            return txt
        
        parse_attempts = [
            # Attempt 1: Direct parse
            lambda txt: json.loads(txt),
            # Attempt 2: Fix trailing commas
            lambda txt: json.loads(repair_json(txt)),
            # Attempt 3: Fix single quotes (conservative)
            lambda txt: json.loads(txt.replace("'", '"')),
            # Attempt 4: Extract JSON object more carefully
            lambda txt: json.loads(re.search(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', txt, re.DOTALL).group(0) if re.search(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', txt, re.DOTALL) else txt),
            # Attempt 5: More aggressive comma fixing for missing commas
            lambda txt: json.loads(re.sub(r'("\s*:\s*[^,}\]]+)\s*(")', r'\1,\2', repair_json(txt))),
            # Attempt 6: Try using json5-like parsing (handle more lenient JSON)
            lambda txt: json.loads(re.sub(r'(["\d\]}])\s+(["{])', r'\1,\2', repair_json(txt))),
        ]
        
        last_error = None
        for i, parse_func in enumerate(parse_attempts):
            try:
                result = parse_func(response_text)
                if result:
                    logger.debug(f"Successfully parsed JSON on attempt {i+1}")
                    break
            except (json.JSONDecodeError, AttributeError, TypeError) as e:
                last_error = e
                if i == len(parse_attempts) - 1:
                    # Last attempt failed, log the error with more context
                    logger.warning(f"JSON parsing failed after {i+1} attempts. Error: {e}")
                    # Log the problematic section
                    if isinstance(e, json.JSONDecodeError) and hasattr(e, 'pos') and e.pos:
                        start = max(0, e.pos - 100)
                        end = min(len(response_text), e.pos + 100)
                        logger.debug(f"Problem area (char {e.pos}, line {e.lineno if hasattr(e, 'lineno') else '?'}): ...{response_text[start:end]}...")
                        # Also log the full response for debugging
                        logger.debug(f"Full response (first 2000 chars): {response_text[:2000]}")
                    else:
                        logger.debug(f"Response text (first 1000 chars): {response_text[:1000]}")
                continue
        
        if result:
            # Ensure all required fields
            result.setdefault("citations", [])
            result.setdefault("confidence", "medium")
            result.setdefault("missing", [])
            return result
        else:
            # Fallback: try to extract answer manually and return safe structure
            logger.warning("Could not parse JSON, extracting answer manually")
            # Try to find answer field in text
            answer_match = re.search(r'"answer"\s*:\s*"([^"]+)"', response_text)
            if answer_match:
                answer = answer_match.group(1)
            else:
                # Extract first sentence or first 500 chars
                answer = response_text.split('.')[0][:500] if '.' in response_text else response_text[:500]
            
            return {
                "answer": answer,
                "citations": [],
                "confidence": "low",
                "missing": []
            }
    
    except Exception as e:
        logger.error(f"Gemini grounding failed: {e}", exc_info=True)
        return {
            "answer": f"Error generating answer: {str(e)[:200]}",
            "citations": [],
            "confidence": "low",
            "missing": []
        }

