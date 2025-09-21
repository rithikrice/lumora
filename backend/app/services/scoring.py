"""Scoring service for startup evaluation."""

from typing import Dict, Any, Optional, Tuple
import numpy as np
from dataclasses import dataclass

from ..models.dto import KPIMetrics, RecommendationType
from ..core.config import get_settings
from ..core.logging import get_logger

logger = get_logger(__name__)


@dataclass
class ScoringResult:
    """Scoring result."""
    score: float
    recommendation: RecommendationType
    component_scores: Dict[str, float]
    reasoning: str


class StartupScorer:
    """Startup scoring engine."""
    
    def __init__(self):
        """Initialize scorer."""
        self.settings = get_settings()
    
    def calculate_score(
        self,
        kpis: KPIMetrics,
        persona_weights: Dict[str, float],
        founder_signal: float = 0.5
    ) -> ScoringResult:
        """Calculate weighted startup score.
        
        Args:
            kpis: Key performance indicators
            persona_weights: Scoring weights
            founder_signal: Founder quality signal (0-1)
            
        Returns:
            Scoring result
        """
        # Calculate component scores
        growth_score = self._calculate_growth_score(kpis)
        unit_econ_score = self._calculate_unit_econ_score(kpis)
        founder_score = founder_signal  # From NLP analysis
        
        component_scores = {
            'growth': growth_score,
            'unit_econ': unit_econ_score,
            'founder': founder_score
        }
        
        # Calculate weighted score
        weights = {
            'growth': persona_weights.get('growth', 0.4),
            'unit_econ': persona_weights.get('unit_econ', 0.4),
            'founder': persona_weights.get('founder', 0.2)
        }
        
        weighted_score = sum(
            component_scores[key] * weights[key]
            for key in weights
        )
        
        # Determine recommendation
        recommendation = self._get_recommendation(weighted_score)
        
        # Generate reasoning
        reasoning = self._generate_reasoning(
            component_scores,
            weights,
            recommendation
        )
        
        return ScoringResult(
            score=weighted_score,
            recommendation=recommendation,
            component_scores=component_scores,
            reasoning=reasoning
        )
    
    def _calculate_growth_score(self, kpis: KPIMetrics) -> float:
        """Calculate growth component score.
        
        Args:
            kpis: Key performance indicators
            
        Returns:
            Growth score (0-1)
        """
        score = 0.5  # Base score
        
        # ARR score
        if kpis.arr:
            if kpis.arr >= 10_000_000:  # $10M+ ARR
                score += 0.3
            elif kpis.arr >= 5_000_000:  # $5M+ ARR
                score += 0.2
            elif kpis.arr >= 1_000_000:  # $1M+ ARR
                score += 0.1
        
        # Growth rate score
        if kpis.growth_rate:
            if kpis.growth_rate >= 3.0:  # 3x+ growth
                score += 0.2
            elif kpis.growth_rate >= 2.0:  # 2x+ growth
                score += 0.15
            elif kpis.growth_rate >= 1.5:  # 1.5x+ growth
                score += 0.1
        
        # Logo retention score
        if kpis.logo_retention:
            if kpis.logo_retention >= 0.95:
                score += 0.1
            elif kpis.logo_retention >= 0.90:
                score += 0.05
        
        # NRR score
        if kpis.nrr:
            if kpis.nrr >= 1.3:  # 130%+ NRR
                score += 0.1
            elif kpis.nrr >= 1.1:  # 110%+ NRR
                score += 0.05
        
        return min(1.0, score)
    
    def _calculate_unit_econ_score(self, kpis: KPIMetrics) -> float:
        """Calculate unit economics score.
        
        Args:
            kpis: Key performance indicators
            
        Returns:
            Unit economics score (0-1)
        """
        score = 0.5  # Base score
        
        # Gross margin score
        if kpis.gross_margin:
            if kpis.gross_margin >= 0.8:  # 80%+ margin
                score += 0.25
            elif kpis.gross_margin >= 0.7:  # 70%+ margin
                score += 0.15
            elif kpis.gross_margin >= 0.6:  # 60%+ margin
                score += 0.1
        
        # CAC/LTV ratio score
        if kpis.cac_ltv_ratio:
            if kpis.cac_ltv_ratio <= 0.33:  # LTV/CAC >= 3
                score += 0.2
            elif kpis.cac_ltv_ratio <= 0.5:  # LTV/CAC >= 2
                score += 0.1
        
        # Burn efficiency score
        if kpis.burn_rate and kpis.arr:
            burn_multiple = kpis.arr / (kpis.burn_rate * 12) if kpis.burn_rate > 0 else 0
            if burn_multiple >= 1.5:
                score += 0.15
            elif burn_multiple >= 1.0:
                score += 0.1
        
        # Runway score
        if kpis.runway_months:
            if kpis.runway_months >= 18:
                score += 0.1
            elif kpis.runway_months >= 12:
                score += 0.05
            elif kpis.runway_months < 6:
                score -= 0.1
        
        return min(1.0, max(0.0, score))
    
    def _get_recommendation(self, score: float) -> RecommendationType:
        """Get recommendation based on score.
        
        Args:
            score: Weighted score
            
        Returns:
            Recommendation type
        """
        if score >= self.settings.INVEST_THRESHOLD:
            return RecommendationType.INVEST
        elif score >= self.settings.FOLLOW_THRESHOLD:
            return RecommendationType.FOLLOW
        else:
            return RecommendationType.PASS
    
    def _generate_reasoning(
        self,
        component_scores: Dict[str, float],
        weights: Dict[str, float],
        recommendation: RecommendationType
    ) -> str:
        """Generate scoring reasoning.
        
        Args:
            component_scores: Individual component scores
            weights: Component weights
            recommendation: Final recommendation
            
        Returns:
            Reasoning text
        """
        # Find strongest and weakest components
        weighted_contributions = {
            k: component_scores[k] * weights[k]
            for k in component_scores
        }
        
        strongest = max(weighted_contributions.items(), key=lambda x: x[1])
        weakest = min(weighted_contributions.items(), key=lambda x: x[1])
        
        reasoning = f"Recommendation: {recommendation.value}. "
        reasoning += f"Strongest signal: {strongest[0]} ({strongest[1]:.2f}). "
        reasoning += f"Needs improvement: {weakest[0]} ({weakest[1]:.2f})."
        
        return reasoning


class CounterfactualAnalyzer:
    """Counterfactual analysis for investment decisions."""
    
    def __init__(self):
        """Initialize analyzer."""
        self.settings = get_settings()
        self.scorer = StartupScorer()
    
    def calculate_breakpoint(
        self,
        current_kpis: KPIMetrics,
        current_score: float,
        persona_weights: Dict[str, float],
        target_recommendation: Optional[RecommendationType] = None
    ) -> Dict[str, float]:
        """Calculate minimum KPI changes to flip recommendation.
        
        Args:
            current_kpis: Current KPIs
            current_score: Current score
            persona_weights: Scoring weights
            target_recommendation: Target recommendation (optional)
            
        Returns:
            Minimum required changes
        """
        # Determine target score
        current_rec = self._get_recommendation(current_score)
        
        if target_recommendation:
            target_score = self._get_target_score(target_recommendation)
        else:
            # Find next threshold
            if current_rec == RecommendationType.PASS:
                target_score = self.settings.FOLLOW_THRESHOLD
            elif current_rec == RecommendationType.FOLLOW:
                target_score = self.settings.INVEST_THRESHOLD
            else:
                # Already at invest, show what it takes to drop
                target_score = self.settings.FOLLOW_THRESHOLD - 0.01
        
        score_gap = target_score - current_score
        
        # Calculate required changes for each component
        breakpoints = {}
        
        # Growth metrics
        growth_weight = persona_weights.get('growth', 0.4)
        if growth_weight > 0:
            growth_contribution_needed = score_gap / growth_weight
            
            # Estimate ARR change needed
            if current_kpis.arr:
                arr_multiplier = 1 + (growth_contribution_needed * 2)
                breakpoints['arr'] = current_kpis.arr * arr_multiplier
            
            # Estimate growth rate change needed
            if current_kpis.growth_rate:
                breakpoints['growth_rate'] = current_kpis.growth_rate + growth_contribution_needed
        
        # Unit economics metrics
        unit_econ_weight = persona_weights.get('unit_econ', 0.4)
        if unit_econ_weight > 0:
            unit_econ_contribution_needed = score_gap / unit_econ_weight
            
            # Estimate gross margin change needed
            if current_kpis.gross_margin:
                breakpoints['gross_margin'] = min(
                    1.0,
                    current_kpis.gross_margin + unit_econ_contribution_needed * 0.3
                )
            
            # Estimate burn reduction needed
            if current_kpis.burn_rate:
                burn_reduction = unit_econ_contribution_needed * 0.5
                breakpoints['burn_rate'] = max(
                    0,
                    current_kpis.burn_rate * (1 - burn_reduction)
                )
        
        return breakpoints
    
    def simulate_change(
        self,
        current_kpis: KPIMetrics,
        changes: Dict[str, float],
        persona_weights: Dict[str, float]
    ) -> Tuple[KPIMetrics, float, RecommendationType]:
        """Simulate KPI changes and recalculate score.
        
        Args:
            current_kpis: Current KPIs
            changes: KPI changes to apply
            persona_weights: Scoring weights
            
        Returns:
            Tuple of (new KPIs, new score, new recommendation)
        """
        # Apply changes
        new_kpis_dict = current_kpis.dict()
        for key, value in changes.items():
            if hasattr(current_kpis, key):
                if key in ['growth_rate', 'gross_margin', 'cac_ltv_ratio']:
                    # These are deltas
                    current_value = new_kpis_dict.get(key, 0) or 0
                    new_kpis_dict[key] = current_value + value
                else:
                    # These are absolute values
                    new_kpis_dict[key] = value
        
        new_kpis = KPIMetrics(**new_kpis_dict)
        
        # Recalculate score
        result = self.scorer.calculate_score(
            new_kpis,
            persona_weights,
            founder_signal=0.5  # Keep constant for counterfactual
        )
        
        return new_kpis, result.score, result.recommendation
    
    def _get_recommendation(self, score: float) -> RecommendationType:
        """Get recommendation for score."""
        if score >= self.settings.INVEST_THRESHOLD:
            return RecommendationType.INVEST
        elif score >= self.settings.FOLLOW_THRESHOLD:
            return RecommendationType.FOLLOW
        else:
            return RecommendationType.PASS
    
    def _get_target_score(self, recommendation: RecommendationType) -> float:
        """Get minimum score for recommendation."""
        if recommendation == RecommendationType.INVEST:
            return self.settings.INVEST_THRESHOLD
        elif recommendation == RecommendationType.FOLLOW:
            return self.settings.FOLLOW_THRESHOLD
        else:
            return 0.0
