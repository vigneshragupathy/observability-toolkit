import logging
import os
import random
import time
from fastapi import FastAPI, Request
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from fastapi.responses import JSONResponse

from opentelemetry import trace, metrics
from opentelemetry.metrics import Observation
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter

# Basic resource attributes
resource = Resource.create({
    "service.name": "o11y-python",
    "service.version": "0.1.0",
    "service.namespace": "demo",
    "deployment.environment": "dev"
})

# Tracer setup
trace_provider = TracerProvider(resource=resource)
trace.set_tracer_provider(trace_provider)
trace_exporter = OTLPSpanExporter(endpoint="otel-collector:4317", insecure=True)
trace_provider.add_span_processor(BatchSpanProcessor(trace_exporter))

# Metrics setup
metric_exporter = OTLPMetricExporter(endpoint="otel-collector:4317", insecure=True)
reader = PeriodicExportingMetricReader(metric_exporter, export_interval_millis=5000)
meter_provider = MeterProvider(resource=resource, metric_readers=[reader])
metrics.set_meter_provider(meter_provider)

# Logs setup
logger_provider = LoggerProvider(resource=resource)
log_exporter = OTLPLogExporter(endpoint="otel-collector:4317", insecure=True)
logger_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))
logging_handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
logging.getLogger().addHandler(logging_handler)
log_level = os.getenv("APP_LOG_LEVEL", "info").upper()
logging.getLogger().setLevel(getattr(logging, log_level, logging.INFO))

app = FastAPI(title="Demo Observability App")
FastAPIInstrumentor.instrument_app(app)

meter = metrics.get_meter("o11y-python")
request_counter = meter.create_counter(
    name="demo_requests_total",
    description="Total number of demo requests",
    unit="1"
)
latency_hist = meter.create_histogram(
    name="demo_request_latency_ms",
    description="Request latency in milliseconds",
    unit="ms"
)
def random_value_callback(options):
    # Provide a changing random value to illustrate observable metrics
    yield Observation(random.random() * 100)

random_gauge = meter.create_observable_gauge(
    name="demo_random_value",
    callbacks=[random_value_callback],
    description="Random value gauge"
)

tracer = trace.get_tracer("o11y-python")

@app.middleware("http")
async def add_metrics(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration_ms = (time.time() - start) * 1000
    request_counter.add(1, {"method": request.method, "path": request.url.path})
    latency_hist.record(duration_ms, {"method": request.method, "path": request.url.path})
    return response

@app.get("/")
async def root():
    logging.info("Root endpoint accessed", extra={"endpoint": "/"})
    with tracer.start_as_current_span("root-operation") as span:
        span.set_attribute("app.logic.phase", "start")
        # Simulate work
        time.sleep(random.random())
        span.set_attribute("app.random.value", random.randint(1, 100))
    return {"message": "Hello from demo app"}

@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.get("/readyz")
async def ready():
    # In a real service you might check downstream connectivity; trivial here.
    return {"ready": True}

@app.get("/error")
async def error():
    logging.warning("Error endpoint hit; generating error span")
    try:
        1 / 0
    except ZeroDivisionError as e:
        with tracer.start_as_current_span("error-span") as span:
            span.record_exception(e)
            span.set_attribute("error", True)
        logging.exception("An error occurred")
        return JSONResponse({"error": "division by zero"}, status_code=500)

@app.get("/work")
async def work():
    with tracer.start_as_current_span("work-operation") as span:
        span.add_event("work_started")
        total = sum(i*i for i in range(10000))
        span.add_event("work_completed", {"result": total})
    logging.info("Work endpoint completed", extra={"result": total})
    return {"result": total}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
