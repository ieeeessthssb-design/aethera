FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/srv/aethera

WORKDIR /srv/aethera

# System dependencies
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

# Backend dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# CPU-only PyTorch and torchvision
RUN pip install torch==2.14.1 torchvision==0.29.1 \
    --index-url https://download.pytorch.org/whl/cpu

# Vision runtime dependencies
COPY backend/requirements-vision-runtime.txt ./requirements-vision-runtime.txt
RUN pip install -r requirements-vision-runtime.txt

# Backend application
COPY backend/ ./backend

# AI Vision package
COPY ai/vision/ ./ai/vision/

# AI retrieval files
RUN mkdir -p ./ai/retrieval
COPY ai/retrieval/retrieve.py ./ai/retrieval/retrieve.py
COPY ai/retrieval/chunks.json ./ai/retrieval/chunks.json

# Backend working directory
WORKDIR /srv/aethera/backend
RUN mkdir -p uploads/diagnoses

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && python -m app.seed_demo_account && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
