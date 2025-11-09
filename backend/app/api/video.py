"""Video analysis API endpoints for founder assessment."""

from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from typing import Dict, Any, Optional
import base64

from ..core.security import verify_api_key
from ..core.logging import get_logger
from ..services.video_analysis import get_video_service
from pydantic import BaseModel

logger = get_logger(__name__)
router = APIRouter()


# Helper functions for UI-friendly metrics
def _get_grade(score: float) -> str:
    """Convert score to letter grade."""
    if score >= 0.9: return "A+"
    elif score >= 0.8: return "A"
    elif score >= 0.7: return "B+"
    elif score >= 0.6: return "B"
    elif score >= 0.5: return "C+"
    elif score >= 0.4: return "C"
    elif score >= 0.3: return "D"
    else: return "F"

def _get_level(score: float) -> str:
    """Convert score to level."""
    if score >= 0.7: return "High"
    elif score >= 0.4: return "Medium"
    else: return "Low"

def _get_recommendation_priority(action: str) -> str:
    """Get priority level for recommendation."""
    priorities = {
        "invest": "high",
        "strong_yes": "high", 
        "yes": "high",
        "follow": "medium",
        "maybe": "medium",
        "pass": "low",
        "no": "low"
    }
    return priorities.get(action.lower(), "medium")

def _get_overall_status(confidence: float) -> str:
    """Get overall status message."""
    if confidence >= 0.8: return "Excellent"
    elif confidence >= 0.6: return "Good"
    elif confidence >= 0.4: return "Fair"
    else: return "Needs Improvement"


class VideoUploadResponse(BaseModel):
    """Response for video upload."""
    video_id: str
    startup_id: str  # Auto-generated if not provided
    filename: str
    size_mb: float
    analysis: Optional[Dict[str, Any]] = None  # Include analysis if processed
    message: str = "Video uploaded and analyzed successfully"


class VideoAnalysisResponse(BaseModel):
    """Response for video analysis."""
    startup_id: str
    video_id: str
    founder_analysis: Dict[str, Any]
    sentiment_analysis: Dict[str, Any]
    content_analysis: Dict[str, Any]
    investment_signals: Dict[str, Any]
    red_flags: list
    green_flags: list
    key_quotes: list
    visual_analysis: Optional[Dict[str, Any]] = None
    ui_metrics: Optional[Dict[str, Any]] = None  # UI-ready calculated metrics


@router.post("/video/upload", response_model=VideoUploadResponse)
async def upload_pitch_video(
    file: UploadFile = File(...),
    startup_id: Optional[str] = Form(None),
    api_key: str = Depends(verify_api_key)
) -> VideoUploadResponse:
    """Upload a founder pitch video for analysis.
    
    Args:
        file: Video file to analyze
        startup_id: Optional startup identifier (auto-generated if not provided)
    """
    logger.info(f"Uploading video for {startup_id}: {file.filename}")
    
    try:
        # Validate file type
        logger.info(f"File content type: {file.content_type}")
        if not file.content_type or not file.content_type.startswith('video/'):
            # Also check file extension as fallback
            if not file.filename or not file.filename.lower().endswith(('.mp4', '.mov', '.avi', '.mkv', '.webm')):
                raise HTTPException(400, f"File must be a video. Detected type: {file.content_type}, filename: {file.filename}")
        
        # Read video content
        content = await file.read()
        size_mb = len(content) / (1024 * 1024)
        
        if size_mb > 100:  # 100MB limit for hackathon
            raise HTTPException(400, "Video must be under 100MB")
        
        # Generate video ID and startup_id if not provided
        if not startup_id:
            import hashlib
            from datetime import datetime
            startup_id = f"video_{hashlib.md5(file.filename.encode()).hexdigest()[:8]}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        
        video_id = f"{startup_id}-video-{hash(file.filename)}"
        
        # Store video (in memory for hackathon)
        # In production, upload to GCS
        _video_storage[video_id] = {
            "content": content,
            "filename": file.filename,
            "startup_id": startup_id
        }
        
        # For demo: Analyze immediately if video is small enough
        analysis_result = None
        if size_mb < 10:  # Auto-analyze videos under 10MB
            try:
                logger.info(f"Auto-analyzing video {video_id} ({size_mb:.1f} MB)")
                service = get_video_service()
                analysis_result = await service.analyze_video(
                    video_content=content,
                    startup_id=startup_id,
                    filename=file.filename
                )
                # Store analysis for later retrieval
                _video_storage[video_id]["analysis"] = analysis_result
            except Exception as e:
                logger.warning(f"Auto-analysis failed: {e}")
        
        response = VideoUploadResponse(
            video_id=video_id,
            startup_id=startup_id,
            filename=file.filename,
            size_mb=round(size_mb, 2)
        )
        
        # Include analysis if available - flatten structure for UI
        if analysis_result:
            # Flatten the nested structure for better UI consumption
            result = analysis_result.get("analysis", {})
            response.analysis = {
                "processed_with": analysis_result.get("processed_with", "Unknown"),
                "timestamp": analysis_result.get("timestamp"),
                "transcript": analysis_result.get("transcript", "")[:200] + "..." if analysis_result.get("transcript") else "No speech detected",
                "founder_analysis": result.get("founder_analysis", {}),
                "sentiment_analysis": result.get("sentiment_analysis", {}),
                "content_analysis": result.get("content_quality", result.get("content_analysis", {})),
                "investment_signals": result.get("investment_signals", {}),
                "visual_analysis": analysis_result.get("visual_analysis", result.get("visual_analysis", {})),
                "ui_metrics": {
                    # Overall founder score (0-100)
                    "founder_score": int(result.get("founder_analysis", {}).get("confidence_score", 0) * 100),
                    
                    # Communication grade (A-F)
                    "communication_grade": _get_grade(result.get("founder_analysis", {}).get("communication_clarity", 0)),
                    
                    # Passion level (High/Medium/Low)
                    "passion_level": _get_level(result.get("founder_analysis", {}).get("passion_score", 0)),
                    
                    # Investment recommendation
                    "recommendation": {
                        "action": result.get("investment_signals", {}).get("recommended_action", "pass").upper(),
                        "priority": _get_recommendation_priority(result.get("investment_signals", {}).get("recommended_action", "pass")),
                        "confidence": int(result.get("sentiment_analysis", {}).get("confidence", 0) * 100)
                    },
                    
                    # Key insights for UI cards
                    "insights": {
                        "strength": result.get("investment_signals", {}).get("key_strengths", ["Professional appearance"])[0] if result.get("investment_signals", {}).get("key_strengths") else "Professional appearance",
                        "concern": result.get("investment_signals", {}).get("concerns", ["Needs more clarity"])[0] if result.get("investment_signals", {}).get("concerns") else "Needs more clarity",
                        "sentiment": result.get("sentiment_analysis", {}).get("overall_sentiment", "neutral").title(),
                        "energy": result.get("sentiment_analysis", {}).get("key_emotions", ["professional"])[0].title() if result.get("sentiment_analysis", {}).get("key_emotions") else "Professional"
                    },
                    
                    # Progress bars data
                    "scores": {
                        "confidence": int(result.get("founder_analysis", {}).get("confidence_score", 0) * 100),
                        "clarity": int(result.get("founder_analysis", {}).get("communication_clarity", 0) * 100),
                        "passion": int(result.get("founder_analysis", {}).get("passion_score", 0) * 100),
                        "authenticity": int(result.get("founder_analysis", {}).get("authenticity", 0) * 100),
                        "technical_depth": int(result.get("founder_analysis", {}).get("technical_depth", 0) * 100)
                    },
                    
                    # Status indicators
                    "status": {
                        "overall": _get_overall_status(result.get("founder_analysis", {}).get("confidence_score", 0)),
                        "ready_for_pitch": result.get("founder_analysis", {}).get("confidence_score", 0) > 0.7,
                        "needs_coaching": result.get("founder_analysis", {}).get("communication_clarity", 0) < 0.5
                    }
                }
            }
        
        return response
        
    except Exception as e:
        logger.error(f"Video upload failed: {e}")
        raise HTTPException(500, f"Upload failed: {str(e)}")


class VideoAnalyzeRequest(BaseModel):
    """Request for video analysis."""
    video_id: str


@router.post("/video/analyze", response_model=VideoAnalysisResponse)
async def analyze_pitch_video(
    request: VideoAnalyzeRequest,
    api_key: str = Depends(verify_api_key)
) -> VideoAnalysisResponse:
    """
    Analyze founder pitch video for sentiment and investment signals.
    
    This endpoint showcases:
    - Multi-modal AI analysis
    - Sentiment detection
    - Confidence scoring
    - Body language analysis
    - Investment signal extraction
    """
    video_id = request.video_id
    logger.info(f"Analyzing video: {video_id}")
    
    try:
        # Get video from storage
        if video_id not in _video_storage:
            raise HTTPException(404, "Video not found")
        
        video_data = _video_storage[video_id]
        
        # Check if analysis already exists (from upload auto-analysis)
        if "analysis" in video_data:
            logger.info(f"Using cached analysis for video {video_id}")
            analysis = video_data["analysis"]
        else:
            # Analyze with video service (only if not already done)
            logger.info(f"Running new analysis for video {video_id}")
            service = get_video_service()
            analysis = await service.analyze_video(
                video_content=video_data["content"],
                startup_id=video_data["startup_id"],
                filename=video_data["filename"]
            )
            # Store analysis for future use
            video_data["analysis"] = analysis
        
        # Extract analysis components and ensure consistent structure
        result = analysis.get("analysis", {})
        
        # Build safe defaults if sections are missing
        def _defaults():
            return {
                "founder_analysis": {
                    "confidence_score": 0.5,
                    "communication_clarity": 0.5,
                    "technical_depth": 0.5,
                    "passion_score": 0.5,
                    "authenticity": 0.5
                },
                "sentiment_analysis": {
                    "overall_sentiment": "neutral",
                    "confidence": 0.5,
                    "key_emotions": ["professional"]
                },
                "content_quality": {
                    "problem_articulation": 0.5,
                    "solution_clarity": 0.5,
                    "market_understanding": 0.5
                },
                "investment_signals": {
                    "founder_quality": 0.5,
                    "recommended_action": "pass",
                    "key_strengths": ["Professional appearance"],
                    "concerns": ["Needs more clarity"]
                },
                "visual_analysis": {
                    "faces_detected": 0,
                    "emotions": [],
                    "labels": [],
                    "confidence_indicators": []
                }
            }
        d = _defaults()
        
        founder_analysis = result.get("founder_analysis") or d["founder_analysis"]
        sentiment_analysis = result.get("sentiment_analysis") or d["sentiment_analysis"]
        # prefer content_quality then fallback to content_analysis then defaults
        content_analysis = result.get("content_quality") or result.get("content_analysis") or d["content_quality"]
        investment_signals = result.get("investment_signals") or d["investment_signals"]
        visual_analysis = analysis.get("visual_analysis") or result.get("visual_analysis") or d["visual_analysis"]
        
        # Get transcript for context
        transcript = analysis.get("transcript", "")
        
        # Create UI-friendly response with calculated metrics
        response_data = {
            "startup_id": video_data["startup_id"],
            "video_id": video_id,
            "founder_analysis": founder_analysis,
            "sentiment_analysis": sentiment_analysis,
            "content_analysis": content_analysis,
            "investment_signals": investment_signals,
            "red_flags": result.get("red_flags", []),
            "green_flags": result.get("green_flags", []),
            "key_quotes": result.get("key_quotes", [transcript[:100] + "..." if transcript else "No speech detected"]),
            "visual_analysis": visual_analysis,
            
            # Add UI-ready metrics
            "ui_metrics": {
                # Overall founder score (0-100)
                "founder_score": int(founder_analysis.get("confidence_score", 0) * 100),
                
                # Communication grade (A-F)
                "communication_grade": _get_grade(founder_analysis.get("communication_clarity", 0)),
                
                # Passion level (High/Medium/Low)
                "passion_level": _get_level(founder_analysis.get("passion_score", 0)),
                
                # Investment recommendation
                "recommendation": {
                    "action": investment_signals.get("recommended_action", "pass").upper(),
                    "priority": _get_recommendation_priority(investment_signals.get("recommended_action", "pass")),
                    "confidence": int(sentiment_analysis.get("confidence", 0) * 100)
                },
                
                # Key insights for UI cards
                "insights": {
                    "strength": investment_signals.get("key_strengths", ["Professional appearance"])[0] if investment_signals.get("key_strengths") else "Professional appearance",
                    "concern": investment_signals.get("concerns", ["Needs more clarity"])[0] if investment_signals.get("concerns") else "Needs more clarity",
                    "sentiment": sentiment_analysis.get("overall_sentiment", "neutral").title(),
                    "energy": sentiment_analysis.get("key_emotions", ["professional"])[0].title() if sentiment_analysis.get("key_emotions") else "Professional"
                },
                
                # Progress bars data
                "scores": {
                    "confidence": int(founder_analysis.get("confidence_score", 0) * 100),
                    "clarity": int(founder_analysis.get("communication_clarity", 0) * 100),
                    "passion": int(founder_analysis.get("passion_score", 0) * 100),
                    "authenticity": int(founder_analysis.get("authenticity", 0) * 100),
                    "technical_depth": int(founder_analysis.get("technical_depth", 0) * 100)
                },
                
                # Status indicators
                "status": {
                    "overall": _get_overall_status(founder_analysis.get("confidence_score", 0)),
                    "ready_for_pitch": founder_analysis.get("confidence_score", 0) > 0.7,
                    "needs_coaching": founder_analysis.get("communication_clarity", 0) < 0.5
                }
            }
        }
        
        return VideoAnalysisResponse(**response_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Video analysis failed: {e}")
        raise HTTPException(500, f"Video analysis failed: {str(e)}")


# Removed redundant insights endpoint - all data available via /v1/video/analyze


# In-memory storage for hackathon demo
_video_storage = {}
