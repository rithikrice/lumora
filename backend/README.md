# Lumora Backend

Professional investment analysis platform powered by Google Cloud AI.

## 🚀 Production Deployment

**Live API:** https://analystai-backend-752741439479.us-central1.run.app

**API Documentation:** [PRODUCTION_API.md](./PRODUCTION_API.md)

**Swagger UI:** https://analystai-backend-752741439479.us-central1.run.app/docs

## Features

- **Investment Analysis**: AI-powered startup evaluation with scoring
- **Video Analysis**: Founder assessment using Google Cloud Video Intelligence with UI-ready metrics
- **RAG Q&A**: Intelligent question answering about startups
- **Neo4j Graph**: Relationship and network analysis
- **LangGraph Workflows**: Multi-agent analysis pipelines
- **Questionnaire System**: Comprehensive data collection
- **Real-time Dashboards**: Investment metrics and insights with video integration
- **Startup Directory**: Searchable and filterable startup listing
- **UI-Optimized APIs**: Pre-calculated metrics for direct frontend consumption

## Tech Stack

- **Framework**: FastAPI (Python 3.12)
- **AI/ML**: Google Gemini, Vertex AI
- **Video**: Google Cloud Video Intelligence API
- **Database**: SQLite, Neo4j
- **Vector Search**: FAISS
- **Cloud**: Google Cloud Platform

## Setup

### 1. Install Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

Create `.env` file:
```env
API_KEY=dev-secret
USE_VERTEX=true
GOOGLE_APPLICATION_CREDENTIALS=./analystai-credentials.json
GEMINI_API_KEY=your-gemini-api-key
GCP_PROJECT_ID=your-project-id
GCP_LOCATION=us-central1
```

### 3. Run Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## API Documentation

Base URL: `http://localhost:8080`
API Key: Include `X-API-Key: dev-secret` in headers

### 1. Health Check

```bash
curl -X GET "http://localhost:8080/health" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-09-20T12:00:00",
  "services": {
    "api": true,
    "vertex": true,
    "bigquery": false,
    "matching_engine": false
  }
}
```

### 2. Submit Questionnaire

```bash
curl -X POST "http://localhost:8080/v1/questionnaire/submit" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techcorp-123",
    "responses": {
      "company_name": "TechCorp AI",
      "arr": 5000000,
      "growth_rate": 150,
      "team_size": 25,
      "burn_rate": 300000,
      "runway": 24,
      "founder_names": "John Doe, Jane Smith"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "startup_id": "techcorp-123",
  "questions_answered": 7,
  "chunks_created": 3,
  "message": "Questionnaire submitted successfully. Ready for analysis."
}
```

### 3. Investment Analysis

```bash
curl -X POST "http://localhost:8080/v1/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techcorp-123",
    "persona": {
      "growth": 0.4,
      "unit_econ": 0.3,
      "founder": 0.3
    }
  }'
```

**Response:**
```json
{
  "startup_id": "techcorp-123",
  "executive_summary": [
    "Strong growth trajectory with 150% YoY growth",
    "Solid unit economics with 24 months runway"
  ],
  "investment_score": 78.5,
  "recommendation": "invest",
  "kpis": {
    "arr": 5000000,
    "growth_rate": 150,
    "burn_rate": 300000,
    "runway_months": 24
  },
  "risks": [
    {
      "risk": "High burn rate",
      "severity": 3,
      "mitigation": "Focus on efficiency improvements"
    }
  ]
}
```

### 4. Video Analysis (Enhanced with UI Metrics)

#### USE CAN USE SAMPLE VIDEO PROVIDED OR ANY VIDEO WITH SIZE<10 MB

```bash
# Upload video (auto-analysis for videos < 10MB)
curl -X POST "http://localhost:8080/v1/video/upload" \
  -H "X-API-Key: dev-secret" \
  -F "startup_id=techcorp-123" \
  -F "file=@pitch_video.mp4"
```

**Response:**
```json
{
  "video_id": "techcorp-123-video-12345",
  "startup_id": "techcorp-123",
  "filename": "pitch_video.mp4",
  "size_mb": 8.5,
  "analysis": {
    "processed_with": "Google Cloud Video Intelligence API (REAL)",
    "transcript": "We're building the future of AI-powered analytics...",
    "founder_analysis": {
      "confidence_score": 0.85,
      "communication_clarity": 0.82,
      "technical_depth": 0.78,
      "passion_score": 0.91
    },
    "investment_signals": {
      "founder_quality": 0.84,
      "recommended_action": "invest",
      "key_strengths": ["Clear vision", "Domain expertise"]
    },
    "ui_metrics": {
      "founder_score": 85,
      "communication_grade": "B+",
      "passion_level": "High",
      "recommendation": {
        "action": "INVEST",
        "priority": "high",
        "confidence": 84
      },
      "scores": {
        "confidence": 85,
        "clarity": 82,
        "passion": 91,
        "authenticity": 88,
        "technical_depth": 78
      },
      "status": {
        "overall": "Excellent",
        "ready_for_pitch": true,
        "needs_coaching": false
      }
    }
  }
}
```

**Get Cached Analysis:**
```bash
curl -X POST "http://localhost:8080/v1/video/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"video_id": "techcorp-123-video-12345"}'
```

### 5. Q&A System

```bash
curl -X POST "http://localhost:8080/v1/ask" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techcorp-123",
    "question": "What is the current ARR and growth rate?"
  }'
```

**Response:**
```json
{
  "startup_id": "techcorp-123",
  "question": "What is the current ARR and growth rate?",
  "answer": [
    "The current Annual Recurring Revenue is $5,000,000 with a growth rate of 150% year-over-year."
  ],
  "sources": [
    {
      "id": "techcorp-123_arr_qa",
      "type": "slide",
      "location": "questionnaire",
      "snippet": "Annual Recurring Revenue: $5,000,000"
    }
  ]
}
```

### 6. Neo4j Graph Analysis

```bash
curl -X POST "http://localhost:8080/v1/advanced/graph/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"startup_id": "techcorp-123"}'
```

**Response:**
```json
{
  "startup_id": "techcorp-123",
  "similar_startups": [],
  "market_position": "Emerging Leader",
  "network_effects": {
    "customer_concentration": 0.3,
    "market_penetration": 0.15
  },
  "relationships": []
}
```

### 7. Dashboard Data (Now includes video_id)

```bash
curl -X GET "http://localhost:8080/v1/ui/dashboard/techcorp-123" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
{
  "company_profile": {
    "name": "TechCorp AI",
    "description": "AI-powered analytics platform",
    "industry": "Technology",
    "stage": "Series A",
    "revenue": "$5.0M ARR",
    "team_size": 45
  },
  "score": 78.5,
  "recommendation": "invest",
  "video_id": "techcorp-123-video-12345",
  "kpi_benchmarks": {
    "arr": {
      "value": "$5.0M",
      "benchmark": "40% QoQ",
      "status": "above"
    },
    "growth_rate": {
      "value": "150%",
      "benchmark": "Industry avg: 120%",
      "status": "excellent"
    }
  },
  "executive_summary": [
    "Strong technical team with proven track record",
    "Solid product-market fit with growing customer base"
  ],
  "ai_insights": [
    {
      "type": "behavioral",
      "title": "Founder Behavioral Fingerprint",
      "score": 0.85
    }
  ]
}
```

### 8. Portfolio View

```bash
curl -X POST "http://localhost:8080/v1/ui/portfolio" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"startup_ids": ["techcorp-123"]}'
```

**Response:**
```json
{
  "portfolio": [
    {
      "startup_id": "techcorp-123",
      "name": "TechCorp AI",
      "score": 78.5,
      "status": "active",
      "metrics": {
        "arr": 5000000,
        "growth": 150
      }
    }
  ],
  "total_value": 5000000,
  "avg_score": 78.5
}
```

### 9. Export Report

```bash
curl -X POST "http://localhost:8080/v1/export/gdoc" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"startup_id": "techcorp-123"}'
```

**Response:**
```json
{
  "doc_url": "https://docs.google.com/document/d/...",
  "doc_id": "1234567890",
  "message": "Report exported successfully"
}
```

### 10. Startup Directory

```bash
curl -X GET "http://localhost:8080/v1/ui/startup-directory" \
  -H "X-API-Key: dev-secret"
```

**With Filters:**
```bash
curl -X GET "http://localhost:8080/v1/ui/startup-directory?sector=Fintech&geography=USA&limit=10" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
{
  "startups": [
    {
      "startup_id": "stellarpay-demo",
      "name": "StellarPay",
      "sector": "Fintech",
      "geography": "Singapore",
      "funding_stage": "Series A",
      "score": 70,
      "arr": 12000000,
      "growth_rate": 150,
      "team_size": 45,
      "description": "B2B SaaS",
      "website": "https://stellarpay.com",
      "logo": "https://ui-avatars.com/api/?name=StellarPay&background=random"
    }
  ],
  "total_count": 10,
  "sectors": ["Fintech", "Technology", "HealthTech"],
  "geographies": ["USA", "Singapore", "UK"],
  "funding_stages": ["Seed", "Series A", "Series B"],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "has_more": false
  }
}
```

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   FastAPI   │────▶│   Services   │────▶│ Google Cloud │
│   Endpoints │     │   (Business  │     │     APIs     │
│             │     │    Logic)    │     │              │
└─────────────┘     └──────────────┘     └──────────────┘
       │                   │                      │
       ▼                   ▼                      ▼
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Pydantic  │     │   Database   │     │    Gemini    │
│   Models    │     │   (SQLite)   │     │   Vertex AI  │
└─────────────┘     └──────────────┘     └──────────────┘
```

## Deployment

### Docker

```bash
docker build -t analystai-backend .
docker run -p 8080:8080 --env-file .env analystai-backend
```

### Google Cloud Run

```bash
gcloud run deploy analystai-backend \
  --source . \
  --port 8080 \
  --region us-central1 \
  --allow-unauthenticated
```

## Testing

```bash
# Run tests
pytest tests/

# Check API health
curl http://localhost:8080/health -H "X-API-Key: dev-secret"
```

## License

Proprietary - All rights reserved