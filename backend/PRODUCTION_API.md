# Lumora Production API Documentation

## 🚀 Production Endpoint
**Base URL:** `https://analystai-backend-752741439479.us-central1.run.app`

## 🆕 Latest Updates
- **Video APIs Enhanced**: Now include `ui_metrics` for direct Flutter consumption
- **Dashboard API**: Now returns `video_id` for video integration
- **Startup Directory**: New API for listing and filtering startups
- **Cached Analysis**: Video analysis results are cached for performance
- **UI-Ready Metrics**: Pre-calculated scores, grades, and status indicators

## 🔐 Authentication
All API endpoints require an API key in the header:
```
X-API-Key: dev-secret
```

---

## 📋 API Endpoints

### 1. Health Check
**Endpoint:** `GET /health/`  
**Description:** Check if the service is running

**Request:**
```bash
curl -X GET "https://analystai-backend-752741439479.us-central1.run.app/health/"
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-09-20T14:30:00.000000",
  "services": {
    "api": true,
    "vertex": false,
    "bigquery": false,
    "matching_engine": false
  }
}
```

---

### 2. Get Questionnaire Questions
**Endpoint:** `GET /v1/questionnaire/questions`  
**Description:** Get all questionnaire questions

**Request:**
```bash
curl -X GET "https://analystai-backend-752741439479.us-central1.run.app/v1/questionnaire/questions" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
[
  {
    "id": "company_name",
    "text": "What is your company name?",
    "type": "text",
    "category": "Company Overview",
    "required": true,
    "placeholder": "Enter company name"
  },
  {
    "id": "arr",
    "text": "What is your current Annual Recurring Revenue (ARR)?",
    "type": "number",
    "category": "Financial Metrics",
    "required": true,
    "placeholder": "Enter ARR in USD"
  }
  // ... more questions
]
```

---

### 3. Submit Questionnaire
**Endpoint:** `POST /v1/questionnaire/submit`  
**Description:** Submit all questionnaire responses

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/questionnaire/submit" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123",
    "responses": {
      "company_name": "TechCorp AI",
      "company_description": "AI-powered analytics platform",
      "arr": 5000000,
      "growth_rate": 150,
      "burn_rate": 200000,
      "runway": 24,
      "team_size": 45,
      "customers": 120,
      "total_raised": 10000000,
      "current_ask": 20000000,
      "founder_names": "John Doe, Jane Smith",
      "target_markets": "Enterprise B2B SaaS",
      "main_challenges": "Scaling sales team, enterprise adoption",
      "product_description": "Real-time analytics dashboard",
      "technology_stack": "Python, React, AWS, PostgreSQL"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "startup_id": "startup-123",
  "questions_answered": 15,
  "chunks_created": 5,
  "message": "Questionnaire submitted successfully. Ready for analysis."
}
```

---

### 4. Analyze Startup
**Endpoint:** `POST /v1/analyze`  
**Description:** Perform comprehensive investment analysis

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123",
    "include_peers": true,
    "include_stress": true,
    "persona": {
      "risk_tolerance": 0.5,
      "growth_focus": 0.8,
      "revenue_focus": 0.6,
      "team_weight": 0.7
    }
  }'
```

**Response:**
```json
{
  "startup_id": "startup-123",
  "executive_summary": [
    "Strong revenue growth trajectory with 150% YoY growth",
    "Solid team of 45 employees with experienced founders",
    "24 months runway provides stability for scaling"
  ],
  "kpis": {
    "arr": 5000000,
    "growth_rate": 150,
    "burn_multiple": 0.4,
    "ltv_cac": 3.5,
    "gross_margin": 75,
    "rule_of_40": 125
  },
  "risks": [
    {
      "category": "Market",
      "severity": "Medium",
      "description": "Intense competition in enterprise analytics space",
      "mitigation": "Focus on unique AI capabilities and vertical specialization"
    }
  ],
  "recommendation": "invest",
  "score": 0.82,
  "investment_score": 82,
  "persona_scores": {
    "conservative": 0.75,
    "balanced": 0.82,
    "aggressive": 0.88
  },
  "peer_comparison": {
    "percentile": 75,
    "similar_companies": ["DataCo", "AnalyticsPro"],
    "relative_performance": "above_average"
  },
  "stress_test": {
    "scenarios": {
      "best_case": {"score": 0.92, "arr": 15000000},
      "base_case": {"score": 0.82, "arr": 8000000},
      "worst_case": {"score": 0.65, "arr": 3000000}
    }
  },
  "evidence": [
    {
      "id": "startup-123_arr",
      "type": "slide",
      "location": "questionnaire",
      "snippet": "Annual Recurring Revenue: $5,000,000",
      "confidence": 1.0
    }
  ],
  "timestamp": "2025-09-20T14:30:00.000000"
}
```

---

### 5. Ask Questions (Q&A)
**Endpoint:** `POST /v1/ask`  
**Description:** Ask specific questions about a startup

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/ask" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123",
    "question": "What is the current revenue growth rate and how does it compare to industry standards?"
  }'
```

**Response:**
```json
{
  "startup_id": "startup-123",
  "question": "What is the current revenue growth rate and how does it compare to industry standards?",
  "answer": "TechCorp AI is experiencing 150% year-over-year growth, which is significantly above the industry average of 40-60% for B2B SaaS companies at this stage. This exceptional growth rate indicates strong product-market fit and effective go-to-market strategy.",
  "sources": [
    {
      "id": "startup-123_growth",
      "type": "slide",
      "location": "questionnaire",
      "snippet": "Growth Rate: 150% year-over-year",
      "confidence": 1.0
    }
  ]
}
```

---

### 6. Generate Counterfactuals
**Endpoint:** `POST /v1/counterfactual`  
**Description:** Generate what-if scenarios

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/counterfactual" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123",
    "changes": {
      "arr": 8000000,
      "growth_rate": 200,
      "team_size": 60
    }
  }'
```

**Response:**
```json
{
  "startup_id": "startup-123",
  "original_score": 0.82,
  "new_score": 0.91,
  "impact": 0.09,
  "analysis": "Increasing ARR to $8M and growth rate to 200% would significantly improve the investment score by 9 points, moving the startup into the top tier of investment opportunities.",
  "key_improvements": [
    "Revenue milestone achievement increases institutional investor interest",
    "Hypergrowth rate demonstrates exceptional market demand",
    "Larger team size indicates scaling capability"
  ]
}
```

---

### 7. Upload Pitch Video
**Endpoint:** `POST /v1/video/upload`  
**Description:** Upload founder pitch video for analysis

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/video/upload" \
  -H "X-API-Key: dev-secret" \
  -F "startup_id=startup-123" \
  -F "file=@pitch_video.mp4"
```

**Response:**
```json
{
  "video_id": "startup-123-video-12345",
  "startup_id": "startup-123",
  "filename": "pitch_video.mp4",
  "size_mb": 8.5,
  "analysis": {
    "founder_analysis": {
      "confidence_score": 0.85,
      "communication_clarity": 0.90,
      "technical_depth": 0.78,
      "passion_score": 0.88,
      "authenticity": 0.82
    },
    "sentiment_analysis": {
      "overall_sentiment": "positive",
      "confidence": 0.85,
      "key_emotions": ["confident", "enthusiastic", "determined"]
    },
    "content_quality": {
      "problem_articulation": 0.82,
      "solution_clarity": 0.88,
      "market_understanding": 0.79
    },
    "investment_signals": {
      "founder_quality": 0.85,
      "recommended_action": "invest",
      "key_strengths": ["Clear vision", "Domain expertise", "Strong communication"],
      "concerns": ["Need more traction data", "Competition not fully addressed"]
    }
  },
  "transcript": "Our AI-powered platform transforms how enterprises analyze data...",
  "processed_with": "Google Cloud Video Intelligence API",
  "timestamp": "2025-09-20T14:30:00.000000"
}
```

---

### 8. Video Analysis Insights
**Endpoint:** `GET /v1/video/insights/{video_id}`  
**Description:** Get detailed video analysis insights

**Request:**
```bash
curl -X GET "https://analystai-backend-752741439479.us-central1.run.app/v1/video/insights/startup-123-video-12345" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
{
  "video_id": "startup-123-video-12345",
  "startup_id": "startup-123",
  "detailed_analysis": {
    "presentation_skills": {
      "eye_contact": 0.78,
      "pace": "optimal",
      "clarity": 0.85,
      "energy_level": "high"
    },
    "content_analysis": {
      "key_points_covered": [
        "Problem statement",
        "Solution overview",
        "Market size",
        "Business model",
        "Team background"
      ],
      "missing_elements": [
        "Competitive differentiation",
        "Go-to-market strategy details"
      ]
    },
    "investor_readiness": 0.82,
    "recommendations": [
      "Include more specific metrics and KPIs",
      "Elaborate on competitive advantages",
      "Provide clearer financial projections"
    ]
  }
}
```

---

### 9. Export Report
**Endpoint:** `POST /v1/export`  
**Description:** Export comprehensive analysis report

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/export" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123",
    "format": "gdoc",
    "include_appendix": true
  }'
```

**Response:**
```json
{
  "startup_id": "startup-123",
  "format": "gdoc",
  "document_url": "https://docs.google.com/document/d/1234567890/edit",
  "document_id": "1234567890",
  "message": "Comprehensive report created successfully"
}
```

---

### 10. UI Dashboard Data
**Endpoint:** `POST /v1/ui/dashboard`  
**Description:** Get aggregated dashboard data for UI

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/ui/dashboard" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "startup-123"
  }'
```

**Response:**
```json
{
  "startup_id": "startup-123",
  "company_name": "TechCorp AI",
  "investment_score": 82,
  "recommendation": "invest",
  "summary": {
    "strengths": ["Strong growth", "Solid team", "Good runway"],
    "weaknesses": ["High burn rate", "Competitive market"],
    "opportunities": ["Enterprise expansion", "International markets"],
    "threats": ["New competitors", "Economic downturn"]
  },
  "metrics": {
    "arr": 5000000,
    "growth_rate": 150,
    "burn_rate": 200000,
    "runway_months": 24,
    "team_size": 45,
    "customers": 120
  },
  "trends": {
    "revenue": [
      {"month": "Jan", "value": 300000},
      {"month": "Feb", "value": 350000},
      {"month": "Mar", "value": 420000}
    ],
    "customers": [
      {"month": "Jan", "value": 80},
      {"month": "Feb", "value": 95},
      {"month": "Mar", "value": 120}
    ]
  },
  "last_updated": "2025-09-20T14:30:00.000000"
}
```

---

### 11. Portfolio Overview
**Endpoint:** `GET /v1/ui/portfolio`  
**Description:** Get portfolio overview of all startups

**Request:**
```bash
curl -X GET "https://analystai-backend-752741439479.us-central1.run.app/v1/ui/portfolio" \
  -H "X-API-Key: dev-secret"
```

**Response:**
```json
{
  "total_startups": 5,
  "total_value": 45000000,
  "average_score": 78.5,
  "portfolio": [
    {
      "startup_id": "startup-123",
      "name": "TechCorp AI",
      "score": 82,
      "arr": 5000000,
      "growth_rate": 150,
      "status": "active",
      "recommendation": "invest"
    },
    {
      "startup_id": "startup-124",
      "name": "DataFlow Inc",
      "score": 75,
      "arr": 3000000,
      "growth_rate": 100,
      "status": "active",
      "recommendation": "hold"
    }
  ],
  "distribution": {
    "by_stage": {
      "seed": 2,
      "series_a": 2,
      "series_b": 1
    },
    "by_sector": {
      "ai_ml": 3,
      "fintech": 1,
      "healthtech": 1
    }
  }
}
```

---

### 12. Startup Comparison
**Endpoint:** `POST /v1/ui/comparison`  
**Description:** Compare multiple startups

**Request:**
```bash
curl -X POST "https://analystai-backend-752741439479.us-central1.run.app/v1/ui/comparison" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_ids": ["startup-123", "startup-124"]
  }'
```

**Response:**
```json
{
  "comparison": [
    {
      "startup_id": "startup-123",
      "name": "TechCorp AI",
      "metrics": {
        "score": 82,
        "arr": 5000000,
        "growth_rate": 150,
        "burn_rate": 200000,
        "team_size": 45,
        "runway": 24
      }
    },
    {
      "startup_id": "startup-124",
      "name": "DataFlow Inc",
      "metrics": {
        "score": 75,
        "arr": 3000000,
        "growth_rate": 100,
        "burn_rate": 150000,
        "team_size": 30,
        "runway": 20
      }
    }
  ],
  "winner": {
    "startup_id": "startup-123",
    "name": "TechCorp AI",
    "winning_factors": [
      "Higher growth rate",
      "Better unit economics",
      "Stronger team"
    ]
  },
  "analysis": "TechCorp AI shows superior performance across key metrics with 50% higher growth rate and better capital efficiency."
}
```

---

## 🔑 Required Parameters by Endpoint

| Endpoint | Required Headers | Required Body Parameters | Optional Parameters |
|----------|-----------------|-------------------------|-------------------|
| **GET /health/** | None | None | None |
| **GET /v1/questionnaire/questions** | X-API-Key | None | None |
| **POST /v1/questionnaire/submit** | X-API-Key, Content-Type | startup_id, responses (object) | None |
| **POST /v1/analyze** | X-API-Key, Content-Type | startup_id | persona, include_peers, include_stress |
| **POST /v1/ask** | X-API-Key, Content-Type | startup_id, question | None |
| **POST /v1/counterfactual** | X-API-Key, Content-Type | startup_id, changes (object) | None |
| **POST /v1/video/upload** | X-API-Key | startup_id, file (multipart) | None |
| **GET /v1/video/insights/{video_id}** | X-API-Key | None (video_id in path) | None |
| **POST /v1/export** | X-API-Key, Content-Type | startup_id, format | include_appendix |
| **POST /v1/ui/dashboard** | X-API-Key, Content-Type | startup_id | None |
| **GET /v1/ui/portfolio** | X-API-Key | None | None |
| **POST /v1/ui/comparison** | X-API-Key, Content-Type | startup_ids (array) | None |

---

## 📊 Response Status Codes

| Code | Description |
|------|------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Missing or invalid API key |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error |

---

## 🚀 Quick Start

1. **Set your API key:**
```bash
export API_KEY="dev-secret"
export BASE_URL="https://analystai-backend-752741439479.us-central1.run.app"
```

2. **Test the service:**
```bash
curl -X GET "$BASE_URL/health/"
```

3. **Submit questionnaire data:**
```bash
curl -X POST "$BASE_URL/v1/questionnaire/submit" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d @questionnaire_data.json
```

4. **Get analysis:**
```bash
curl -X POST "$BASE_URL/v1/analyze" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"startup_id": "your-startup-id"}'
```

---

## 📝 Notes

- All timestamps are in UTC ISO 8601 format
- Monetary values are in USD
- Percentages are expressed as whole numbers (e.g., 150 = 150%)
- Scores are normalized between 0 and 1, investment_score is 0-100
- File uploads are limited to 100MB for videos
- API rate limits: 1000 requests per minute

---

## 🔗 Additional Resources

- **Swagger UI Documentation:** https://analystai-backend-752741439479.us-central1.run.app/docs
- **OpenAPI Schema:** https://analystai-backend-752741439479.us-central1.run.app/openapi.json
- **Health Dashboard:** https://analystai-backend-752741439479.us-central1.run.app/health/

---

## 📧 Support

For API support or issues, please contact the development team or raise an issue in the project repository.

---

*Last Updated: September 20, 2025*
