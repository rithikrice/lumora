"""
Startup Management API - CRUD operations for startups
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from datetime import datetime
import re
import google.generativeai as genai
import json

from ..core.security import verify_api_key
from ..core.logging import get_logger, log_api_call
from ..core.config import get_settings
from ..services.database import get_database_service
from ..services.gcs import GCSService

logger = get_logger(__name__)
router = APIRouter()


# ═══════════════════════════════════════════════════════════════════════════
# Request/Response Models
# ═══════════════════════════════════════════════════════════════════════════

class UpdateStartupRequest(BaseModel):
    """Request to update startup information."""
    company_name: Optional[str] = None
    stage: Optional[str] = None
    sector: Optional[str] = None
    arr: Optional[float] = None
    growth_rate: Optional[float] = None
    team_size: Optional[int] = None
    burn_rate: Optional[float] = None
    runway_months: Optional[int] = None
    gross_margin: Optional[float] = None
    # Add any other fields you want to update


class DeleteResponse(BaseModel):
    """Response for delete operation."""
    success: bool
    startup_id: str
    message: str
    deleted_at: str


class UpdateResponse(BaseModel):
    """Response for update operation."""
    success: bool
    startup_id: str
    message: str
    updated_fields: Dict[str, Any]
    updated_at: str


# ═══════════════════════════════════════════════════════════════════════════
# DELETE Endpoint
# ═══════════════════════════════════════════════════════════════════════════

@router.delete("/startups/{startup_id}", response_model=DeleteResponse)
async def delete_startup(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> DeleteResponse:
    """
    Delete a startup and all associated data.
    
    This will remove:
    - Startup record from Firestore
    - All documents (pitch deck, checklist, etc.)
    - Associated files from GCS (if any)
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        DeleteResponse with success status
    """
    log_api_call("/startups/delete", "DELETE", startup_id=startup_id)
    
    try:
        db = get_database_service()
        
        # Check if startup exists
        startup_data = db.get_startup(startup_id)
        if not startup_data:
            raise HTTPException(404, f"Startup {startup_id} not found")
        
        company_name = startup_data.get("questionnaire_responses", {}).get("company_name", startup_id)
        
        # Delete from database (Firestore)
        success = db.delete_startup(startup_id)
        
        if not success:
            raise HTTPException(500, "Failed to delete startup from database")
        
        logger.info(f"✅ Deleted startup: {startup_id} ({company_name})")
        
        return DeleteResponse(
            success=True,
            startup_id=startup_id,
            message=f"Successfully deleted startup '{company_name}' and all associated data",
            deleted_at=datetime.utcnow().isoformat()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting startup {startup_id}: {e}")
        raise HTTPException(500, f"Failed to delete startup: {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# UPDATE Endpoint
# ═══════════════════════════════════════════════════════════════════════════

@router.put("/startups/{startup_id}", response_model=UpdateResponse)
async def update_startup(
    startup_id: str,
    request: UpdateStartupRequest,
    api_key: str = Depends(verify_api_key)
) -> UpdateResponse:
    """
    Update startup information.
    
    Only updates the fields provided in the request.
    All other fields remain unchanged.
    
    Args:
        startup_id: Startup identifier
        request: Fields to update
        api_key: API key for authentication
        
    Returns:
        UpdateResponse with updated fields
    """
    log_api_call("/startups/update", "PUT", startup_id=startup_id)
    
    try:
        db = get_database_service()
        
        # Check if startup exists
        startup_data = db.get_startup(startup_id)
        if not startup_data:
            raise HTTPException(404, f"Startup {startup_id} not found")
        
        # Get existing questionnaire responses
        existing_responses = startup_data.get("questionnaire_responses", {})
        
        # Build update dictionary with only provided fields
        updates = {}
        if request.company_name is not None:
            updates["company_name"] = request.company_name
        if request.stage is not None:
            updates["stage"] = request.stage
        if request.sector is not None:
            updates["sector"] = request.sector
        if request.arr is not None:
            updates["arr"] = request.arr
        if request.growth_rate is not None:
            updates["growth_rate"] = request.growth_rate
        if request.team_size is not None:
            updates["team_size"] = request.team_size
        if request.burn_rate is not None:
            updates["burn_rate"] = request.burn_rate
        if request.runway_months is not None:
            updates["runway"] = request.runway_months
        if request.gross_margin is not None:
            updates["gross_margin"] = request.gross_margin
        
        if not updates:
            raise HTTPException(400, "No fields provided for update")
        
        # Merge updates into existing responses
        existing_responses.update(updates)
        
        # Save updated data
        success = db.save_questionnaire_response(
            startup_id=startup_id,
            responses=existing_responses
        )
        
        if not success:
            raise HTTPException(500, "Failed to update startup in database")
        
        logger.info(f"✅ Updated startup {startup_id}: {list(updates.keys())}")
        
        return UpdateResponse(
            success=True,
            startup_id=startup_id,
            message=f"Successfully updated {len(updates)} field(s)",
            updated_fields=updates,
            updated_at=datetime.utcnow().isoformat()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating startup {startup_id}: {e}")
        raise HTTPException(500, f"Failed to update startup: {str(e)}")


# ═══════════════════════════════════════════════════════════════════════════
# PATCH Endpoint (Partial Update - Alias for PUT)
# ═══════════════════════════════════════════════════════════════════════════

@router.patch("/startups/{startup_id}", response_model=UpdateResponse)
async def patch_startup(
    startup_id: str,
    request: UpdateStartupRequest,
    api_key: str = Depends(verify_api_key)
) -> UpdateResponse:
    """
    Partially update startup information (same as PUT).
    
    This is an alias for PUT /startups/{startup_id}.
    Only updates the fields provided in the request.
    
    Args:
        startup_id: Startup identifier
        request: Fields to update
        api_key: API key for authentication
        
    Returns:
        UpdateResponse with updated fields
    """
    return await update_startup(startup_id, request, api_key)


# ═══════════════════════════════════════════════════════════════════════════
# GET Endpoint (Detailed Startup Info)
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/startups/{startup_id}")
async def get_startup(
    startup_id: str,
    include: str = "light",
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """
    Get startup data with profile (SSoT).
    
    This endpoint serves the profile as the single source of truth.
    All UI components should read from profile for consistency.
    
    Args:
        startup_id: Startup identifier
        include: Response level - "light" (strips heavy blobs) or "full"
        api_key: API key for authentication
        
    Returns:
        Startup data with profile and raw sources
    """
    log_api_call("/startups/get", "GET", startup_id=startup_id)
    
    try:
        db = get_database_service()
        data = db.get_startup(startup_id)
        if not data:
            raise HTTPException(404, "Startup not found")
        
        # Get profile (SSoT)
        profile = data.get("profile", {})
        
        # Get raw sources for reference/debug
        qr = data.get("questionnaire_responses", {})
        if include == "light":
            # strip heavy blobs from raw sources
            for k in ("pitch_deck", "checklist", "investment_memo", "financial_report"):
                if k in qr and isinstance(qr[k], dict):
                    qr[k] = {kk: vv for kk, vv in qr[k].items() if kk not in ("pages", "full_text")}
        
        return {
            "startup_id": startup_id,
            "name": data.get("name"),
            "name_lower": data.get("name_lower"),
            "profile": profile,  # <-- SSoT
            "sources": {
                "pitch_deck": qr.get("pitch_deck"),
                "checklist": qr.get("checklist"),
                "questionnaire": {k: v for k, v in qr.items() if k not in ["pitch_deck", "checklist"]}
            },
            "documents": data.get("documents", [])
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching startup {startup_id}: {e}")
        raise HTTPException(500, f"Failed to fetch startup: {str(e)}")


@router.get("/startups/{startup_id}/details")
async def get_startup_details(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """
    Get complete startup details including all uploaded documents.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Complete startup data
    """
    log_api_call("/startups/details", "GET", startup_id=startup_id)
    
    try:
        db = get_database_service()
        
        startup_data = db.get_startup(startup_id)
        if not startup_data:
            raise HTTPException(404, f"Startup {startup_id} not found")
        
        responses = startup_data.get("questionnaire_responses", {})
        profile = startup_data.get("profile", {})
        metrics = profile.get("metrics", {})
        latest_analysis = startup_data.get("latest_analysis") or {}
        pitch_deck = responses.get("pitch_deck") or {}
        checklist = responses.get("checklist") or {}

        def _extract_founders_from_pitch(pitch: Dict[str, Any]) -> List[str]:
            names: List[str] = []
            pages = pitch.get("pages") or []
            for p in pages:
                text = p.get("text", "")
                for m in re.finditer(r"([A-Z][a-z]+(?: [A-Z][a-z]+)+)\s+Co-founder", text):
                    names.append(m.group(1).strip())
            # de-dup while preserving order
            seen = set()
            dedup: List[str] = []
            for n in names:
                if n not in seen:
                    dedup.append(n)
                    seen.add(n)
            return dedup

        def _collect_key_metrics_from_pitch(pitch: Dict[str, Any]) -> List[str]:
            out: List[str] = []
            for p in pitch.get("pages") or []:
                for k in p.get("key_metrics", []) or []:
                    out.append(str(k))
            # de-dup
            seen = set()
            dedup: List[str] = []
            for k in out:
                if k not in seen:
                    dedup.append(k)
                    seen.add(k)
            return dedup

        def _extract_business_context(
            checklist_struct: Dict, pitch_struct: Dict, 
            checklist_text: str, pitch_text: str, 
            config
        ) -> Dict[str, str]:
            """Extract comprehensive business context using Gemini when structured data is incomplete."""
            
            # Try structured data first
            business = {
                "problem": checklist_struct.get("problem") or pitch_struct.get("problem"),
                "solution": checklist_struct.get("solution") or pitch_struct.get("solution"),
                "business_model": checklist_struct.get("business_model") or pitch_struct.get("business_model"),
                "target_audience": checklist_struct.get("target_audience") or pitch_struct.get("target_audience"),
                "competitive_advantage": checklist_struct.get("competitive_advantage") or pitch_struct.get("competitive_advantage"),
                "tech_stack": checklist_struct.get("tech_stack") or pitch_struct.get("tech_stack"),
                "pricing": checklist_struct.get("pricing") or pitch_struct.get("pricing")
            }
            
            # If most fields are empty, use Gemini to extract all at once
            empty_count = sum(1 for v in business.values() if not v)
            if empty_count >= 4 and config.GEMINI_API_KEY:
                try:
                    genai.configure(api_key=config.GEMINI_API_KEY)
                    model = genai.GenerativeModel('gemini-2.5-pro')  # Using latest stable Gemini 2.5 Pro with adaptive thinking
                    
                    combined_text = f"{checklist_text[:3000]}\n\n{pitch_text[:3000]}"
                    business_prompt = f"""Extract the following business information from this startup's documents. Return as JSON only.

{{
  "problem": "What problem is the startup solving?",
  "solution": "What is their solution/product?",
  "business_model": "How do they make money?",
  "target_audience": "Who are their target customers?",
  "competitive_advantage": "What makes them unique?",
  "tech_stack": "What technologies do they use?",
  "pricing": "What is their pricing model?"
}}

Documents:
{combined_text}

Return ONLY the JSON object:"""
                    
                    response = model.generate_content(business_prompt)
                    result_text = response.text.strip()
                    
                    # Clean markdown if present
                    if result_text.startswith("```"):
                        result_text = result_text.split("```")[1].replace("json", "").strip()
                    
                    extracted = json.loads(result_text)
                    
                    # Merge with existing data (prefer extracted if existing is None)
                    for key in business.keys():
                        if not business[key] and extracted.get(key):
                            business[key] = extracted[key]
                
                except Exception as e:
                    logger.debug(f"Gemini business extraction failed: {e}")
            
            # Ensure no None values
            for key in business.keys():
                if not business[key]:
                    business[key] = "TBD"
            
            return business
        
        def _parse_fundraising_field(fundraising_highlights: List[str], field_type: str) -> Optional[str]:
            """Parse specific fundraising field from highlights text."""
            combined_text = " ".join(fundraising_highlights)
            
            if field_type == "ask":
                # Look for "seeking ₹X crores" or "FUNDING NEEDED"
                match = re.search(r"seeking\s+([₹$\d.,]+\s*(?:crores?|Cr|million|M|lakh|L))", combined_text, re.IGNORECASE)
                if match:
                    return match.group(1).strip()
            
            elif field_type == "raised":
                # Look for "raise of INR X" or "Pre-seed raise"
                match = re.search(r"raise\s+of\s+(?:INR|₹)\s*([\d.,]+\s*(?:Cr|crores?|lakh|L))", combined_text, re.IGNORECASE)
                if match:
                    return f"₹{match.group(1).strip()}"
            
            elif field_type == "valuation":
                # Look for "at X (pre-money) valuation"
                match = re.search(r"at\s+([\d.,]+\s*(?:Cr|crores?))\s*\(pre-money\)", combined_text, re.IGNORECASE)
                if match:
                    return f"₹{match.group(1).strip()} pre-money"
            
            return None
        
        def _extract_website(profile_links: Dict[str, Any], pitch_full_text: str, fundraising_highlights: List[str]) -> Optional[str]:
            site = (profile_links or {}).get("website")
            if isinstance(site, str):
                m = re.search(r"https?://\S+|www\.[^\s]+", site)
                if m:
                    return m.group(0)
            
            # Try to find company website (not research/external links)
            if isinstance(pitch_full_text, str):
                # Look for www.companyname.com patterns, avoiding research links
                urls = re.findall(r"(?:https?://)?(?:www\.)?([a-zA-Z0-9-]+\.com)(?:/|\s|$)", pitch_full_text)
                for url in urls:
                    # Skip common external domains
                    if not any(ext in url.lower() for ext in ["google", "research", "linkedin", "twitter", "facebook", "instagram"]):
                        return f"https://www.{url}" if not url.startswith("http") else url
            
            # Try fundraising highlights (often has contact info)
            for highlight in fundraising_highlights:
                urls = re.findall(r"(?:www\.)([a-zA-Z0-9-]+\.com)", highlight)
                for url in urls:
                    if not any(ext in url.lower() for ext in ["google", "research", "linkedin"]):
                        return f"https://www.{url}"
            
            return None

        # Extract structured data if available from pitch_deck/checklist
        pitch_structured = pitch_deck.get("structured_profile", {}) if isinstance(pitch_deck, dict) else {}
        checklist_structured = checklist.get("structured_profile", {}) if isinstance(checklist, dict) else {}
        
        # Get settings
        settings = get_settings()
        
        # Helper: Generate real AI analysis from pitch/checklist data
        def _generate_analysis_from_data(
            pitch: Dict, checklist: Dict, pitch_struct: Dict, checklist_struct: Dict,
            available_data: Dict, founder_list: List, startup_id: str
        ) -> Dict[str, Any]:
            """Generate real analysis from pitch/checklist data, no mocking."""
            try:
                # Extract real KPIs from all sources
                kpis = {}
                
                # Financial KPIs
                if available_data.get("arr"):
                    kpis["arr"] = available_data["arr"]
                if available_data.get("growth_rate"):
                    kpis["growth_rate"] = available_data["growth_rate"]
                if available_data.get("gross_margin"):
                    kpis["gross_margin"] = available_data["gross_margin"]
                if available_data.get("burn_rate"):
                    kpis["burn_rate"] = available_data["burn_rate"]
                if available_data.get("runway_months"):
                    kpis["runway_months"] = available_data["runway_months"]
                
                # Unit economics
                if available_data.get("cac"):
                    kpis["cac"] = available_data["cac"]
                if available_data.get("ltv"):
                    kpis["ltv"] = available_data["ltv"]
                if available_data.get("cac_ltv_ratio"):
                    kpis["cac_ltv_ratio"] = available_data["cac_ltv_ratio"]
                
                # Extract additional metrics from traction highlights
                highlights = available_data.get("traction_highlights", [])
                for h in highlights:
                    if isinstance(h, str):
                        # Extract AUM
                        if "aum" in h.lower() and "aum" not in kpis:
                            aum_match = re.search(r"AUM[:\s]+([₹$\d.,]+\s*(?:Cr|M|L|lakh|crore|million)?)", h, re.IGNORECASE)
                            if aum_match:
                                kpis["aum"] = aum_match.group(1).strip()
                        
                        # Extract users
                        if "users" in h.lower() and "users" not in kpis:
                            users_match = re.search(r"(\d+(?:,\d+)*)\s*(?:users|customers)", h, re.IGNORECASE)
                            if users_match:
                                kpis["users"] = users_match.group(1).strip()
                        
                        # Extract MRR
                        if "mrr" in h.lower() and "mrr" not in kpis:
                            mrr_match = re.search(r"MRR[:\s]+([₹$\d.,]+\s*[kKmM]?)", h, re.IGNORECASE)
                            if mrr_match:
                                kpis["mrr"] = mrr_match.group(1).strip()
                
                # Extract risks from checklist text with Gemini for complete analysis
                risks = []
                checklist_text = checklist.get("full_text", "")
                if "risk" in checklist_text.lower() and settings.GEMINI_API_KEY:
                    try:
                        genai.configure(api_key=settings.GEMINI_API_KEY)
                        model = genai.GenerativeModel('gemini-2.5-pro')  # Using latest stable Gemini 2.5 Pro with adaptive thinking
                        risk_prompt = f"""Extract all risks and their mitigations from this startup checklist.
Return as JSON array with format: {{"type": "risk type", "severity": "high/medium/low", "description": "full description", "mitigation": "mitigation strategy"}}

Checklist excerpt:
{checklist_text[checklist_text.lower().find('risk'):checklist_text.lower().find('risk')+3000]}

Return ONLY valid JSON array, no markdown:"""
                        response = model.generate_content(risk_prompt)
                        risks_text = response.text.strip()
                        if risks_text.startswith("```"):
                            risks_text = risks_text.split("```")[1].replace("json", "").strip()
                        risks = json.loads(risks_text)[:5]  # Top 5 risks
                    except Exception as e:
                        logger.debug(f"Gemini risk extraction failed: {e}")
                        # Fallback to regex
                        risk_section = re.search(r"(risks?.*?mitigation.*?)(?=\n\n[A-Z]|\Z)", checklist_text, re.IGNORECASE | re.DOTALL)
                        if risk_section:
                            risk_text = risk_section.group(1)
                            risk_items = re.findall(r"(?:^|\n)([A-Z][^:\n]+:.*?)(?=\n[A-Z]|\Z)", risk_text, re.DOTALL)
                            for item in risk_items[:3]:
                                risk_type = item.split(":")[0].strip()
                                risks.append({
                                    "type": risk_type,
                                    "severity": "medium",
                                    "description": item.strip()[:200]
                                })
                
                # Generate comprehensive executive summary with Gemini
                problem = checklist_struct.get("problem") or pitch_struct.get("problem") or ""
                solution = checklist_struct.get("solution") or pitch_struct.get("solution") or ""
                
                exec_summary = ""
                if settings.GEMINI_API_KEY:
                    try:
                        genai.configure(api_key=settings.GEMINI_API_KEY)
                        model = genai.GenerativeModel('gemini-2.5-pro')  # Using latest stable Gemini 2.5 Pro with adaptive thinking
                        full_context = f"Pitch Deck:\n{pitch.get('full_text', '')[:2000]}\n\nChecklist:\n{checklist_text[:2000]}"
                        summary_prompt = f"""Write a concise 2-3 paragraph executive summary for this startup covering:
1. Problem they're solving and target market
2. Their solution and business model
3. Key traction metrics and competitive advantage

Context:
{full_context}

Executive Summary:"""
                        response = model.generate_content(summary_prompt)
                        exec_summary = response.text.strip()
                    except Exception as e:
                        logger.debug(f"Gemini summary generation failed: {e}")
                        exec_summary = f"{problem[:200]}... {solution[:200]}..." if problem and solution else ""
                
                if not exec_summary and checklist_text:
                    paragraphs = [p.strip() for p in checklist_text.split("\n\n") if len(p.strip()) > 100]
                    exec_summary = paragraphs[0][:400] + "..." if paragraphs else ""
                
                # Calculate recommendation based on KPIs
                score = 70  # Base score
                recommendation = "FOLLOW"
                
                # Adjust based on available metrics
                if kpis.get("arr"):
                    score += 5
                if kpis.get("growth_rate"):
                    score += 5
                if kpis.get("cac_ltv_ratio"):
                    ratio_match = re.search(r"(\d+(?:\.\d+)?)", str(kpis["cac_ltv_ratio"]))
                    if ratio_match and float(ratio_match.group(1)) > 3:
                        score += 10
                        recommendation = "INVEST"
                
                if founder_list and len(founder_list) > 1:
                    score += 5
                
                return {
                    "executive_summary": exec_summary or "Analysis based on pitch deck and checklist data.",
                    "kpis": kpis,
                    "risks": risks or [{"type": "General", "severity": "low", "description": "Standard early-stage risks apply"}],
                    "recommendation": recommendation,
                    "score": min(score, 95),  # Cap at 95
                    "generated_from": "pitch_deck_and_checklist",
                    "timestamp": datetime.utcnow().isoformat()
                }
            except Exception as e:
                logger.error(f"Failed to generate analysis from data: {e}")
                return {
                    "executive_summary": "Unable to generate analysis. Please upload pitch deck and checklist.",
                    "kpis": {},
                    "risks": [],
                    "recommendation": "INSUFFICIENT_DATA",
                    "score": None,
                    "error": str(e)
                }
        
        # Helper: Use Gemini to extract missing structured fields from full_text
        def _extract_missing_with_gemini(field_name: str, context_text: str, field_description: str) -> Optional[str]:
            """Extract a specific field from text using Gemini when it's missing."""
            if not context_text or not settings.GEMINI_API_KEY:
                return None
            try:
                genai.configure(api_key=settings.GEMINI_API_KEY)
                model = genai.GenerativeModel('gemini-2.5-pro')  # Using latest stable Gemini 2.5 Pro with adaptive thinking
                prompt = f"""Extract the {field_description} from this startup document.
Return ONLY the extracted value, nothing else. If not found, return 'NOT_FOUND'.

Document excerpt:
{context_text[:3000]}

Extract {field_name}:"""
                response = model.generate_content(prompt)
                result = response.text.strip()
                return None if result == "NOT_FOUND" else result
            except Exception as e:
                logger.debug(f"Gemini extraction failed for {field_name}: {e}")
                return None
        
        # Helper: Calculate derived metrics using mathematical formulas
        def _calculate_metric(metric_name: str, available_data: Dict[str, Any]) -> Optional[Any]:
            """Calculate a metric from other available metrics."""
            try:
                if metric_name == "runway_months":
                    burn = available_data.get("burn_rate")
                    cash = available_data.get("cash_available") or available_data.get("raised_to_date")
                    if burn and cash:
                        # Parse numeric values
                        burn_val = float(re.sub(r'[^0-9.]', '', str(burn)))
                        cash_val = float(re.sub(r'[^0-9.]', '', str(cash)))
                        if burn_val > 0:
                            return int(cash_val / burn_val)
                
                elif metric_name == "gross_margin":
                    revenue = available_data.get("arr") or available_data.get("revenue")
                    costs = available_data.get("costs") or available_data.get("burn_rate")
                    if revenue and costs:
                        rev_val = float(re.sub(r'[^0-9.]', '', str(revenue)))
                        cost_val = float(re.sub(r'[^0-9.]', '', str(costs)))
                        if rev_val > 0:
                            return f"{int(((rev_val - cost_val) / rev_val) * 100)}%"
                
                elif metric_name == "growth_rate":
                    # Try to extract from traction highlights
                    highlights = available_data.get("traction_highlights", [])
                    for h in highlights:
                        if isinstance(h, str) and "%" in h and any(word in h.lower() for word in ["growth", "yoy", "increase"]):
                            match = re.search(r'(\d+)%', h)
                            if match:
                                return f"{match.group(1)}% YoY"
                
                elif metric_name == "cac_ltv_ratio":
                    cac = available_data.get("cac")
                    ltv = available_data.get("ltv")
                    if cac and ltv:
                        cac_val = float(re.sub(r'[^0-9.]', '', str(cac)))
                        ltv_val = float(re.sub(r'[^0-9.]', '', str(ltv)))
                        if cac_val > 0:
                            ratio = ltv_val / cac_val
                            return f"{ratio:.1f}:1"
                
                return None
            except Exception as e:
                logger.debug(f"Calculation failed for {metric_name}: {e}")
                return None
        
        # Format response - prioritize profile (SSoT) over raw responses
        pitch_metrics = _collect_key_metrics_from_pitch(pitch_deck)
        
        # Pre-extract fundraising highlights for website detection
        fundraising_pages = [p.get("text", "") for p in (pitch_deck.get("pages") or []) if "FUNDING" in p.get("text", "").upper() or "THANK YOU" in p.get("text", "").upper()]
        
        # Extract founders: try profile.team -> structured -> pitch deck extraction -> Gemini
        founders = (
            profile.get("team") or 
            checklist_structured.get("team") or 
            pitch_structured.get("team") or 
            _extract_founders_from_pitch(pitch_deck)
        )
        
        # If still no founders, use Gemini to extract
        if not founders or len(founders) == 0:
            full_text_combined = (pitch_deck.get("full_text") or "") + "\n\n" + (checklist.get("full_text") or "")
            if full_text_combined.strip():
                founders_extracted = _extract_missing_with_gemini(
                    "founders",
                    full_text_combined,
                    "founder names (comma-separated list of full names only)"
                )
                if founders_extracted and founders_extracted != "TBD":
                    founders = [name.strip() for name in founders_extracted.split(",")]
        
        # Ensure founders is always a list with at least placeholder
        if not founders or len(founders) == 0:
            founders = ["Team information not disclosed"]
        
        # Get AI KPIs for fallback
        ai_kpis = (latest_analysis.get("kpis") or {}) if isinstance(latest_analysis, dict) else {}
        
        # Collect all available data for calculations
        all_available_data = {
            **metrics,
            **checklist_structured.get("metrics", {}),
            **pitch_structured.get("metrics", {}),
            **ai_kpis,
            **responses,
            "traction_highlights": pitch_metrics,
            "raised_to_date": checklist_structured.get("fundraising", {}).get("raised_to_date")
        }
        
        # Helper to get metric with intelligent fallback: never returns None
        def get_metric_safe(metric_key, ai_key=None, q_key=None):
            # 1. Try profile SSoT
            val = metrics.get(metric_key)
            if val is not None:
                return val
            
            # 2. Try structured extractions
            if checklist_structured.get("metrics", {}).get(metric_key):
                return checklist_structured["metrics"][metric_key]
            if pitch_structured.get("metrics", {}).get(metric_key):
                return pitch_structured["metrics"][metric_key]
            
            # 3. Try AI analysis
            if ai_key and ai_kpis.get(ai_key) is not None:
                return ai_kpis.get(ai_key)
            
            # 4. Try questionnaire
            if q_key and responses.get(q_key) is not None:
                return responses.get(q_key)
            
            # 5. Try mathematical derivation
            calculated = _calculate_metric(metric_key, all_available_data)
            if calculated is not None:
                return calculated
            
            # 6. Try Gemini extraction from full text
            full_text = (pitch_deck.get("full_text") or "") + "\\n\\n" + (checklist.get("full_text") or "")
            if full_text.strip():
                extracted = _extract_missing_with_gemini(
                    metric_key,
                    full_text,
                    f"numerical value for {metric_key} (e.g., revenue, growth rate, burn rate)"
                )
                if extracted:
                    return extracted
            
            # 7. Return descriptive placeholder instead of None
            return f"Not disclosed" if metric_key in ["cac", "ltv", "churn"] else "TBD"
        # Helper: Get field with Gemini fallback
        full_text = (pitch_deck.get("full_text") or "") + "\n\n" + (checklist.get("full_text") or "")
        
        def get_field_safe(field_name: str, *sources, description: str = None) -> str:
            """Get a field from sources or extract with Gemini, never return None."""
            for src in sources:
                if src:
                    return src
            
            # Special handling for company name - never use filename
            if field_name == "company_name":
                # Try to extract from pitch deck title page or checklist
                pitch_text = pitch_deck.get("full_text", "")
                if pitch_text:
                    # Look for company name in first 500 chars
                    first_page = pitch_text[:500]
                    # Remove common pitch deck words
                    cleaned = re.sub(r"(?i)(pitch|deck|presentation|sep|2025|pdf|.pdf)", "", first_page)
                    lines = [l.strip() for l in cleaned.split("\n") if l.strip() and len(l.strip()) > 3]
                    if lines:
                        # First substantial line is usually company name
                        for line in lines:
                            if len(line) < 30 and not any(x in line.lower() for x in ["page", "slide", "welcome"]):
                                return line
            
            # Try Gemini extraction
            if full_text.strip() and description and settings.GEMINI_API_KEY:
                extracted = _extract_missing_with_gemini(field_name, full_text, description)
                if extracted:
                    return extracted
            return "Stealth" if field_name in ["stage", "sector"] else "TBD"
        
        # Build identity with smart fallbacks
        ui_response = {
            "identity": {
                "startup_id": startup_id,
                "name": startup_data.get("name"),
                "company_name": get_field_safe(
                    "company_name",
                    profile.get("company_name"),
                    checklist_structured.get("company_name"),
                    pitch_structured.get("company_name"),
                    responses.get("company_name"),
                    startup_id,
                    description="company name"
                ),
                "stage": get_field_safe(
                    "stage",
                    profile.get("stage"),
                    checklist_structured.get("stage"),
                    pitch_structured.get("stage"),
                    description="funding stage (e.g., Seed, Series A, Pre-seed)"
                ),
                "sector": get_field_safe(
                    "sector",
                    profile.get("sector"),
                    checklist_structured.get("sector"),
                    pitch_structured.get("sector"),
                    description="industry or sector (e.g., Fintech, SaaS, E-commerce)"
                ),
                "location": get_field_safe(
                    "location",
                    profile.get("location"),
                    checklist_structured.get("location"),
                    pitch_structured.get("location"),
                    description="company headquarters location (city, country)"
                ),
                "founded_year": get_field_safe(
                    "founded_year",
                    profile.get("founded_year"),
                    checklist_structured.get("founded_year"),
                    pitch_structured.get("founded_year"),
                    description="year the company was founded (YYYY format)"
                ),
                "website": get_field_safe(
                    "website",
                    _extract_website((profile.get("links") or {}), (pitch_deck.get("full_text") or ""), fundraising_pages),
                    checklist_structured.get("links", {}).get("website"),
                    pitch_structured.get("links", {}).get("website"),
                    description="company website URL"
                )
            },
            "founders": founders,  # Always has value due to fallback logic above
            "metrics": {
                "arr": get_metric_safe("arr", "arr", "arr"),
                "growth_rate": get_metric_safe("growth", "growth_rate", "growth_rate"),
                "gross_margin": get_metric_safe("gross_margin", "gross_margin", "gross_margin"),
                "burn_rate": get_metric_safe("burn_rate", "burn_rate", "burn_rate"),
                "runway_months": get_metric_safe("runway_months", "runway_months", "runway"),
                "cac": get_metric_safe("cac", None, "cac"),
                "ltv": get_metric_safe("ltv", None, "ltv"),
                "cac_ltv_ratio": get_metric_safe("cac_ltv_ratio", "cac_ltv_ratio", None)
            },
            "market": {
                "highlights": [m for m in pitch_metrics if any(x in m.lower() for x in ["tam", "sam", "som", "cagr", "market"])] or ["Market analysis available in pitch deck"]
            },
            "traction": {
                "highlights": [m for m in pitch_metrics if any(x in m.lower() for x in ["users", "aum", "%", "acquired", "transactions", "revenue"])] or ["Traction metrics available in pitch deck"],
            },
            "gtm": {
                "highlights": [p.get("text", "") for p in (pitch_deck.get("pages") or []) if "GO TO MARKET" in p.get("text", "").upper()] or ["Go-to-market strategy available in pitch deck"]
            },
            "fundraising": {
                "highlights": fundraising_pages or ["Fundraising details available in pitch deck"],
                "ask": get_field_safe(
                    "fundraising_ask",
                    checklist_structured.get("fundraising", {}).get("ask"),
                    pitch_structured.get("fundraising", {}).get("ask"),
                    _parse_fundraising_field(fundraising_pages, "ask"),
                    description="amount of funding being raised (e.g., $2M, ₹5 Cr)"
                ),
                "raised_to_date": get_field_safe(
                    "raised_to_date",
                    checklist_structured.get("fundraising", {}).get("raised_to_date"),
                    pitch_structured.get("fundraising", {}).get("raised_to_date"),
                    _parse_fundraising_field(fundraising_pages, "raised"),
                    description="total funding raised to date (e.g., $1.5M, ₹1.2 Cr)"
                ),
                "valuation": get_field_safe(
                    "valuation",
                    checklist_structured.get("fundraising", {}).get("valuation"),
                    pitch_structured.get("fundraising", {}).get("valuation"),
                    _parse_fundraising_field(fundraising_pages, "valuation"),
                    description="current company valuation (pre-money or post-money)"
                )
            },
            "business": _extract_business_context(
                checklist_structured, pitch_structured, 
                checklist.get("full_text", ""), pitch_deck.get("full_text", ""), 
                settings
            ),
            "documents": [
                {
                    "type": doc.get("type"),
                    "filename": doc.get("filename"),
                    "document_id": doc.get("document_id"),
                    "pages": doc.get("pages"),
                    "uploaded_at": doc.get("uploaded_at")
                }
                for doc in startup_data.get("documents", [])
            ],
            "sources": {
                "pitch_deck": {
                    "document_id": pitch_deck.get("document_id"),
                    "filename": pitch_deck.get("filename"),
                    "total_pages": pitch_deck.get("total_pages"),
                    "public_url": pitch_deck.get("public_url")
                } if pitch_deck.get("document_id") else None,
                "checklist": {
                    "document_id": checklist.get("document_id"),
                    "filename": checklist.get("filename"),
                    "total_pages": checklist.get("total_pages"),
                    "public_url": checklist.get("public_url")
                } if checklist.get("document_id") else None
            },
            "ai_analysis": latest_analysis or _generate_analysis_from_data(
                pitch_deck, checklist, pitch_structured, checklist_structured, 
                all_available_data, founders, startup_id
            )
        }

        # Return ONLY UI-ready data - no verbose pitch/checklist pages
        return ui_response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching startup details for {startup_id}: {e}")
        raise HTTPException(500, f"Failed to fetch startup details: {str(e)}")

