"""Questionnaire API endpoints for interactive data collection."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

from ..core.security import verify_api_key
from ..core.logging import get_logger, log_api_call
from ..services.questionnaire import InvestmentQuestionnaire, QuestionType
from ..services.database import DatabaseService
from ..services.retrieval import HybridRetriever
from ..models.dto import AnalyzeRequest

router = APIRouter()
logger = get_logger(__name__)
questionnaire_service = InvestmentQuestionnaire()
db_service = DatabaseService()


class QuestionResponse(BaseModel):
    """Response model for a question."""
    question_id: str
    text: str
    type: str
    category: str
    required: bool
    options: Optional[List[str]] = None
    validation: Optional[Dict[str, Any]] = None


class AnswerRequest(BaseModel):
    """Request model for submitting an answer."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    question_id: str
    answer: Any


class AnswerResponse(BaseModel):
    """Response model for answer submission."""
    success: bool
    next_question: Optional[QuestionResponse] = None
    progress: float = Field(..., description="Completion percentage")
    message: str


class QuestionnaireStartRequest(BaseModel):
    """Request to start questionnaire."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    category: Optional[str] = None


class QuestionnaireSubmitRequest(BaseModel):
    """Request to submit complete questionnaire responses."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    responses: Dict[str, Any] = Field(..., description="All questionnaire responses")


class QuestionnaireCompleteRequest(BaseModel):
    """Request to complete questionnaire and run analysis."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    run_analysis: bool = True


class BulkAnswersRequest(BaseModel):
    """Request for submitting multiple answers at once."""
    startup_id: str = Field(..., min_length=1, max_length=100)
    answers: Dict[str, Any]


@router.post("/questionnaire/submit")
async def submit_questionnaire(
    request: QuestionnaireSubmitRequest,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """
    Submit complete questionnaire responses at once.
    This is the main endpoint for UI to submit all data.
    """
    log_api_call(
        "questionnaire_submit",
        {"startup_id": request.startup_id, "response_count": len(request.responses)}
    )
    
    try:
        # Save responses to database
        success = db_service.save_questionnaire_response(
            request.startup_id,
            request.responses
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save questionnaire responses"
            )
        
        # Convert to chunks for retrieval
        chunks = questionnaire_service.responses_to_chunks(
            request.startup_id,
            request.responses
        )
        
        # Store chunks for later retrieval
        from ..services.chunk_store import store_chunks
        store_chunks(request.startup_id, chunks)
        
        logger.info(
            f"Questionnaire submitted for {request.startup_id}",
            extra={
                "startup_id": request.startup_id,
                "response_count": len(request.responses),
                "chunk_count": len(chunks)
            }
        )
        
        return {
            "success": True,
            "startup_id": request.startup_id,
            "questions_answered": len(request.responses),
            "chunks_created": len(chunks),
            "message": "Questionnaire submitted successfully. Ready for analysis."
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to submit questionnaire: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit questionnaire: {str(e)}"
        )


@router.post("/questionnaire/start", response_model=QuestionResponse)
async def start_questionnaire(
    request: QuestionnaireStartRequest,
    api_key: str = Depends(verify_api_key)
) -> QuestionResponse:
    """Start questionnaire flow and get first question.
    
    Args:
        request: Start request
        api_key: API key for authentication
        
    Returns:
        First question
    """
    log_api_call("/questionnaire/start", "POST", startup_id=request.startup_id)
    
    # Get first question
    question = questionnaire_service.get_next_question({}, request.category)
    
    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No questions available"
        )
    
    return QuestionResponse(
        question_id=question.id,
        text=question.text,
        type=question.type.value,
        category=question.category,
        required=question.required,
        options=question.options,
        validation=question.validation
    )


@router.post("/questionnaire/answer", response_model=AnswerResponse)
async def submit_answer(
    request: AnswerRequest,
    api_key: str = Depends(verify_api_key)
) -> AnswerResponse:
    """Submit answer and get next question.
    
    Args:
        request: Answer submission
        api_key: API key for authentication
        
    Returns:
        Response with next question
    """
    log_api_call("/questionnaire/answer", "POST", 
                startup_id=request.startup_id,
                question_id=request.question_id)
    
    # Validate answer
    if request.question_id not in questionnaire_service.questions:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )
    
    question = questionnaire_service.questions[request.question_id]
    is_valid, error_msg = questionnaire_service.validate_answer(question, request.answer)
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=error_msg
        )
    
    # Save to database
    db_service.save_single_questionnaire_response(
        startup_id=request.startup_id,
        question_id=request.question_id,
        question=question.text,
        answer=str(request.answer),
        confidence=1.0
    )
    
    # Get answered questions for progress
    answered = db_service.get_questionnaire_responses(request.startup_id)
    answered_ids = {r["question_id"] for r in answered}
    
    # Also save aggregated responses to startup record
    # This makes data immediately available for grounding API
    answers_dict = {r["question_id"]: r["answer"] for r in answered}
    db_service.save_questionnaire_response(
        startup_id=request.startup_id,
        responses=answers_dict
    )
    
    # Get next question
    answered_dict = {r["question_id"]: r["answer"] for r in answered}
    next_question = questionnaire_service.get_next_question(answered_dict)
    
    # Calculate progress
    total_questions = len(questionnaire_service.questions)
    progress = (len(answered_ids) / total_questions) * 100
    
    response = AnswerResponse(
        success=True,
        progress=progress,
        message=f"Answer saved. Progress: {progress:.1f}%"
    )
    
    if next_question:
        response.next_question = QuestionResponse(
            question_id=next_question.id,
            text=next_question.text,
            type=next_question.type.value,
            category=next_question.category,
            required=next_question.required,
            options=next_question.options,
            validation=next_question.validation
        )
    
    return response


@router.post("/questionnaire/bulk", response_model=Dict[str, Any])
async def submit_bulk_answers(
    request: BulkAnswersRequest,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Submit multiple answers at once.
    
    Args:
        request: Bulk answers
        api_key: API key for authentication
        
    Returns:
        Processing result
    """
    log_api_call("/questionnaire/bulk", "POST", startup_id=request.startup_id)
    
    results = {}
    errors = {}
    
    for question_id, answer in request.answers.items():
        if question_id not in questionnaire_service.questions:
            errors[question_id] = "Question not found"
            continue
        
        question = questionnaire_service.questions[question_id]
        is_valid, error_msg = questionnaire_service.validate_answer(question, answer)
        
        if not is_valid:
            errors[question_id] = error_msg
        else:
            db_service.save_questionnaire_response(
                startup_id=request.startup_id,
                question_id=question_id,
                question=question.text,
                answer=str(answer),
                confidence=1.0
            )
            results[question_id] = "Saved"
    
    # Convert to chunks for RAG
    if results:
        chunks = questionnaire_service.convert_to_chunks(
            request.startup_id,
            request.answers
        )
        
        # Index chunks for retrieval
        if chunks:
            retriever = HybridRetriever(request.startup_id)
            await retriever.index_documents(chunks)
    
    return {
        "success": len(results) > 0,
        "saved": results,
        "errors": errors,
        "total_saved": len(results),
        "total_errors": len(errors)
    }


@router.get("/questionnaire/progress/{startup_id}")
async def get_progress(
    startup_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get questionnaire progress for a startup.
    
    Args:
        startup_id: Startup identifier
        api_key: API key for authentication
        
    Returns:
        Progress information
    """
    log_api_call("/questionnaire/progress", "GET", startup_id=startup_id)
    
    # Get answered questions
    answered = db_service.get_questionnaire_responses(startup_id)
    answered_ids = {r["question_id"] for r in answered}
    
    # Calculate progress by category
    categories = {}
    for question in questionnaire_service.questions.values():
        if question.category not in categories:
            categories[question.category] = {"total": 0, "answered": 0}
        categories[question.category]["total"] += 1
        if question.id in answered_ids:
            categories[question.category]["answered"] += 1
    
    # Calculate overall progress
    total_questions = len(questionnaire_service.questions)
    overall_progress = (len(answered_ids) / total_questions) * 100 if total_questions > 0 else 0
    
    return {
        "startup_id": startup_id,
        "overall_progress": overall_progress,
        "questions_answered": len(answered_ids),
        "total_questions": total_questions,
        "category_progress": categories,
        "answered": [{"question_id": r["question_id"], "answer": r["answer"]} for r in answered]
    }


@router.post("/questionnaire/complete")
async def complete_questionnaire(
    request: QuestionnaireCompleteRequest,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Complete questionnaire and optionally run analysis.
    
    Args:
        request: Completion request
        api_key: API key for authentication
        
    Returns:
        Completion status and analysis results
    """
    log_api_call("/questionnaire/complete", "POST", startup_id=request.startup_id)
    
    # Get all responses
    responses = db_service.get_questionnaire_responses(request.startup_id)
    
    if not responses:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No questionnaire responses found"
        )
    
    # Convert to dictionary
    answers = {r["question_id"]: r["answer"] for r in responses}
    
    # Save aggregated responses to startup record
    # This makes them accessible to the grounding API
    db_service.save_questionnaire_response(
        startup_id=request.startup_id,
        responses=answers
    )
    
    logger.info(f"Saved {len(answers)} questionnaire responses for {request.startup_id}")
    
    # Generate summary
    summary = await questionnaire_service.generate_summary(answers)
    
    # Convert to chunks
    chunks = questionnaire_service.convert_to_chunks(request.startup_id, answers)
    
    # Index chunks
    if chunks:
        retriever = HybridRetriever(request.startup_id)
        await retriever.index_documents(chunks)
    
    result = {
        "success": True,
        "startup_id": request.startup_id,
        "summary": summary,
        "chunks_created": len(chunks),
        "data_method": "questionnaire"
    }
    
    # Run analysis if requested
    if request.run_analysis:
        from ..api.analyze import analyze_startup
        
        try:
            analysis_req = AnalyzeRequest(
                startup_id=request.startup_id,
                persona={}  # Use default weights
            )
            analysis = await analyze_startup(analysis_req, api_key)
            result["analysis"] = {
                "recommendation": analysis.recommendation.value,
                "score": analysis.score,
                "summary": analysis.executive_summary[:3]  # First 3 lines
            }
        except Exception as e:
            logger.error(f"Analysis failed: {str(e)}")
            result["analysis_error"] = str(e)
    
    return result


@router.get("/questionnaire/questions")
async def list_all_questions(
    category: Optional[str] = None,
    api_key: str = Depends(verify_api_key)
) -> List[QuestionResponse]:
    """List all available questions.
    
    Args:
        category: Optional category filter
        api_key: API key for authentication
        
    Returns:
        List of questions
    """
    questions = questionnaire_service.questions.values()
    
    if category:
        questions = [q for q in questions if q.category == category]
    
    return [
        QuestionResponse(
            question_id=q.id,
            text=q.text,
            type=q.type.value,
            category=q.category,
            required=q.required,
            options=q.options,
            validation=q.validation
        )
        for q in questions
    ]
