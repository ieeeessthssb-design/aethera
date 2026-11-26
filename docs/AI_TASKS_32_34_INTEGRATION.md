# Tasks 32–34: connected irrigation-advice flow

## Request flow

`POST /farms/{farm_id}/irrigation/advice` (JWT required; farm owner only)

1. **Task 34 safety gate** — `safety.evaluate_message()` runs before retrieval or LLM. Refused pesticide dosage/product, poisoning, fertilizer dosage and unclear requests do not reach the retriever or LLM. Disease-related answers are kept cautious and receive the localized expert footer. Escalated advice creates a pending `ExpertCase`.
2. **Task 32 farm context** — farm crop, region, area, plant age and irrigation type are combined with the latest soil-moisture, temperature and humidity readings and the next 24-hour Open-Meteo forecast.
3. **Task 33 retrieval** — the local BM25 retriever searches the existing page-aware `ai/retrieval/chunks.json` index and adds up to three relevant excerpts to `farm_context.verified_agronomy_references`.
4. **Task 32 LLM** — Groq is primary when configured; Ollama is the existing fallback. The prompt distinguishes general agronomy references from farm-specific sensor/weather facts.
5. **Safety/confidence enforcement** — missing/stale/simulated readings and unavailable weather constrain the action/confidence. The assistant does not invent irrigation duration or water quantity.
6. **Traceability** — response includes `source_labels`, `knowledge_sources`, `confidence_reasons`, `sensor_data`, `weather` and expert-review status. Expert-case source metadata stores labels and citations.

## Task 33 implementation reality

The archive does **not** contain a pgvector or Chroma integration. It contains a local BM25 index (`chunks.json`, 2,415 passages) and the new API adapter connects that existing index to the irrigation endpoint. Do not describe it as pgvector/Chroma until a vector store is actually implemented.

The indexed passages in this archive come from three PDF files: FAO-56 Rev.1 (2025), the Tunisia crop water productivity review (2024), and the Tunisia olive water productivity report (2024). The source catalogue contains additional records that are not indexed because their PDFs are absent or the listed licence does not permit redistribution/indexing under the current script's policy. Recheck licences and document availability before expanding the corpus or commercial use.

## Docker build

The API image now needs the repository root as its build context so it can copy `ai/retrieval/retrieve.py` and `chunks.json`. Compose therefore builds with `context: ..` and `dockerfile: backend/Dockerfile`. The root `.dockerignore` excludes `.env`, local databases, virtual environments, frontend files and Git data.

## Verification still required on the developer machine

Run the complete Docker test suite and rebuild the API image. The archive could be syntax-checked and the BM25 index exercised here, but the Python environment used for this edit did not have the backend dependency `aiosqlite`, so the full pytest suite could not be run in this environment. After local tests pass, make a real authenticated request and verify that `knowledge_sources` is populated for a relevant agronomy question and empty for an unrelated question. Also verify the pesticide-dose request creates an expert case and does not call Groq/Ollama.

## Frontend boundary (not yet end-to-end)

The Flutter archive does not yet call this endpoint: `screens/assist.dart` simulates the pipeline with timers and hard-coded example output, while `screens/irrigation.dart` displays hard-coded dashboard values. `core/backend.dart` initializes Supabase, whereas the FastAPI routes shown here require the backend's own JWT. Therefore this patch connects Tasks 32–34 inside the FastAPI irrigation-advice flow, but it does not claim the Flutter screen is live-connected. A separate frontend integration is needed after deciding how Supabase identity is exchanged for a FastAPI JWT and which farm ID is selected.
