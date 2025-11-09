"""Analysis view endpoints that read from profile (SSoT).

These endpoints provide clean views over the profile data for UI consumption.
All data comes from the profile, ensuring consistency regardless of source.
"""

from fastapi import APIRouter, Depends, HTTPException
from typing import Dict, Any, List, Optional
from pydantic import BaseModel

from ..core.security import verify_api_key
from ..core.logging import get_logger, log_api_call
from ..services.database import get_database_service

logger = get_logger(__name__)
router = APIRouter()


@router.get("/analysis/{startup_id}/investment-highlights")
async def investment_highlights(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get investment highlights from profile.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Investment highlights data
    """
    log_api_call("/analysis/investment-highlights", "GET", startup_id=startup_id)
    
    db = get_database_service()
    data = db.get_startup(startup_id)
    
    if not data:
        raise HTTPException(404, "Startup not found")
    
    profile = data.get("profile", {})
    funding = profile.get("funding", {})
    business_model = profile.get("business_model", {})
    strategy = profile.get("strategy", {})
    
    return {
        "startup_id": startup_id,
        "current_ask": funding.get("ask_now"),
        "valuation": funding.get("valuation_implied"),
        "use_of_funds": business_model.get("use_of_funds", []),
        "exit_strategy": strategy.get("exit_strategy"),
        "key_strengths": strategy.get("key_strengths", [])
    }


@router.get("/analysis/{startup_id}/kpis")
async def kpis(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get KPI metrics from profile.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        KPI metrics data
    """
    log_api_call("/analysis/kpis", "GET", startup_id=startup_id)
    
    db = get_database_service()
    data = db.get_startup(startup_id)
    
    if not data:
        raise HTTPException(404, "Startup not found")
    
    profile = data.get("profile", {})
    metrics = profile.get("metrics", {})
    market = profile.get("market", {})
    
    return {
        "startup_id": startup_id,
        "arr": metrics.get("arr"),
        "cac": metrics.get("cac"),
        "churn": metrics.get("churn"),
        "runway": metrics.get("runway_months"),
        "gmv": metrics.get("gmv"),
        "tam": market.get("tam"),
        "sam": market.get("sam"),
        "som": market.get("som"),
        "growth": metrics.get("growth"),
        "peer_comparison": []  # TODO: fill from benchmark service if available
    }


@router.get("/analysis/{startup_id}/insights")
async def insights(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get AI insights from profile.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Insights data
    """
    log_api_call("/analysis/insights", "GET", startup_id=startup_id)
    
    db = get_database_service()
    data = db.get_startup(startup_id)
    
    if not data:
        raise HTTPException(404, "Startup not found")
    
    profile = data.get("profile", {})
    insights_data = profile.get("insights", {})
    strategy = profile.get("strategy", {})
    
    return {
        "startup_id": startup_id,
        "founder_integrity_score": insights_data.get("founder_integrity_score"),
        "cultural_fit_score": insights_data.get("cultural_fit_score"),
        "executive_summary": strategy.get("executive_summary"),
        "risk_heatmap": insights_data.get("risk_heatmap", []),
        "evidence_highlights": insights_data.get("evidence_highlights", [])
    }


@router.get("/analysis/{startup_id}/growth-simulations")
async def growth_simulations(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get growth simulation scenarios.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Growth simulation data
    """
    log_api_call("/analysis/growth-simulations", "GET", startup_id=startup_id)
    
    db = get_database_service()
    data = db.get_startup(startup_id)
    
    if not data:
        raise HTTPException(404, "Startup not found")
    
    profile = data.get("profile", {})
    metrics = profile.get("metrics", {})
    
    # TODO: Implement actual growth simulation logic
    # For now, return placeholder structure
    arr = metrics.get("arr")
    growth = metrics.get("growth")
    
    return {
        "startup_id": startup_id,
        "base_scenario": {
            "arr_current": arr,
            "growth_rate": growth,
            "projection_months": 12
        },
        "optimistic_scenario": {
            "arr_current": arr,
            "growth_rate": growth,
            "projection_months": 12
        },
        "pessimistic_scenario": {
            "arr_current": arr,
            "growth_rate": growth,
            "projection_months": 12
        }
    }

