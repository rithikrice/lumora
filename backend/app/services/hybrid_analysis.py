"""Hybrid analysis service combining multiple data sources."""

from typing import List, Dict, Any, Optional, Tuple
from enum import Enum
from datetime import datetime

from ..models.dto import DocumentChunk, Evidence, AnalyzeResponse, KPIMetrics
from ..core.logging import get_logger
from .retrieval import HybridRetriever
from .generator import GeminiGenerator
from .scoring import StartupScorer
from .database import DatabaseService
from .questionnaire import InvestmentQuestionnaire

logger = get_logger(__name__)


class DataSource(str, Enum):
    """Data source types."""
    DECK = "deck"
    QUESTIONNAIRE = "questionnaire"
    EXTERNAL_API = "external_api"
    MANUAL_ENTRY = "manual_entry"
    HYBRID = "hybrid"


class DataCompleteness:
    """Assess data completeness for analysis."""
    
    REQUIRED_METRICS = [
        "arr", "growth_rate", "gross_margin", "burn_rate",
        "runway_months", "customer_count", "team_size"
    ]
    
    OPTIONAL_METRICS = [
        "nrr", "logo_retention", "cac", "ltv", "tam",
        "previous_funding", "valuation"
    ]
    
    @classmethod
    def assess(cls, data: Dict[str, Any]) -> Dict[str, Any]:
        """Assess data completeness.
        
        Args:
            data: Available data
            
        Returns:
            Completeness assessment
        """
        required_present = sum(1 for m in cls.REQUIRED_METRICS if m in data and data[m])
        optional_present = sum(1 for m in cls.OPTIONAL_METRICS if m in data and data[m])
        
        required_score = required_present / len(cls.REQUIRED_METRICS)
        optional_score = optional_present / len(cls.OPTIONAL_METRICS)
        overall_score = (required_score * 0.7) + (optional_score * 0.3)
        
        return {
            "overall_score": overall_score,
            "required_completeness": required_score,
            "optional_completeness": optional_score,
            "missing_required": [m for m in cls.REQUIRED_METRICS if m not in data or not data[m]],
            "missing_optional": [m for m in cls.OPTIONAL_METRICS if m not in data or not data[m]],
            "confidence_level": "high" if overall_score > 0.8 else "medium" if overall_score > 0.5 else "low"
        }


class HybridAnalysisService:
    """Service for hybrid analysis combining multiple data sources."""
    
    def __init__(self):
        """Initialize hybrid analysis service."""
        self.db_service = DatabaseService()
        self.questionnaire_service = InvestmentQuestionnaire()
        self.generator = GeminiGenerator()
        self.scorer = StartupScorer()
    
    async def collect_all_data(
        self,
        startup_id: str
    ) -> Tuple[Dict[str, Any], List[DataSource]]:
        """Collect data from all available sources.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            Tuple of (aggregated_data, data_sources)
        """
        aggregated_data = {}
        data_sources = []
        
        # 1. Get questionnaire responses
        questionnaire_data = self._extract_questionnaire_data(startup_id)
        if questionnaire_data:
            aggregated_data.update(questionnaire_data)
            data_sources.append(DataSource.QUESTIONNAIRE)
        
        # 2. Get data from uploaded documents (via RAG)
        document_data = await self._extract_document_data(startup_id)
        if document_data:
            # Merge, preferring document data for conflicts
            for key, value in document_data.items():
                if key not in aggregated_data or value:
                    aggregated_data[key] = value
            data_sources.append(DataSource.DECK)
        
        # 3. Get from database if previously saved
        db_data = self._get_database_data(startup_id)
        if db_data:
            # Fill in any missing data
            for key, value in db_data.items():
                if key not in aggregated_data:
                    aggregated_data[key] = value
        
        # Determine overall source type
        if DataSource.DECK in data_sources and DataSource.QUESTIONNAIRE in data_sources:
            data_sources = [DataSource.HYBRID]
        
        return aggregated_data, data_sources
    
    def _extract_questionnaire_data(self, startup_id: str) -> Dict[str, Any]:
        """Extract data from questionnaire responses.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            Extracted metrics
        """
        responses = self.db_service.get_questionnaire_responses(startup_id)
        
        if not responses:
            return {}
        
        data = {}
        for response in responses:
            question_id = response["question_id"]
            answer = response["answer"]
            
            # Convert to appropriate type
            if question_id in ["arr", "mrr", "burn_rate", "cac", "ltv", "tam", "valuation"]:
                try:
                    data[question_id] = float(answer)
                except (ValueError, TypeError):
                    pass
            elif question_id in ["growth_rate", "gross_margin", "logo_retention", "nrr"]:
                try:
                    # Store as decimal (e.g., 75% -> 0.75)
                    value = float(answer)
                    data[question_id] = value / 100 if value > 1 else value
                except (ValueError, TypeError):
                    pass
            elif question_id in ["team_size", "total_customers", "runway"]:
                try:
                    data[question_id] = int(float(answer))
                except (ValueError, TypeError):
                    pass
            else:
                data[question_id] = answer
        
        return data
    
    async def _extract_document_data(self, startup_id: str) -> Dict[str, Any]:
        """Extract data from uploaded documents using RAG.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            Extracted metrics
        """
        retriever = HybridRetriever(startup_id)
        
        # Query for specific metrics
        queries = [
            "What is the ARR annual recurring revenue MRR monthly recurring revenue?",
            "What is the growth rate year over year YoY revenue growth?",
            "What is the gross margin profit margin unit economics?",
            "What is the burn rate monthly burn cash burn runway?",
            "How many customers users clients logos do they have?",
            "What is the team size number of employees headcount?",
            "What is the NRR net revenue retention dollar retention?",
            "What is the CAC customer acquisition cost LTV lifetime value?"
        ]
        
        extracted = {}
        
        for query in queries:
            try:
                evidence = await retriever.retrieve(query, k=5)
                if evidence:
                    # Use Gemini to extract structured data
                    metrics = await self._extract_metrics_from_evidence(evidence)
                    extracted.update(metrics)
            except Exception as e:
                logger.warning(f"Failed to extract from query '{query}': {str(e)}")
        
        return extracted
    
    async def _extract_metrics_from_evidence(
        self,
        evidence: List[Evidence]
    ) -> Dict[str, Any]:
        """Use Gemini to extract structured metrics from evidence.
        
        Args:
            evidence: Evidence chunks
            
        Returns:
            Extracted metrics
        """
        if not self.generator.model:
            # Mock extraction for offline mode
            return {"arr": 5000000, "growth_rate": 2.0}
        
        context = "\n".join([e.snippet for e in evidence[:3]])
        
        prompt = f"""
        Extract any financial metrics from this text.
        Return ONLY a JSON object with these fields (use null if not found):
        {{
            "arr": number or null,
            "growth_rate": decimal (e.g., 2.5 for 2.5x) or null,
            "gross_margin": decimal (e.g., 0.75 for 75%) or null,
            "burn_rate": number or null,
            "runway_months": integer or null,
            "customer_count": integer or null,
            "nrr": decimal or null,
            "cac": number or null,
            "ltv": number or null
        }}
        
        Text: {context}
        """
        
        try:
            response = await self.generator._generate(prompt, temperature=0.1)
            import json
            metrics = json.loads(response)
            # Filter out nulls
            return {k: v for k, v in metrics.items() if v is not None}
        except Exception as e:
            logger.warning(f"Failed to extract metrics: {str(e)}")
            return {}
    
    def _get_database_data(self, startup_id: str) -> Dict[str, Any]:
        """Get previously saved data from database.
        
        Args:
            startup_id: Startup identifier
            
        Returns:
            Saved metrics
        """
        startup = self.db_service.get_startup(startup_id)
        
        if not startup or not startup.get("latest_analysis"):
            return {}
        
        analysis = startup["latest_analysis"]
        kpis = analysis.get("kpis", {})
        
        return {
            "arr": kpis.get("arr"),
            "growth_rate": kpis.get("growth_rate"),
            "gross_margin": kpis.get("gross_margin"),
            "burn_rate": kpis.get("burn_rate"),
            "runway_months": kpis.get("runway_months")
        }
    
    def identify_data_gaps(
        self,
        current_data: Dict[str, Any]
    ) -> List[str]:
        """Identify missing critical data points.
        
        Args:
            current_data: Currently available data
            
        Returns:
            List of suggested questions to ask
        """
        assessment = DataCompleteness.assess(current_data)
        
        # Prioritize missing required metrics
        questions = []
        question_map = {
            "arr": "What is your current Annual Recurring Revenue (ARR)?",
            "growth_rate": "What is your year-over-year growth rate?",
            "gross_margin": "What is your gross margin percentage?",
            "burn_rate": "What is your monthly burn rate?",
            "runway_months": "How many months of runway do you have?",
            "customer_count": "How many paying customers do you have?",
            "team_size": "How many full-time employees do you have?"
        }
        
        for metric in assessment["missing_required"]:
            if metric in question_map:
                questions.append(question_map[metric])
        
        return questions
    
    async def run_comprehensive_analysis(
        self,
        startup_id: str,
        persona_weights: Dict[str, float]
    ) -> Dict[str, Any]:
        """Run comprehensive analysis using all available data.
        
        Args:
            startup_id: Startup identifier
            persona_weights: Scoring persona weights
            
        Returns:
            Comprehensive analysis results
        """
        # Collect all data
        data, sources = await self.collect_all_data(startup_id)
        
        # Assess completeness
        completeness = DataCompleteness.assess(data)
        
        # Identify gaps
        data_gaps = self.identify_data_gaps(data)
        
        # Build KPIs from available data
        kpis = KPIMetrics(
            arr=data.get("arr"),
            growth_rate=data.get("growth_rate"),
            gross_margin=data.get("gross_margin"),
            cac_ltv_ratio=data.get("cac") / data.get("ltv") if data.get("cac") and data.get("ltv") else None,
            burn_rate=data.get("burn_rate"),
            runway_months=data.get("runway_months") or data.get("runway"),
            logo_retention=data.get("logo_retention"),
            nrr=data.get("nrr")
        )
        
        # Calculate score (adjust confidence based on completeness)
        scoring_result = self.scorer.calculate_score(
            kpis=kpis,
            persona_weights=persona_weights,
            founder_signal=0.5  # Default if not assessed
        )
        
        # Adjust score based on data completeness
        confidence_multiplier = 0.8 + (completeness["overall_score"] * 0.2)
        adjusted_score = scoring_result.score * confidence_multiplier
        
        return {
            "startup_id": startup_id,
            "data_sources": [s.value for s in sources],
            "data_completeness": completeness,
            "data_gaps": data_gaps,
            "kpis": kpis.dict(),
            "raw_score": scoring_result.score,
            "adjusted_score": adjusted_score,
            "recommendation": scoring_result.recommendation.value,
            "confidence": completeness["confidence_level"],
            "component_scores": scoring_result.component_scores,
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "suggestions": {
                "next_steps": self._generate_next_steps(completeness, data_gaps),
                "data_collection": "questionnaire" if len(data_gaps) > 3 else "optional"
            }
        }
    
    def _generate_next_steps(
        self,
        completeness: Dict[str, Any],
        data_gaps: List[str]
    ) -> List[str]:
        """Generate recommended next steps.
        
        Args:
            completeness: Data completeness assessment
            data_gaps: Missing data points
            
        Returns:
            List of next steps
        """
        steps = []
        
        if completeness["overall_score"] < 0.5:
            steps.append("Complete questionnaire for missing critical metrics")
        elif completeness["overall_score"] < 0.8:
            steps.append("Provide additional data for higher confidence analysis")
        
        if data_gaps:
            steps.append(f"Answer {len(data_gaps)} additional questions for complete analysis")
        
        steps.append("Upload pitch deck if not already provided")
        steps.append("Schedule follow-up discussion with investment team")
        
        return steps
