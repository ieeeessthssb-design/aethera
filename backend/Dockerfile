FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /srv/aethera

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt ./requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY backend/ ./backend
RUN mkdir -p ./ai/retrieval
COPY ai/retrieval/retrieve.py ./ai/retrieval/retrieve.py
COPY ai/retrieval/chunks.json ./ai/retrieval/chunks.json
WORKDIR /srv/aethera/backend
RUN mkdir -p uploads/diagnoses

EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && python -m app.seed_demo_account && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
