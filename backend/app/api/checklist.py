"""Founders Checklist Upload API - Extract structured startup data.

Extracts comprehensive startup information from founders checklists.
"""

import io
from typing import Dict, Any, Optional, List
from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from pydantic import BaseModel
import google.generativeai as genai

from ..core.security import verify_api_key
from ..core.logging import get_logger
from ..core.config import get_settings
from ..services.database import get_database_service
from ..services.gcs import GCSService

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


class ChecklistUploadResponse(BaseModel):
    """Response from checklist upload."""
    success: bool
    startup_id: str
    document_id: str
    extracted_data: Dict[str, Any]
    company_name: Optional[str] = None


@router.post("/checklist/upload")
async def upload_founders_checklist(
    startup_id: str = Form(...),
    file: UploadFile = File(...),
    api_key: str = Depends(verify_api_key)
) -> ChecklistUploadResponse:
    """Upload and extract structured data from founders checklist.
    
    Extracts:
    - Company name, stage, sector
    - Team size, founders info
    - Revenue, ARR, MRR
    - Growth rates, metrics
    - Customer count, traction
    - Funding details
    - Problem, solution, market size
    
    Args:
        startup_id: Startup identifier
        file: Checklist file (PDF or DOCX)
        api_key: API key
        
    Returns:
        Upload response with extracted structured data
    """
    logger.info(f"Uploading founders checklist for {startup_id}: {file.filename}")
    
    try:
        # Validate file type
        filename_lower = file.filename.lower()
        if not (filename_lower.endswith('.pdf') or filename_lower.endswith('.docx')):
            raise HTTPException(400, "Only PDF and DOCX files are supported")
        
        # Read content
        content = await file.read()
        size_mb = len(content) / (1024 * 1024)
        
        if size_mb > 20:  # 20MB limit for checklists
            raise HTTPException(400, "Checklist must be under 20MB")
        
        logger.info(f"Processing {size_mb:.1f}MB checklist: {file.filename}")
        
        # Extract pages from document (similar to pitch_deck)
        pages_data = await _extract_pages_from_document(content, filename_lower)
        
        # Upload to GCS
        gcs_service = GCSService()
        storage_path, public_url = await gcs_service.upload_file(
            content=content,
            filename=file.filename,
            startup_id=startup_id
        )
        
        # Generate document ID
        import hashlib
        document_id = f"checklist-{startup_id}-{hashlib.md5(content).hexdigest()[:8]}"
        
        # Store in database
        db = get_database_service()
        
        # Get existing data to merge with
        startup_data = db.get_startup(startup_id)
        existing_responses = {}
        if startup_data:
            existing_responses = startup_data.get("questionnaire_responses", {})
        
        # Create checklist record (keep raw data for reference)
        full_text = "\n\n".join([p.get("text", "") for p in pages_data])
        checklist_record = {
            "document_id": document_id,
            "filename": file.filename,
            "storage_path": storage_path,
            "public_url": public_url,
            "full_text": full_text,
            "pages": [p for p in pages_data],
            "total_pages": len(pages_data)
        }
        existing_responses["checklist"] = checklist_record
        
        # Save raw checklist data
        db.save_questionnaire_response(
            startup_id=startup_id,
            responses=existing_responses
        )
        
        # Extract structured profile using unified extractor (LLM + regex fallback)
        from ..services.extractors import extract_structured_profile
        structured = await extract_structured_profile(
            pages=[p for p in pages_data],
            api_key=settings.GEMINI_API_KEY,
            pdf_bytes=content,
            doc_type="checklist"
        )
        
        # Write-through to profile (SSoT)
        profile = db.save_structured_profile(startup_id, structured, source="checklist")
        
        # Keep an index of documents (lightweight)
        doc_index = {
            "document_id": document_id,
            "type": "checklist",
            "filename": file.filename,
            "public_url": public_url,
            "pages": len(pages_data)
        }
        db.add_document_index(startup_id, doc_index)
        
        logger.info(f"Checklist processed: {document_id} for {structured.get('company_name', startup_id)}")
        
        # Use structured data for response
        structured_data = structured
        
        return ChecklistUploadResponse(
            success=True,
            startup_id=startup_id,
            document_id=document_id,
            extracted_data=structured_data,
            company_name=structured_data.get("company_name")
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Checklist upload error: {e}", exc_info=True)
        raise HTTPException(500, f"Upload failed: {str(e)}")


async def _extract_pages_from_document(content: bytes, filename_lower: str) -> List[Dict[str, Any]]:
    """Extract pages from PDF or DOCX as structured page data.
    
    Args:
        content: Document bytes
        filename_lower: Lowercase filename
        
    Returns:
        List of page dictionaries with 'text' and 'page_number'
    """
    pages_data = []
    
    if filename_lower.endswith('.pdf'):
        import fitz  # PyMuPDF
        pdf = fitz.open(stream=content, filetype="pdf")
        for page_num, page in enumerate(pdf, 1):
            text = page.get_text()
            pages_data.append({
                "page_number": page_num,
                "text": text,
                "has_chart": False,  # Can be enhanced with vision analysis
                "has_diagram": False
            })
        pdf.close()
    
    elif filename_lower.endswith('.docx'):
        from docx import Document
        doc = Document(io.BytesIO(content))
        # Split into logical sections (by headings or every ~500 words)
        sections = []
        current_section = []
        word_count = 0
        
        for para in doc.paragraphs:
            if not para.text.strip():
                continue
            
            is_heading = para.style.name.startswith('Heading') if para.style else False
            
            if is_heading and current_section:
                sections.append("\n".join(current_section))
                current_section = []
                word_count = 0
            
            current_section.append(para.text)
            word_count += len(para.text.split())
            
            if word_count > 500:
                sections.append("\n".join(current_section))
                current_section = []
                word_count = 0
        
        if current_section:
            sections.append("\n".join(current_section))
        
        # Create page-like structures from sections
        for idx, section_text in enumerate(sections, 1):
            pages_data.append({
                "page_number": idx,
                "text": section_text,
                "has_chart": False,
                "has_diagram": False
            })
    
    else:
        raise ValueError(f"Unsupported file type: {filename_lower}")
    
    return pages_data


async def _extract_structured_data_with_gemini(text: str, startup_id: str) -> Dict[str, Any]:
    """Extract structured startup data from checklist text using Gemini.
    
    Args:
        text: Checklist text
        startup_id: Startup ID
        
    Returns:
        Structured data dictionary
    """
    if not settings.GEMINI_API_KEY:
        logger.warning("No Gemini API key, returning basic data")
        return {"company_name": startup_id, "raw_text": text[:1000]}
    
    # Check if API key looks like OpenAI key
    if settings.GEMINI_API_KEY.startswith('sk-'):
        logger.error("Invalid Gemini API key format (looks like OpenAI key)")
        return {"company_name": startup_id, "error": "Invalid API key format"}
    
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        
        # Use Gemini 2.5 Pro for structured extraction
        model = genai.GenerativeModel("gemini-2.5-pro")
        
        prompt = f"""Extract structured startup data from this founders checklist.

Checklist content:
{text[:15000]}  # Limit to ~15K chars for context

Extract and return JSON with these fields (use null if not found):
{{
  "company_name": "Company name",
  "stage": "Pre-seed/Seed/Series A/etc",
  "sector": "Industry/sector",
  "founded_year": 2024,
  "team_size": 10,
  "founders": ["Founder 1", "Founder 2"],
  "problem": "Problem being solved",
  "solution": "Solution description",
  "market_size": "TAM/SAM/SOM",
  "business_model": "Revenue model",
  "revenue_current": "Current revenue",
  "arr": 1000000,
  "mrr": 83333,
  "growth_rate": 200,
  "customer_count": 500,
  "key_customers": ["Customer 1", "Customer 2"],
  "funding_raised": 500000,
  "funding_round": "Seed",
  "investors": ["Investor 1"],
  "burn_rate": 50000,
  "runway_months": 12,
  "target_raise": 1000000,
  "valuation": 5000000,
  "use_of_funds": "Product development, hiring",
  "key_metrics": {{
    "metric1": "value1",
    "metric2": "value2"
  }},
  "traction": "Key traction points",
  "competition": "Main competitors",
  "moat": "Competitive advantage",
  "vision": "Long-term vision"
}}

Return ONLY valid JSON, no markdown formatting."""
        
        # Add timeout to prevent hanging
        import asyncio
        import json
        import re
        
        try:
            response = await asyncio.wait_for(
                asyncio.to_thread(model.generate_content, prompt),
                timeout=30.0
            )
            response_text = response.text.strip()
            
            # Extract JSON from markdown if present
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                structured_data = json.loads(json_match.group())
            else:
                structured_data = json.loads(response_text)
            
            logger.info(f"Extracted structured data for: {structured_data.get('company_name', startup_id)}")
            return structured_data
            
        except asyncio.TimeoutError:
            logger.warning("Gemini extraction timed out")
            return {"company_name": startup_id, "error": "Extraction timed out"}
        
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini JSON response: {e}")
        return {"company_name": startup_id, "raw_text": text[:1000]}
    except Exception as e:
        logger.error(f"Gemini extraction failed: {e}", exc_info=True)
        # Return basic data on failure
        return {
            "company_name": startup_id,
            "raw_text": text[:1000],
            "extraction_error": str(e)
        }


@router.get("/checklist/{startup_id}")
async def get_checklist_data(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
):
    """Get extracted checklist data.
    
    Args:
        startup_id: Startup identifier
        api_key: API key
        
    Returns:
        Checklist data
    """
    db = get_database_service()
    startup_data = db.get_startup(startup_id)
    
    if not startup_data:
        raise HTTPException(404, "Startup not found")
    
    # Get checklist from questionnaire_responses
    responses = startup_data.get("questionnaire_responses", {})
    if "checklist" not in responses:
        raise HTTPException(404, "Checklist not found for this startup")
    
    return {
        "startup_id": startup_id,
        "company_name": responses.get("company_name", startup_id),
        "checklist": responses["checklist"],
        "extracted_data": responses["checklist"].get("extracted_data", {})
    }

