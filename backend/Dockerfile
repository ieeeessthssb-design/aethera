FROM python:3.12-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./
# Task #33 retrieval index and BM25 implementation are shared with the AI source tree.
RUN mkdir -p ./ai/retrieval
COPY ai/retrieval/retrieve.py ./ai/retrieval/retrieve.py
COPY ai/retrieval/chunks.json ./ai/retrieval/chunks.json
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
