"""Stress testing service for scenario analysis."""

from typing import Dict, Any, Literal
from ..models.dto import KPIMetrics, StressTestResponse
from ..core.logging import get_logger

logger = get_logger(__name__)


class StressTestService:
    """Service for stress testing startup metrics."""
    
    def apply_stress_scenario(
        self,
        kpis: KPIMetrics,
        scenario: Literal["revenue_shock", "funding_delay", "custom"],
        custom_params: Dict[str, float] = None
    ) -> StressTestResponse:
        """Apply stress test scenario to KPIs.
        
        Args:
            kpis: Current KPIs
            scenario: Stress test scenario
            custom_params: Custom scenario parameters
            
        Returns:
            Stress test results
        """
        stressed_kpis = kpis.dict()
        
        if scenario == "revenue_shock":
            # Scenario A: revenue -20%, churn +2%
            if kpis.arr:
                stressed_kpis['arr'] = kpis.arr * 0.8
            if kpis.growth_rate:
                stressed_kpis['growth_rate'] = kpis.growth_rate * 0.7
                
        elif scenario == "funding_delay":
            # Scenario B: fundraise delayed 6 months
            if kpis.runway_months:
                stressed_kpis['runway_months'] = max(0, kpis.runway_months - 6)
            if kpis.burn_rate:
                stressed_kpis['burn_rate'] = kpis.burn_rate * 1.1
                
        elif scenario == "custom" and custom_params:
            # Apply custom changes
            for key, delta in custom_params.items():
                if hasattr(kpis, key):
                    current = getattr(kpis, key) or 0
                    stressed_kpis[key] = current + delta
        
        stressed_metrics = KPIMetrics(**stressed_kpis)
        
        # Calculate impact
        runway_change = (stressed_metrics.runway_months or 0) - (kpis.runway_months or 0)
        dilution_impact = 0.1 if runway_change < -3 else 0.05
        
        # Determine risk level
        if runway_change <= -6:
            risk_level = "critical"
        elif runway_change <= -3:
            risk_level = "high"
        elif runway_change <= 0:
            risk_level = "medium"
        else:
            risk_level = "low"
        
        return StressTestResponse(
            startup_id="",  # Set by caller
            scenario=scenario,
            original_metrics=kpis,
            stressed_metrics=stressed_metrics,
            runway_change=runway_change,
            dilution_impact=dilution_impact,
            risk_level=risk_level
        )
