# Assistant v1 — farm-aware irrigation advice

## What it does

`POST /farms/{farm_id}/irrigation/advice` builds a single prompt from:
- the authenticated farmer's farm profile (crop, region, area, plant age, irrigation method);
- the latest soil-moisture, temperature and humidity readings in `readings`;
- the next 24 hours of Open-Meteo weather (temperature, rain probability and precipitation).

The Groq LLM returns a constrained JSON recommendation (`irrigate_now`, `wait`, `monitor`, or `insufficient_data`). The API returns the explanation, practical steps, sensor/weather context, source labels and a confidence level.

The confidence score is a **data-availability/quality score**, not a statistically calibrated probability that the recommendation is correct. Simulated sensor data, missing soil moisture, or unavailable weather force a low-confidence result. Low-confidence results create a pending `ExpertCase` for human review.

The assistant deliberately does not invent irrigation minutes, litres, or millimetres. The current farm schema does not contain crop-specific water requirements or validated irrigation thresholds, so quantitative advice must wait until those agronomic data are added and reviewed by an expert.

## Configure the free LLM API

1. Create an account at https://console.groq.com/.
2. Open API Keys and create a key.
3. Copy `backend/.env.example` to `backend/.env`, then set these values in `backend/.env`:

```env
ASSISTANT_PROVIDER=groq
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=openai/gpt-oss-20b
GROQ_BASE_URL=https://api.groq.com/openai/v1
```

4. From the project root, run `docker compose -f backend/docker-compose.yml up --build`. Keep the key in the backend environment only; never put it in Flutter, Git, or a public repository.

If the key is absent or the API fails, the endpoint uses a cautious deterministic fallback and labels it `rules_fallback`. The API still works locally, but it is not an LLM response in that case.

## Request

Requires the same JWT Bearer token as the other FastAPI endpoints. The farm must belong to the authenticated user.

```http
POST /farms/{farm_id}/irrigation/advice
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "message": "Should I irrigate my tomato field today?"
}
```

The request body is optional; when omitted, the default question is used.

## Example response shape

```json
{
  "farm_id": "farm-id",
  "action": "monitor",
  "action_label": "Monitor conditions",
  "explanation": "The available data does not justify an automatic irrigation quantity.",
  "recommended_steps": ["Check soil moisture manually near the root zone."],
  "confidence": 0.59,
  "confidence_level": "low",
  "confidence_reasons": ["Sensor values are simulated, not field measurements"],
  "source_labels": ["sensor", "simulated_data", "weather", "farm_profile", "llm_groq"],
  "source_label": "sensor + simulated_data + weather + farm_profile + llm_groq",
  "sensor_data": {},
  "weather": {},
  "expert_review_required": true,
  "expert_case_id": "case-id",
  "generated_at": "2026-11-22T00:00:00Z"
}
```

## Test

From `backend/` (after installing the requirements and configuring the test database):

```bash
pip install -r requirements.txt
pytest -q
```

## Weather attribution

Weather data is provided by [Open-Meteo](https://open-meteo.com/) under CC BY 4.0. This integration is intended for non-commercial development/pilot use; check Open-Meteo's current terms before commercial deployment.
