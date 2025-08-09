FROM python:3.11-slim

LABEL org.opencontainers.image.title="o11y-python demo" \
    org.opencontainers.image.description="FastAPI demo app emitting OTLP traces/metrics/logs to an OpenTelemetry Collector" \
    org.opencontainers.image.source="https://github.com/vigneshragupathy/observability-toolkit" \
    org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install dependencies (copy first for better layer cache)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .
RUN chown -R appuser:appuser /app

ENV OTEL_EXPORTER_OTLP_ENDPOINT=otel-collector:4317 \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
    OTEL_SERVICE_NAME=o11y-python \
    PYTHONUNBUFFERED=1 \
    APP_LOG_LEVEL=info

EXPOSE 8000

USER appuser

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
