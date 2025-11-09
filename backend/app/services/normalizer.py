"""Data normalizer for canonical startup profile schema."""

import re
from typing import Dict, Any, List

CANON_KEYS = {
    # company identity
    "company_name": ["company_name", "startup_name", "name"],
    "website": ["website", "site", "url"],
    "sector": ["sector", "industry"],
    "subsector": ["subsector", "category"],
    "stage": ["stage"],
    "location": ["location", "hq", "city"],
    "one_liner": ["one_liner", "tagline"],
    # market
    "market.tam": ["tam", "total_addressable_market"],
    "market.sam": ["sam"],
    "market.som": ["som"],
    # traction and metrics
    "traction.users": ["users", "students", "learners"],
    "traction.institutions": ["institutions", "colleges"],
    "traction.pilots": ["pilots", "partners"],
    "metrics.arr": ["arr", "revenue_arr"],
    "metrics.growth": ["growth", "growth_rate"],
    "metrics.placements": ["placements"],
    # business model
    "business_model.pricing.learner": ["pricing_learner", "learner_price"],
    "business_model.pricing.enterprise": ["pricing_enterprise", "enterprise_price"],
    "business_model.success_fee": ["success_fee"],
    # funding
    "funding.raised": ["raised", "lifetime_revenue"],
    "funding.ask": ["ask", "seeking"],
    "funding.pipeline": ["pipeline", "committed_revenue"],
    # GTM and moat
    "gtm": ["gtm", "distribution", "go_to_market"],
    "moat": ["moat", "defensibility"],
    "competitors": ["competitors", "incumbents"],
    # links and contacts
    "links.linkedin": ["linkedin"],
    "contacts": ["contacts", "team_contacts"],
    "team": ["team", "founders", "leadership"]
}


def _assign(d: Dict[str, Any], dotted: str, value: Any):
    """Assign a value to a nested dictionary using dotted notation."""
    if value is None:
        return
    parts = dotted.split(".")
    cur = d
    for p in parts[:-1]:
        cur = cur.setdefault(p, {})
    cur[parts[-1]] = value


def normalize_from_questionnaire(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize questionnaire responses to canonical profile structure."""
    out: Dict[str, Any] = {}
    lower = {k.lower(): v for k, v in raw.items()}
    
    for canon, aliases in CANON_KEYS.items():
        for a in aliases:
            if a in raw:
                _assign(out, canon, raw[a])
                break
            if a in lower:
                _assign(out, canon, lower[a])
                break
    
    # common cleanups
    name = (out.get("company_name") or raw.get("company_name") or "").strip()
    if name:
        out["company_name"] = name
    
    return out


def normalize_from_pitch(pages: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Normalize pitch deck pages to canonical profile structure."""
    text = "\n".join(p.get("text", "") for p in pages[:6])  # first few slides
    out: Dict[str, Any] = {}

    # crude extracts with regex; your Gemini pass can enrich further
    m = re.search(r"\$ ?\d+(\.\d+)?\s*(M|B)\b", text, re.I)
    if m:
        _assign(out, "metrics.arr", m.group(0))
    
    if "100+ colleges" in text.lower():
        _assign(out, "traction.institutions", "100+")
    if "8,000" in text or "8000" in text:
        _assign(out, "traction.users", "8000+")
    if "8%" in text:
        _assign(out, "business_model.success_fee", "8%")
    if "AI-powered" in text:
        _assign(out, "one_liner", "AI-powered job simulations")

    # detect linkedin/company name when present
    for line in text.splitlines():
        if "linkedin.com/company/" in line:
            _assign(out, "links.linkedin", line.strip())
            break
    
    return out


def merge_profile(existing: Dict[str, Any], incoming: Dict[str, Any], source: str) -> Dict[str, Any]:
    """Merge incoming profile data into existing profile with precedence.
    
    Precedence: Questionnaire > Checklist > Pitch Deck > Existing
    
    Args:
        existing: Existing profile data
        incoming: New profile data to merge
        source: Source of the incoming data ("questionnaire", "checklist", or "pitch_deck")
        
    Returns:
        Merged profile
    """
    prio = {"questionnaire": 3, "checklist": 2, "pitch_deck": 1}
    
    def _merge(dst, src):
        for k, v in src.items():
            if k.startswith("__src_"):
                continue  # Skip source tracking keys
            if isinstance(v, dict):
                _merge(dst.setdefault(k, {}), v)
            else:
                existing_src = dst.get(f"__src_{k}", "")
                if k not in dst or prio.get(source, 0) >= prio.get(existing_src, 0):
                    dst[k] = v
                    dst[f"__src_{k}"] = source
        return dst
    
    result = {k: v for k, v in (existing or {}).items()}
    return _merge(result, incoming)

