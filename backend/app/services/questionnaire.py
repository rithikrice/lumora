"""Interactive questionnaire service for guided data collection."""

from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

from ..core.logging import get_logger
from ..models.dto import DocumentChunk, DocumentType
from .generator import GeminiGenerator

logger = get_logger(__name__)


class QuestionType(str, Enum):
    """Question types for different response formats."""
    TEXT = "text"
    NUMBER = "number"
    CHOICE = "choice"
    MULTI_CHOICE = "multi_choice"
    RANGE = "range"
    YES_NO = "yes_no"
    DATE = "date"
    URL = "url"


@dataclass
class Question:
    """Questionnaire question definition."""
    id: str
    text: str
    type: QuestionType
    category: str
    required: bool = True
    options: List[str] = None
    validation: Dict[str, Any] = None
    follow_up: Optional[str] = None  # ID of follow-up question
    depends_on: Optional[Tuple[str, Any]] = None  # (question_id, answer_value)


class InvestmentQuestionnaire:
    """Investment analysis questionnaire system."""
    
    def __init__(self):
        """Initialize questionnaire with predefined questions."""
        self.questions = self._build_question_tree()
        self.generator = GeminiGenerator()
    
    def _build_question_tree(self) -> Dict[str, Question]:
        """Build the question tree for investment analysis.
        
        Returns:
            Dictionary of questions by ID
        """
        questions = {
            # Company Overview
            "company_name": Question(
                id="company_name",
                text="What is your company name?",
                type=QuestionType.TEXT,
                category="overview"
            ),
            "founding_year": Question(
                id="founding_year",
                text="When was your company founded?",
                type=QuestionType.NUMBER,
                category="overview",
                validation={"min": 1900, "max": 2024}
            ),
            "industry": Question(
                id="industry",
                text="What industry/vertical are you in?",
                type=QuestionType.CHOICE,
                category="overview",
                options=["SaaS", "Fintech", "Healthcare", "E-commerce", "AI/ML", "Marketplace", "Hardware", "Other"]
            ),
            "business_model": Question(
                id="business_model",
                text="What's your primary business model?",
                type=QuestionType.CHOICE,
                category="overview",
                options=["B2B SaaS", "B2C Subscription", "Marketplace", "Transaction-based", "Enterprise", "Freemium", "Other"]
            ),
            
            # Financial Metrics
            "arr": Question(
                id="arr",
                text="What is your current Annual Recurring Revenue (ARR)?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": 0}
            ),
            "mrr": Question(
                id="mrr",
                text="What is your current Monthly Recurring Revenue (MRR)?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": 0}
            ),
            "growth_rate": Question(
                id="growth_rate",
                text="What is your year-over-year revenue growth rate (as a percentage)?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": -100, "max": 1000}
            ),
            "gross_margin": Question(
                id="gross_margin",
                text="What is your gross margin percentage?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": 0, "max": 100}
            ),
            "burn_rate": Question(
                id="burn_rate",
                text="What is your monthly burn rate?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": 0}
            ),
            "runway": Question(
                id="runway",
                text="How many months of runway do you have?",
                type=QuestionType.NUMBER,
                category="financials",
                validation={"min": 0, "max": 120}
            ),
            
            # Additional Company Details for UI
            "company_description": Question(
                id="company_description",
                text="Describe your company in one sentence",
                type=QuestionType.TEXT,
                category="overview"
            ),
            "headquarters": Question(
                id="headquarters",
                text="Where is your headquarters? (City, Country)",
                type=QuestionType.TEXT,
                category="overview"
            ),
            "target_markets": Question(
                id="target_markets",
                text="What are your target markets? (comma-separated)",
                type=QuestionType.TEXT,
                category="overview"
            ),
            
            # Customer Metrics
            "total_customers": Question(
                id="total_customers",
                text="How many paying customers do you have?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0}
            ),
            "fortune_500_customers": Question(
                id="fortune_500_customers",
                text="How many Fortune 500 customers do you have?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0}
            ),
            "churn_rate": Question(
                id="churn_rate",
                text="What is your monthly churn rate (percentage)?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0, "max": 100}
            ),
            "logo_retention": Question(
                id="logo_retention",
                text="What is your annual logo retention rate (percentage)?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0, "max": 100}
            ),
            "nrr": Question(
                id="nrr",
                text="What is your Net Revenue Retention (NRR) percentage?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0, "max": 300}
            ),
            "cac": Question(
                id="cac",
                text="What is your Customer Acquisition Cost (CAC)?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0}
            ),
            "ltv": Question(
                id="ltv",
                text="What is your customer Lifetime Value (LTV)?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0}
            ),
            "customer_concentration": Question(
                id="customer_concentration",
                text="What percentage of revenue comes from your top 10 customers?",
                type=QuestionType.NUMBER,
                category="customers",
                validation={"min": 0, "max": 100}
            ),
            
            # Team & Founders - ESSENTIAL FOR UI
            "team_size": Question(
                id="team_size",
                text="How many full-time employees do you have?",
                type=QuestionType.NUMBER,
                category="team",
                validation={"min": 1}
            ),
            "founder_names": Question(
                id="founder_names",
                text="List founder names and roles (e.g., 'John Doe - CEO, Jane Smith - CTO')",
                type=QuestionType.TEXT,
                category="team"
            ),
            "founder_experience": Question(
                id="founder_experience",
                text="Do founders have prior exit experience? (Yes/No)",
                type=QuestionType.CHOICE,
                category="team",
                options=["Yes", "No"]
            ),
            "team_from_faang": Question(
                id="team_from_faang",
                text="How many team members are from FAANG/top tech companies?",
                type=QuestionType.NUMBER,
                category="team",
                validation={"min": 0}
            ),
            "technical_team": Question(
                id="technical_team",
                text="What percentage of your team is technical/engineering?",
                type=QuestionType.NUMBER,
                category="team",
                validation={"min": 0, "max": 100}
            ),
            
            # Funding & Investment - ESSENTIAL FOR UI
            "funding_stage": Question(
                id="funding_stage",
                text="What is your current funding stage?",
                type=QuestionType.CHOICE,
                category="funding",
                options=["Pre-seed", "Seed", "Series A", "Series B", "Series C+", "Bootstrapped"]
            ),
            "total_raised": Question(
                id="total_raised",
                text="Total funding raised to date (in USD)?",
                type=QuestionType.NUMBER,
                category="funding",
                validation={"min": 0}
            ),
            "last_valuation": Question(
                id="last_valuation",
                text="Last valuation (in USD)?",
                type=QuestionType.NUMBER,
                category="funding",
                validation={"min": 0}
            ),
            "current_ask": Question(
                id="current_ask",
                text="How much are you raising now (in USD)?",
                type=QuestionType.NUMBER,
                category="funding",
                validation={"min": 0}
            ),
            "target_valuation": Question(
                id="target_valuation",
                text="Target valuation for this round (in USD)?",
                type=QuestionType.NUMBER,
                category="funding",
                validation={"min": 0}
            ),
            "use_of_funds": Question(
                id="use_of_funds",
                text="Primary use of funds (e.g., '50% marketing, 30% product, 20% hiring')",
                type=QuestionType.TEXT,
                category="funding"
            ),
            "exit_strategy": Question(
                id="exit_strategy",
                text="Exit strategy (e.g., 'IPO in 5 years' or 'Acquisition by enterprise player')",
                type=QuestionType.TEXT,
                category="funding"
            ),
            "investor_names": Question(
                id="investor_names",
                text="Current investors (comma-separated, e.g., 'Y Combinator, Sequoia Capital')",
                type=QuestionType.TEXT,
                category="funding"
            ),
            
            # Product & Market
            "product_stage": Question(
                id="product_stage",
                text="What stage is your product in?",
                type=QuestionType.CHOICE,
                category="product",
                options=["Idea", "MVP", "Beta", "Launched", "Growing", "Scaling"]
            ),
            "competitive_advantage": Question(
                id="competitive_advantage",
                text="What is your main competitive advantage?",
                type=QuestionType.TEXT,
                category="product",
                required=False
            ),
            "tam": Question(
                id="tam",
                text="What is your Total Addressable Market (TAM) in dollars?",
                type=QuestionType.NUMBER,
                category="market",
                validation={"min": 0}
            ),
            
            # Fundraising
            "previous_funding": Question(
                id="previous_funding",
                text="How much funding have you raised to date?",
                type=QuestionType.NUMBER,
                category="fundraising",
                validation={"min": 0}
            ),
            "current_round": Question(
                id="current_round",
                text="How much are you raising in this round?",
                type=QuestionType.NUMBER,
                category="fundraising",
                validation={"min": 0}
            ),
            "valuation": Question(
                id="valuation",
                text="What is your target valuation?",
                type=QuestionType.NUMBER,
                category="fundraising",
                validation={"min": 0},
                required=False
            ),
            
            # Additional Context
            "pitch_deck_url": Question(
                id="pitch_deck_url",
                text="Do you have a pitch deck URL to share? (optional)",
                type=QuestionType.URL,
                category="documents",
                required=False
            ),
            "financial_model_url": Question(
                id="financial_model_url",
                text="Do you have a financial model to share? (optional)",
                type=QuestionType.URL,
                category="documents",
                required=False
            )
        }
        
        return questions
    
    def get_questions_by_category(self, category: str) -> List[Question]:
        """Get all questions for a category.
        
        Args:
            category: Question category
            
        Returns:
            List of questions
        """
        return [q for q in self.questions.values() if q.category == category]
    
    def get_next_question(
        self,
        answered: Dict[str, Any],
        category: Optional[str] = None
    ) -> Optional[Question]:
        """Get next unanswered question based on flow logic.
        
        Args:
            answered: Already answered questions
            category: Optional category filter
            
        Returns:
            Next question or None if complete
        """
        for question in self.questions.values():
            # Skip if already answered
            if question.id in answered:
                continue
            
            # Check category filter
            if category and question.category != category:
                continue
            
            # Check dependencies
            if question.depends_on:
                dep_id, dep_value = question.depends_on
                if dep_id not in answered or answered[dep_id] != dep_value:
                    continue
            
            return question
        
        return None
    
    def validate_answer(self, question: Question, answer: Any) -> Tuple[bool, str]:
        """Validate answer for a question.
        
        Args:
            question: Question being answered
            answer: Provided answer
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Type validation
        if question.type == QuestionType.NUMBER:
            try:
                value = float(answer)
                if question.validation:
                    if "min" in question.validation and value < question.validation["min"]:
                        return False, f"Value must be at least {question.validation['min']}"
                    if "max" in question.validation and value > question.validation["max"]:
                        return False, f"Value must be at most {question.validation['max']}"
            except (ValueError, TypeError):
                return False, "Please enter a valid number"
        
        elif question.type == QuestionType.CHOICE:
            if question.options and answer not in question.options:
                return False, f"Please select one of: {', '.join(question.options)}"
        
        elif question.type == QuestionType.YES_NO:
            if str(answer).lower() not in ["yes", "no", "true", "false"]:
                return False, "Please answer yes or no"
        
        elif question.type == QuestionType.URL:
            if answer and not (answer.startswith("http://") or answer.startswith("https://")):
                return False, "Please enter a valid URL"
        
        return True, ""
    
    def convert_to_chunks(
        self,
        startup_id: str,
        responses: Dict[str, Any]
    ) -> List[DocumentChunk]:
        """Convert questionnaire responses to document chunks for RAG.
        
        Args:
            startup_id: Startup identifier
            responses: Question responses
            
        Returns:
            List of document chunks
        """
        chunks = []
        
        # Group by category
        categories = {}
        for q_id, answer in responses.items():
            if q_id in self.questions:
                question = self.questions[q_id]
                if question.category not in categories:
                    categories[question.category] = []
                categories[question.category].append((question, answer))
        
        # Create chunks per category
        chunk_id = 0
        for category, qa_pairs in categories.items():
            # Build narrative text
            text_parts = [f"# {category.title()} Information\n"]
            
            for question, answer in qa_pairs:
                # Format based on type
                if question.type == QuestionType.NUMBER:
                    try:
                        numeric_answer = float(answer)
                        if "rate" in question.id or "margin" in question.id:
                            text_parts.append(f"{question.text} {answer}%")
                        elif "arr" in question.id or "mrr" in question.id or "cac" in question.id:
                            text_parts.append(f"{question.text} ${numeric_answer:,.0f}")
                        else:
                            text_parts.append(f"{question.text} {answer}")
                    except (ValueError, TypeError):
                        text_parts.append(f"{question.text} {answer}")
                else:
                    text_parts.append(f"{question.text} {answer}")
            
            chunk_text = "\n".join(text_parts)
            
            chunk = DocumentChunk(
                id=f"questionnaire-{startup_id}-{chunk_id:04d}",
                startup_id=startup_id,
                type=DocumentType.TEXT,
                source="questionnaire",
                text=chunk_text,
                metadata={
                    "category": category,
                    "source_type": "questionnaire",
                    "questions_answered": len(qa_pairs)
                }
            )
            chunks.append(chunk)
            chunk_id += 1
        
        return chunks
    
    async def generate_summary(
        self,
        responses: Dict[str, Any]
    ) -> str:
        """Generate executive summary from questionnaire responses.
        
        Args:
            responses: Question responses
            
        Returns:
            Executive summary
        """
        # Build context
        context = "Company Information:\n"
        for q_id, answer in responses.items():
            if q_id in self.questions:
                question = self.questions[q_id]
                context += f"- {question.text} {answer}\n"
        
        prompt = f"""
        Based on the following information provided via questionnaire, 
        write a 3-sentence executive summary of this startup:
        
        {context}
        
        Focus on: 1) What the company does, 2) Key traction metrics, 3) Investment opportunity.
        """
        
        if self.generator.model:
            response = await self.generator._generate(prompt, temperature=0.3)
            return response
        else:
            # Mock response
            return "This startup operates in the SaaS space with strong unit economics and impressive growth metrics."
    
    def responses_to_chunks(self, startup_id: str, responses: Dict[str, Any]) -> List:
        """Convert questionnaire responses to searchable chunks."""
        from ..models.dto import Chunk
        chunks = []
        
        # Group responses by category
        categories = {}
        for key, value in responses.items():
            question = self.questions.get(key)
            if question:
                category = question.category
                if category not in categories:
                    categories[category] = []
                categories[category].append(f"{question.text}: {value}")
        
        # Create chunks for each category
        for category, items in categories.items():
            content = "\n".join(items)
            chunk = Chunk(
                chunk_id=f"{startup_id}_questionnaire_{category}",
                content=content,
                metadata={
                    "source": "questionnaire",
                    "category": category,
                    "startup_id": startup_id
                },
                embedding=[]  # Will be generated by embedding service
            )
            chunks.append(chunk)
        
        # Also create one comprehensive chunk
        all_content = "\n\n".join([f"{k}: {v}" for k, v in responses.items()])
        chunks.append(Chunk(
            chunk_id=f"{startup_id}_questionnaire_all",
            content=all_content,
            metadata={
                "source": "questionnaire",
                "category": "all",
                "startup_id": startup_id
            },
            embedding=[]
        ))
        
        return chunks
