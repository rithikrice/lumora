"""Export API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any

from ..models.dto import (
    ExportRequest, ExportResponse, AnalyzeRequest
)
from ..core.security import verify_api_key
from ..core.logging import get_logger, log_api_call
from ..services.gdocs import GoogleDocsExporter
from .analyze import analyze_startup

router = APIRouter()
logger = get_logger(__name__)


@router.post("/export", response_model=ExportResponse)
async def export_report(
    request: ExportRequest,
    api_key: str = Depends(verify_api_key)
) -> ExportResponse:
    """Export analysis report to specified format.
    
    Args:
        request: Export request
        api_key: API key for authentication
        
    Returns:
        Export response with document URL
        
    Raises:
        HTTPException: If export fails
    """
    log_api_call("/export", "POST", startup_id=request.startup_id, format=request.format.value)
    
    try:
        # Get analysis data
        analyze_req = AnalyzeRequest(
            startup_id=request.startup_id,
            persona={},  # Use default weights
            include_peers=True,
            include_stress=True
        )
        analysis = await analyze_startup(analyze_req, api_key)
        
        # Get additional data for comprehensive report
        from ..services.database import DatabaseService
        db = DatabaseService()
        startup_data = db.get_startup(request.startup_id)
        
        # Get video analysis if available
        video_analysis = None
        from ..api.video import _video_storage
        for video_id, data in _video_storage.items():
            if data.get("startup_id") == request.startup_id:
                video_analysis = data.get("analysis")
                break
        
        # Export based on format
        if request.format.value == "gdoc":
            exporter = GoogleDocsExporter()
            doc_info = await exporter.create_comprehensive_report(
                analysis=analysis,
                include_appendix=request.include_appendix,
                questionnaire_data=startup_data.get("questionnaire_responses") if startup_data else None,
                video_analysis=video_analysis
            )
            
            response = ExportResponse(
                startup_id=request.startup_id,
                format=request.format,
                document_url=doc_info.get("document_url"),
                document_id=doc_info.get("document_id"),
                success=True,
                message="Report exported successfully"
            )
            
        elif request.format.value == "json":
            # Return analysis as JSON
            import json
            from pathlib import Path
            
            export_dir = Path("data/exports")
            export_dir.mkdir(parents=True, exist_ok=True)
            
            export_path = export_dir / f"{request.startup_id}_analysis.json"
            
            # Convert to dict and save
            analysis_dict = analysis.dict()
            with open(export_path, "w") as f:
                json.dump(analysis_dict, f, indent=2, default=str)
            
            response = ExportResponse(
                startup_id=request.startup_id,
                format=request.format,
                document_url=f"file://{export_path.absolute()}",
                document_id=f"json_{request.startup_id}",
                success=True,
                message="Analysis exported as JSON"
            )
            
        else:
            # PDF export would go here
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail=f"Export format '{request.format.value}' not implemented yet"
            )
        
        logger.info(
            f"Report exported successfully",
            extra={
                "startup_id": request.startup_id,
                "format": request.format.value,
                "document_id": response.document_id
            }
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Export failed: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Export failed"
        )


@router.post("/export/google-doc", response_model=ExportResponse)
async def export_to_google_doc(
    request: ExportRequest,
    api_key: str = Depends(verify_api_key)
) -> ExportResponse:
    """Export analysis report to Google Docs.
    
    Convenience endpoint specifically for Google Docs export.
    
    Args:
        request: Export request
        api_key: API key for authentication
        
    Returns:
        Export response with document URL
    """
    request.format = "gdoc"  # Force Google Doc format
    return await export_report(request, api_key)
