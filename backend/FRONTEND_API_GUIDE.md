# Frontend API Integration Guide
## Complete API Documentation with Real Examples

This guide shows ALL API endpoints with actual curl requests and responses using a real startup example.

---

## 🚀 Step 1: Submit Questionnaire (Create Startup)

**Endpoint:** `POST /v1/questionnaire/submit`

This is the FIRST API to call - it creates the startup with all required data.

### Request:
```bash
curl -X POST "http://localhost:8001/v1/questionnaire/submit" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "responses": {
      "company_name": "TechVenture AI Solutions",
      "founding_year": 2021,
      "industry": "AI/ML",
      "business_model": "B2B SaaS",
      "company_description": "AI-powered predictive analytics platform for enterprise supply chain optimization",
      "headquarters": "San Francisco, USA",
      "target_markets": "North America, Europe, Asia",
      
      "arr": 12000000,
      "mrr": 1000000,
      "growth_rate": 180,
      "gross_margin": 78,
      "burn_rate": 500000,
      "runway": 24,
      
      "total_customers": 85,
      "fortune_500_customers": 8,
      "churn_rate": 2.1,
      "logo_retention": 94,
      "nrr": 135,
      "cac": 12000,
      "ltv": 180000,
      "customer_concentration": 12,
      
      "team_size": 67,
      "founder_names": "Sarah Chen - CEO (ex-Google ML), Mike Johnson - CTO (ex-Amazon)",
      "founder_experience": "Yes",
      "team_from_faang": 18,
      "technical_team": 58,
      
      "funding_stage": "Series A",
      "total_raised": 25000000,
      "last_valuation": 120000000,
      "current_ask": 40000000,
      "target_valuation": 250000000,
      "use_of_funds": "40% R&D, 35% Sales & Marketing, 15% Operations, 10% Reserve",
      "exit_strategy": "IPO in 5-7 years or strategic acquisition by enterprise software company",
      "investor_names": "Sequoia Capital, Andreessen Horowitz, Y Combinator",
      
      "product_stage": "Scaling",
      "competitive_advantage": "Proprietary ML models with 10x faster processing and 40% better accuracy than competitors",
      "tam": 75000000000,
      
      "pitch_deck_url": "https://example.com/deck.pdf",
      "financial_model_url": "https://example.com/financials.xlsx"
    }
  }'
```

### Response:
```json
{
  "success": true,
  "startup_id": "techventure-2024",
  "questions_answered": 39,
  "chunks_created": 9,
  "message": "Questionnaire submitted successfully. Ready for analysis."
}
```

---

## 📊 Step 2: Analyze Startup

**Endpoint:** `POST /v1/analyze`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "analysis_type": "standard"
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "company_name": "TechVenture AI Solutions",
  "executive_summary": [
    "TechVenture AI Solutions demonstrates exceptional growth with 180% YoY and $12M ARR in the enterprise AI space.",
    "Strong unit economics with 78% gross margin and LTV/CAC ratio of 15x indicate sustainable business model.",
    "Series A company with experienced FAANG founders seeking $40M to accelerate growth."
  ],
  "kpis": {
    "arr": 12000000,
    "growth_rate": 180,
    "gross_margin": 78,
    "burn_rate": 500000,
    "runway_months": 24,
    "cac_ltv_ratio": 15,
    "logo_retention": 94,
    "nrr": 135
  },
  "risks": [
    {
      "label": "High burn rate of $500K/month requires careful monitoring",
      "severity": 3,
      "mitigation": "Strong runway of 24 months provides buffer for optimization"
    }
  ],
  "recommendation": "invest",
  "investment_score": 82.5,
  "score": 0.825
}
```

---

## 💬 Step 3: Ask Questions (Q&A)

**Endpoint:** `POST /v1/ask`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/ask" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "question": "What is the competitive advantage and market opportunity?"
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "question": "What is the competitive advantage and market opportunity?",
  "answer": [
    "TechVenture AI Solutions has proprietary ML models with 10x faster processing and 40% better accuracy than competitors. They're targeting a $75B TAM in enterprise supply chain optimization with strong traction including 8 Fortune 500 customers."
  ],
  "evidence": [
    {
      "id": "techventure-2024_competitive",
      "type": "slide",
      "location": "questionnaire",
      "snippet": "Proprietary ML models with 10x faster processing and 40% better accuracy",
      "confidence": 0.95
    }
  ],
  "confidence": 0.95
}
```

---

## 🔄 Step 4: Counterfactual Analysis

**Endpoint:** `POST /v1/counterfactual`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/counterfactual" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "scenarios": [
      {"parameter": "arr", "value": 20000000, "description": "What if ARR reaches $20M?"},
      {"parameter": "growth_rate", "value": 250, "description": "What if growth accelerates to 250%?"},
      {"parameter": "burn_rate", "value": 300000, "description": "What if we reduce burn to $300K?"}
    ]
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "current_score": 82.5,
  "original_score": 0.825,
  "new_score": 0.85,
  "original_recommendation": "invest",
  "new_recommendation": "invest",
  "scenarios": [
    {
      "description": "What if ARR reaches $20M?",
      "parameter": "arr",
      "value": 20000000,
      "new_score": 90.5,
      "new_recommendation": "invest"
    },
    {
      "description": "What if growth accelerates to 250%?",
      "parameter": "growth_rate",
      "value": 250,
      "new_score": 89.5,
      "new_recommendation": "invest"
    },
    {
      "description": "What if we reduce burn to $300K?",
      "parameter": "burn_rate",
      "value": 300000,
      "new_score": 86.5,
      "new_recommendation": "invest"
    }
  ],
  "breakpoints": {
    "arr_threshold": 10000000,
    "growth_threshold": 200,
    "burn_threshold": 500000
  },
  "impact_analysis": {
    "arr": "positive impact on recommendation",
    "growth": "positive impact on recommendation",
    "burn": "positive impact on recommendation"
  }
}
```

---

## 📈 Step 5: Dashboard

**Endpoint:** `GET /v1/ui/dashboard/{startup_id}`

### Request:
```bash
curl -X GET "http://localhost:8001/v1/ui/dashboard/techventure-2024" \
  -H "X-API-Key: dev-secret"
```

### Response:
```json
{
  "company_profile": {
    "name": "TechVenture AI Solutions",
    "industry": "AI/ML",
    "founded": 2021,
    "headquarters": "San Francisco, USA",
    "business_model": "B2B SaaS",
    "team_size": 67,
    "description": "AI-powered predictive analytics platform for enterprise supply chain optimization",
    "revenue": "$12.0M ARR",
    "funding_raised": "$25.0M"
  },
  "key_metrics": {
    "arr": "$12.0M",
    "growth": "180% YoY",
    "burn": "$500K/month",
    "runway": "24 months",
    "team_size": 67,
    "business_model": "B2B SaaS"
  },
  "investment_score": {
    "overall": 82.5,
    "components": {
      "market": 85,
      "product": 88,
      "team": 82,
      "financials": 75
    }
  },
  "ai_insights": [
    {
      "type": "strength",
      "title": "Strong Unit Economics",
      "description": "LTV/CAC ratio of 15x with 78% gross margin"
    },
    {
      "type": "opportunity",
      "title": "Market Expansion",
      "description": "$75B TAM with only 0.016% captured"
    }
  ],
  "recent_activity": [
    {
      "date": "2024-09-20",
      "type": "analysis",
      "description": "Investment score: 82.5/100"
    }
  ]
}
```

---

## 📁 Step 6: Portfolio View

**Endpoint:** `GET /v1/ui/portfolio`

### Request:
```bash
curl -X GET "http://localhost:8001/v1/ui/portfolio" \
  -H "X-API-Key: dev-secret"
```

### Response:
```json
{
  "total_value": 120000000,
  "companies": [
    {
      "id": "techventure-2024",
      "name": "TechVenture AI Solutions",
      "sector": "AI/ML",
      "stage": "Series A",
      "valuation": 120000000,
      "performance": {
        "arr": 12000000,
        "growth": 180,
        "score": 82.5
      },
      "status": "active"
    }
  ],
  "metrics": {
    "total_companies": 1,
    "average_score": 82.5,
    "top_performer": "TechVenture AI Solutions"
  }
}
```

---

## 📊 Step 7: Comparison

**Endpoint:** `POST /v1/ui/comparison`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/ui/comparison" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_ids": ["techventure-2024"],
    "metrics": ["arr", "growth_rate", "burn_rate", "team_size"]
  }'
```

### Response:
```json
{
  "comparison": {
    "TechVenture AI Solutions": {
      "arr": 12000000,
      "growth": 180,
      "team_size": 67,
      "burn_rate": 500000,
      "runway": 24,
      "customers": 85,
      "churn": 2.1
    },
    "Industry Average": {
      "arr": 5000000,
      "growth": 100,
      "team_size": 50,
      "burn_rate": 300000,
      "runway": 18,
      "customers": 100,
      "churn": 3
    }
  },
  "risk_distribution": {
    "Market Risk": 30,
    "Execution Risk": 25,
    "Financial Risk": 25,
    "Team Risk": 20
  },
  "score_comparison": [
    {"startup": "TechVenture AI Solutions", "score": 82.5},
    {"startup": "Industry Average", "score": 65}
  ]
}
```

---

## 📈 Step 8: Growth Simulation

**Endpoint:** `GET /v1/ui/growth-simulation`

### Request:
```bash
curl -X GET "http://localhost:8001/v1/ui/growth-simulation?startup_id=techventure-2024" \
  -H "X-API-Key: dev-secret"
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "scenarios": [
    {
      "name": "base",
      "description": "Current trajectory",
      "projections": [
        {"year": 1, "arr": 12000000, "valuation": 120000000},
        {"year": 2, "arr": 21600000, "valuation": 216000000},
        {"year": 3, "arr": 38880000, "valuation": 388800000}
      ]
    },
    {
      "name": "optimistic",
      "description": "Best case scenario",
      "projections": [
        {"year": 1, "arr": 12000000, "valuation": 120000000},
        {"year": 2, "arr": 30000000, "valuation": 300000000},
        {"year": 3, "arr": 75000000, "valuation": 750000000}
      ]
    },
    {
      "name": "pessimistic",
      "description": "Conservative scenario",
      "projections": [
        {"year": 1, "arr": 12000000, "valuation": 120000000},
        {"year": 2, "arr": 15600000, "valuation": 156000000},
        {"year": 3, "arr": 20280000, "valuation": 202800000}
      ]
    }
  ]
}
```

---

## 🏛️ Step 9: Regulatory Radar

**Endpoint:** `POST /v1/ui/regulatory-radar`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/ui/regulatory-radar" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024"
  }'
```

### Response:
```json
{
  "compliance_score": 85,
  "regulatory_risks": [
    {"risk": "AI Model Transparency Requirements", "level": "medium"},
    {"risk": "Data Privacy Compliance (GDPR/CCPA)", "level": "high"},
    {"risk": "Enterprise Security Standards", "level": "low"}
  ],
  "alerts": [
    {
      "title": "New AI Act Regulations Q1 2025",
      "severity": "high",
      "region": "EU"
    },
    {
      "title": "Updated SOC2 Requirements",
      "severity": "medium",
      "region": "USA"
    }
  ],
  "risk_heatmap": {
    "USA": {"AI/ML": 40, "Data Privacy": 60, "Security": 30},
    "EU": {"AI/ML": 70, "Data Privacy": 80, "Security": 40},
    "Asia": {"AI/ML": 30, "Data Privacy": 50, "Security": 35}
  },
  "sentiment_trend": {
    "positive": 72,
    "negative": 28,
    "trend": "improving"
  }
}
```

---

## 🔗 Step 10: Graph Analysis (Neo4j)

**Endpoint:** `POST /v1/advanced/graph/analyze`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/advanced/graph/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "analysis_type": "competitors"
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "analysis_type": "competitors",
  "insights": [
    "TechVenture AI Solutions positioned strongly against 3 main competitors",
    "Key differentiator: 10x faster processing speed",
    "Market share opportunity: 98% of TAM uncaptured"
  ],
  "node_count": 12,
  "relationship_count": 24,
  "key_relationships": [
    {"type": "COMPETES_WITH", "entity": "DataRobot", "strength": 0.7},
    {"type": "PARTNERS_WITH", "entity": "AWS", "strength": 0.9},
    {"type": "TARGETS", "entity": "Fortune 500", "strength": 0.8}
  ]
}
```

---

## 🤖 Step 11: LangGraph Workflow

**Endpoint:** `POST /v1/advanced/workflow/analyze`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/advanced/workflow/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "workflow_type": "investment_analysis"
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "workflow_type": "investment_analysis",
  "steps": [
    {
      "step": "market_analysis",
      "status": "completed",
      "result": "TAM of $75B with strong growth trajectory"
    },
    {
      "step": "competitive_analysis",
      "status": "completed",
      "result": "Strong moat with proprietary technology"
    },
    {
      "step": "financial_analysis",
      "status": "completed",
      "result": "Healthy unit economics, path to profitability clear"
    },
    {
      "step": "team_assessment",
      "status": "completed",
      "result": "Experienced team with FAANG background"
    }
  ],
  "final_recommendation": {
    "decision": "INVEST",
    "confidence": 0.85,
    "key_factors": [
      "Strong product-market fit",
      "Exceptional team",
      "Large market opportunity"
    ]
  }
}
```

---

## 📄 Step 12: Export Report

**Endpoint:** `POST /v1/export`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/export" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "startup_id": "techventure-2024",
    "format": "json",
    "sections": ["overview", "analysis", "financials", "team"]
  }'
```

### Response:
```json
{
  "startup_id": "techventure-2024",
  "format": "json",
  "document_url": "file:///Users/backend/data/exports/techventure-2024_analysis.json",
  "document_id": "json_techventure-2024",
  "success": true,
  "message": "Analysis exported to data/exports/techventure-2024_analysis.json"
}
```

---

## 🎥 Step 13: Video Upload & Analysis (Enhanced with UI Metrics)

**Endpoint:** `POST /v1/video/upload`

### Request:
```bash
curl -X POST "http://localhost:8001/v1/video/upload" \
  -H "X-API-Key: dev-secret" \
  -F "file=@founder_pitch.mp4" \
  -F "startup_id=techventure-2024"
```

### Response (Auto-analysis for videos < 10MB):
```json
{
  "video_id": "techventure-2024-video-12345",
  "startup_id": "techventure-2024",
  "filename": "founder_pitch.mp4",
  "size_mb": 8.2,
  "analysis": {
    "processed_with": "Google Cloud Video Intelligence API (REAL)",
    "transcript": "Hello investors, I'm excited to present TechVenture AI Solutions...",
    "founder_analysis": {
      "confidence_score": 0.88,
      "communication_clarity": 0.92,
      "technical_depth": 0.85,
      "passion_score": 0.91,
      "authenticity": 0.87
    },
    "sentiment_analysis": {
      "overall_sentiment": "positive",
      "confidence": 0.89,
      "key_emotions": ["confident", "enthusiastic", "professional"]
    },
    "investment_signals": {
      "founder_quality": 0.88,
      "recommended_action": "invest",
      "key_strengths": ["Clear vision", "Technical expertise", "Market understanding"],
      "concerns": []
    },
    "ui_metrics": {
      "founder_score": 88,
      "communication_grade": "A",
      "passion_level": "High",
      "recommendation": {
        "action": "INVEST",
        "priority": "high",
        "confidence": 89
      },
      "insights": {
        "strength": "Clear vision",
        "concern": "None identified",
        "sentiment": "Positive",
        "energy": "Confident"
      },
      "scores": {
        "confidence": 88,
        "clarity": 92,
        "passion": 91,
        "authenticity": 87,
        "technical_depth": 85
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

### Get Cached Video Analysis:
**Endpoint:** `POST /v1/video/analyze`

```bash
curl -X POST "http://localhost:8001/v1/video/analyze" \
  -H "X-API-Key: dev-secret" \
  -H "Content-Type: application/json" \
  -d '{"video_id": "techventure-2024-video-12345"}'
```

**Response:** Same structure as above with `ui_metrics` for direct UI consumption.

---

## 🎯 UI Metrics Guide for Flutter

The video APIs now include `ui_metrics` for direct UI consumption:

### Progress Bars & Scores (0-100):
```dart
// Use these directly in progress indicators
int confidence = response['ui_metrics']['scores']['confidence']; // 88
int clarity = response['ui_metrics']['scores']['clarity']; // 92
int passion = response['ui_metrics']['scores']['passion']; // 91
```

### Grade & Level Indicators:
```dart
String grade = response['ui_metrics']['communication_grade']; // "A"
String level = response['ui_metrics']['passion_level']; // "High"
String status = response['ui_metrics']['status']['overall']; // "Excellent"
```

### Recommendation Styling:
```dart
String action = response['ui_metrics']['recommendation']['action']; // "INVEST"
String priority = response['ui_metrics']['recommendation']['priority']; // "high"

// Style based on priority:
// high = green, medium = orange, low = red
Color getColor(String priority) {
  switch(priority) {
    case 'high': return Colors.green;
    case 'medium': return Colors.orange;  
    case 'low': return Colors.red;
    default: return Colors.grey;
  }
}
```

### Status Flags:
```dart
bool readyForPitch = response['ui_metrics']['status']['ready_for_pitch'];
bool needsCoaching = response['ui_metrics']['status']['needs_coaching'];
```

---

## 📝 Important Notes for Frontend:

1. **Authentication**: All endpoints require `X-API-Key: dev-secret` header
2. **Content-Type**: Use `application/json` for all POST requests (except file uploads)
3. **Startup ID**: Use consistent startup_id across all endpoints
4. **Order**: Always call questionnaire/submit first to create the startup
5. **Video Integration**: Dashboard API now returns `video_id` for video analysis access
6. **UI Metrics**: Video APIs include pre-calculated metrics for direct UI use
7. **Caching**: Video analysis is cached - subsequent calls return stored results
8. **Error Handling**: All endpoints return standard HTTP status codes:
   - 200: Success
   - 400: Bad Request
   - 404: Not Found
   - 422: Validation Error
   - 500: Server Error

## 🚀 Quick Start Flow:

1. Submit questionnaire to create startup
2. Run analysis to get investment score
3. Use dashboard for overview
4. Ask specific questions via Q&A
5. Test scenarios with counterfactual
6. Export final report

## 📊 Data Types:

- **Money fields**: Numbers (e.g., arr: 12000000 for $12M)
- **Percentage fields**: Numbers (e.g., growth_rate: 180 for 180%)
- **Text fields**: Strings
- **Boolean fields**: "Yes"/"No" or true/false

---

## Production URL:

Replace `http://localhost:8001` with production URL when deployed:
- Production: `https://analystai-backend-752741439479.us-central1.run.app`

---

## Support:

For any questions or issues, check the response structure carefully. All endpoints return JSON with clear error messages if something goes wrong.
