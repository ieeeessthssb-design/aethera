FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/aethera
RUN pip install --no-cache-dir requests==2.32.5
COPY runner.py /opt/aethera/runner.py

CMD ["python", "/opt/aethera/runner.py"]
