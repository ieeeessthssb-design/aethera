# Aethera safety rules (task 34)

Code: `backend/app/services/safety.py`. Tests: `backend/tests/test_safety.py`.
The rules run **before** any answer is generated (stub assistant, RAG or LLM), in code, not only in the prompt.

| Category | Example | Behaviour |
|---|---|---|
| `emergency` | "my child drank insecticide" | Refuse. Urgent medical wording and SAMU number. Expert case created. |
| `pesticide_dosage` | "how many ml of fungicide per liter?" | **Refuse.** No dose, ratio, concentration or schedule. Expert case created. |
| `pesticide_topic` | "which pesticide for my tomatoes?" | Refuse product advice, point to expert/CRDA. Expert case created. |
| `fertilizer_dosage` | "how much NPK per hectare?" | Refuse the exact rate (needs soil analysis). Expert case created. |
| `disease` | "my leaves have spots" | Answer is kept, "cannot diagnose from text, see an expert / send a photo" added, expert case created. |
| `unclear` | "???", empty | Ask to rephrase. Expert case created. |
| low confidence (< 0.6) | no knowledge-base match | Existing rule: escalate. |

**Expert wording.** Every escalated answer ends with "Check with an expert before acting on this" and every other
answer with a lighter "check with an expert for your specific field" footer, in Arabic, French or English
(language is detected from the message).

**Irrigation endpoint.** `generate_irrigation_advice` runs the same check on the farmer's question. Refused
questions are never sent to the LLM; the response is `monitor` + the refusal text + `safety_rules` source label +
`expert_review_required`.

**Refusals report confidence 0.0.** A refusal is not an agronomic answer, so there is no confidence to report.

## Known limits
- Keyword based. It will miss unusual phrasing and misspellings, especially Tunisian Derja in Latin letters (Arabizi).
  Have Derja speakers extend the lists in `safety.py` and re-test.
- `EMERGENCY_NUMBER = "190"` (SAMU) must be verified before the jury demo.
- The old stub knowledge base still contains specific figures (for example "1 hour per day", "NPK 20-20-20").
  They are outside this task but contradict the prompt rule "no fixed irrigation duration"; review them.
- Not reviewed by an agronomist or lawyer.
