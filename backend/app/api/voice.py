"""Voice agent API - AI Founder Meeting (Round1-style)."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException
from typing import Dict, Any, List
import asyncio
import base64
import json
from datetime import datetime
import uuid

from ..core.security import verify_api_key
from ..core.logging import get_logger
from ..core.config import get_settings
from ..services.database import get_database_service

logger = get_logger(__name__)
router = APIRouter()
settings = get_settings()

# Active voice sessions
_voice_sessions: Dict[str, Dict[str, Any]] = {}


class VoiceAgent:
    """Real-time voice agent using Google Cloud services."""
    
    def __init__(self, startup_id: str, session_id: str):
        """Initialize voice agent.
        
        Args:
            startup_id: Startup being interviewed
            session_id: Unique session ID
        """
        self.startup_id = startup_id
        self.session_id = session_id
        self.conversation_history = []
        self.transcript = []
        
        # Initialize Google Cloud clients
        self.stt_client = None
        self.tts_client = None
        self.gemini_client = None
        
        # Conversation state
        self.turn_count = 0
        self.max_turns = 10  # Limit turns for demo
        
    async def initialize(self):
        """Initialize Google Cloud services."""
        from google.cloud import speech_v2 as speech
        from google.cloud import texttospeech
        import google.generativeai as genai
        
        # STT client
        self.stt_client = speech.SpeechAsyncClient()
        
        # TTS client
        self.tts_client = texttospeech.TextToSpeechAsyncClient()
        
        # Gemini client
        genai.configure(api_key=settings.GEMINI_API_KEY)
        self.gemini_client = genai.GenerativeModel("gemini-2.5-pro")  # Using Gemini 2.5 Pro for better voice Q&A
        
        # Load startup context
        db = get_database_service()
        startup_data = db.get_startup(self.startup_id)
        
        if startup_data:
            responses = startup_data.get("questionnaire_responses", {})
            company_name = responses.get("company_name", "the startup")
            
            # System prompt for investor interview
            system_prompt = f"""You are an experienced venture capital investor conducting a pitch meeting with {company_name}.

Your goal: Evaluate the startup through a conversational interview, asking insightful questions about:
- The problem they're solving and why now
- Their solution and competitive advantage
- Business model and go-to-market strategy
- Team background and expertise
- Traction, metrics, and growth
- Funding needs and use of capital

Be professional but friendly. Ask follow-up questions. Keep responses concise (2-3 sentences max).
After {self.max_turns} exchanges, provide a brief investment recommendation.

Company context:
{json.dumps(responses, indent=2)}

Start by warmly greeting the founder and asking them to introduce their company."""
            
            self.conversation_history.append({
                "role": "user",
                "parts": [system_prompt]
            })
        
        logger.info(f"Voice agent initialized for {self.startup_id}")
    
    async def transcribe_audio(self, audio_chunk: bytes) -> str:
        """Transcribe audio using Speech-to-Text v2.
        
        Args:
            audio_chunk: PCM audio bytes
            
        Returns:
            Transcribed text
        """
        from google.cloud.speech_v2 import RecognitionConfig, RecognizeRequest
        
        try:
            config = RecognitionConfig(
                auto_decoding_config={},
                language_codes=["en-US"],
                model="latest_long",
            )
            
            request = RecognizeRequest(
                recognizer=f"projects/{settings.GOOGLE_PROJECT_ID}/locations/global/recognizers/_",
                config=config,
                content=audio_chunk,
            )
            
            response = await self.stt_client.recognize(request=request)
            
            # Extract transcript
            transcript = ""
            for result in response.results:
                transcript += result.alternatives[0].transcript
            
            return transcript.strip()
            
        except Exception as e:
            logger.error(f"STT error: {e}")
            return ""
    
    async def generate_response(self, user_text: str) -> str:
        """Generate response using Gemini 2.0 Flash.
        
        Args:
            user_text: User's transcribed speech
            
        Returns:
            AI response text
        """
        try:
            # Add user message
            self.conversation_history.append({
                "role": "user",
                "parts": [user_text]
            })
            
            # Generate response
            response = await self.gemini_client.generate_content_async(
                self.conversation_history,
                generation_config={
                    "temperature": 0.7,
                    "max_output_tokens": 200,  # Keep responses concise
                }
            )
            
            ai_text = response.text
            
            # Add to history
            self.conversation_history.append({
                "role": "model",
                "parts": [ai_text]
            })
            
            self.turn_count += 1
            
            # Save to transcript
            self.transcript.append({
                "timestamp": datetime.utcnow().isoformat(),
                "speaker": "founder",
                "text": user_text
            })
            self.transcript.append({
                "timestamp": datetime.utcnow().isoformat(),
                "speaker": "investor",
                "text": ai_text
            })
            
            return ai_text
            
        except Exception as e:
            logger.error(f"Gemini error: {e}")
            return "I'm sorry, could you repeat that?"
    
    async def synthesize_speech(self, text: str) -> bytes:
        """Synthesize speech using Text-to-Speech.
        
        Args:
            text: Text to synthesize
            
        Returns:
            Audio bytes (MP3)
        """
        from google.cloud import texttospeech
        
        try:
            synthesis_input = texttospeech.SynthesisInput(text=text)
            
            voice = texttospeech.VoiceSelectionParams(
                language_code="en-US",
                name="en-US-Neural2-J",  # Professional male voice
            )
            
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.MP3,
                speaking_rate=1.0,
                pitch=0.0,
            )
            
            request = texttospeech.SynthesizeSpeechRequest(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config,
            )
            
            response = await self.tts_client.synthesize_speech(request=request)
            
            return response.audio_content
            
        except Exception as e:
            logger.error(f"TTS error: {e}")
            return b""
    
    async def save_transcript(self):
        """Save conversation transcript to Firestore and GCS."""
        try:
            from google.cloud import storage
            
            # Save to Firestore
            db = get_database_service()
            transcript_doc = {
                "session_id": self.session_id,
                "startup_id": self.startup_id,
                "transcript": self.transcript,
                "turn_count": self.turn_count,
                "created_at": datetime.utcnow(),
            }
            
            # TODO: Add method to save transcripts to Firestore
            
            # Save to GCS
            if settings.GCP_BUCKET:
                storage_client = storage.Client()
                bucket = storage_client.bucket(settings.GCP_BUCKET)
                blob = bucket.blob(f"voice_transcripts/{self.startup_id}/{self.session_id}.json")
                blob.upload_from_string(
                    json.dumps(transcript_doc, default=str),
                    content_type="application/json"
                )
                
                logger.info(f"Transcript saved: {self.session_id}")
            
        except Exception as e:
            logger.error(f"Failed to save transcript: {e}")


@router.websocket("/voice/stream")
async def voice_stream(
    websocket: WebSocket,
    startup_id: str,
    api_key: str = None
):
    """WebSocket endpoint for real-time voice agent.
    
    Protocol:
        Client -> Server: {"type": "audio", "data": "<base64_audio>"}
        Server -> Client: {"type": "audio", "data": "<base64_audio>"}
        Server -> Client: {"type": "transcript", "speaker": "...", "text": "..."}
        Server -> Client: {"type": "status", "message": "..."}
    
    Args:
        websocket: WebSocket connection
        startup_id: Startup ID for context
        api_key: API key for auth (query param)
    """
    # Verify API key
    if api_key != settings.API_KEY:
        await websocket.close(code=1008, reason="Invalid API key")
        return
    
    # Accept connection
    await websocket.accept()
    
    # Create session
    session_id = str(uuid.uuid4())
    agent = VoiceAgent(startup_id, session_id)
    _voice_sessions[session_id] = {"agent": agent, "websocket": websocket}
    
    try:
        # Initialize agent
        await agent.initialize()
        
        # Send initial greeting
        await websocket.send_json({
            "type": "status",
            "message": "Connected. Voice agent ready."
        })
        
        # Generate and send opening from investor
        opening = await agent.generate_response("")  # Trigger system prompt
        audio_bytes = await agent.synthesize_speech(opening)
        
        await websocket.send_json({
            "type": "transcript",
            "speaker": "investor",
            "text": opening
        })
        
        await websocket.send_json({
            "type": "audio",
            "data": base64.b64encode(audio_bytes).decode("utf-8")
        })
        
        # Main loop - receive and process audio
        while True:
            try:
                # Receive message
                data = await websocket.receive_json()
                
                if data.get("type") == "audio":
                    # Decode audio
                    audio_chunk = base64.b64decode(data["data"])
                    
                    # Transcribe
                    await websocket.send_json({
                        "type": "status",
                        "message": "Transcribing..."
                    })
                    
                    user_text = await agent.transcribe_audio(audio_chunk)
                    
                    if not user_text:
                        continue
                    
                    # Send transcript
                    await websocket.send_json({
                        "type": "transcript",
                        "speaker": "founder",
                        "text": user_text
                    })
                    
                    # Generate response
                    await websocket.send_json({
                        "type": "status",
                        "message": "Thinking..."
                    })
                    
                    ai_text = await agent.generate_response(user_text)
                    
                    # Send AI transcript
                    await websocket.send_json({
                        "type": "transcript",
                        "speaker": "investor",
                        "text": ai_text
                    })
                    
                    # Synthesize and send audio
                    await websocket.send_json({
                        "type": "status",
                        "message": "Speaking..."
                    })
                    
                    audio_bytes = await agent.synthesize_speech(ai_text)
                    
                    await websocket.send_json({
                        "type": "audio",
                        "data": base64.b64encode(audio_bytes).decode("utf-8")
                    })
                    
                    # Check if interview is complete
                    if agent.turn_count >= agent.max_turns:
                        await websocket.send_json({
                            "type": "status",
                            "message": "Interview complete. Thank you!"
                        })
                        break
                
                elif data.get("type") == "end":
                    break
                
            except WebSocketDisconnect:
                break
            except Exception as e:
                logger.error(f"WebSocket error: {e}")
                await websocket.send_json({
                    "type": "error",
                    "message": str(e)
                })
        
    except Exception as e:
        logger.error(f"Voice stream error: {e}")
    
    finally:
        # Save transcript
        await agent.save_transcript()
        
        # Cleanup
        if session_id in _voice_sessions:
            del _voice_sessions[session_id]
        
        await websocket.close()


@router.get("/voice/sessions")
async def list_voice_sessions(
    startup_id: str = None,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """List voice interview sessions.
    
    Args:
        startup_id: Optional filter by startup
        api_key: API key
        
    Returns:
        List of sessions
    """
    # TODO: Query Firestore for saved transcripts
    return {
        "sessions": [],
        "active_sessions": len(_voice_sessions)
    }


@router.get("/voice/transcript/{session_id}")
async def get_voice_transcript(
    session_id: str,
    api_key: str = Depends(verify_api_key)
) -> Dict[str, Any]:
    """Get voice interview transcript.
    
    Args:
        session_id: Session ID
        api_key: API key
        
    Returns:
        Transcript data
    """
    # Check active sessions
    if session_id in _voice_sessions:
        agent = _voice_sessions[session_id]["agent"]
        return {
            "session_id": session_id,
            "startup_id": agent.startup_id,
            "transcript": agent.transcript,
            "turn_count": agent.turn_count,
            "status": "active"
        }
    
    # TODO: Query Firestore for saved transcript
    raise HTTPException(404, "Session not found")

