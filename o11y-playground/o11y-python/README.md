> NOTE: This demo app is intentionally independent from the core observability stack.
> Start the toolkit (root directory) and this app separately. They communicate only
> via the shared Docker network `observability` and the OTLP endpoint `otel-collector:4317`.
# Demo Python Observability App

Independent FastAPI application instrumented with OpenTelemetry to emit metrics, logs, and traces to an existing Observability Toolkit stack (Prometheus, Grafana, Jaeger, Elasticsearch/Kibana) via the OpenTelemetry Collector.

It connects by joining the shared external Docker network named `observability` and sending OTLP gRPC data to `otel-collector:4317`.

## Endpoints
* `/` – Simple hello; creates a span with random work.
* `/healthz` – Liveness probe.
* `/readyz` – Readiness probe.
* `/work` – CPU loop; span events + metrics.
* `/error` – Intentionally triggers a division error to showcase error span + logs.

## Data Flow
App -> OTLP gRPC -> OTel Collector ->
* Traces: Jaeger UI + Elasticsearch index `otel-traces`
* Metrics: Prometheus (collector exporter) -> Grafana
* Logs: Elasticsearch index `otel-logs` (Kibana Discover)

## Prerequisites
Start the Observability Toolkit stack (in its own project directory):
```bash
./manage-stack.sh start
```
Ensure the network exists (toolkit compose names it automatically):
```bash
docker network create observability 2>/dev/null || true
```

## Run (Standalone - demo only)
From this directory (creates/uses external network `observability` if present):
```bash
chmod +x run.sh  # first time
./run.sh up
```
Stop / remove:
```bash
./run.sh down
```

## Run with Full Observability Stack (Independent)
1. In repository root: `./manage-stack.sh start`
2. In this directory: `docker compose up -d --build`
	(or `./run.sh up`)
3. (Optional) If you start the app before the stack, telemetry export will warn until the collector is up.
4. Generate traffic (see below). No edits to the root compose file are required.

## Generate Test Traffic
```bash
curl http://localhost:8000/
curl http://localhost:8000/work
curl http://localhost:8000/error
for i in {1..20}; do curl -s http://localhost:8000/work > /dev/null; done
# or use script helper:
./run.sh traffic
```

## Where to Observe
* Prometheus: http://localhost:9090 (metrics: `demo_requests_total`, `demo_request_latency_ms`, `demo_random_value`)
* Grafana: http://localhost:3000 (build a dashboard with those metrics)
* Jaeger: http://localhost:16686 (service: `o11y-python`)
* Kibana: http://localhost:5601 (Discover index: `otel-logs*`, filter by `resource.service.name`)

## Multiple Demo Apps
To add more sample services independently:
1. Copy this folder (e.g., `cp -r o11y-python o11y-python-2`).
2. Change `OTEL_SERVICE_NAME` in its compose file or Dockerfile env.
3. Bring it up with `docker compose up -d --build` inside the new folder.
4. Ensure it uses the `observability` network (external) so it can reach `otel-collector`.

Each will appear as a distinct service in Jaeger / metrics / logs without modifying the core stack compose.

## Notes
* Runs as non-root user inside container.
* Metrics exported via OTLP to the collector then exposed via Prometheus exporter (port 8889).
* Logs use BatchLogRecordProcessor; gauge emits random values for demonstration.
* Health endpoints (`/healthz`, `/readyz`) provided for orchestration probes.
* Adjustable log level via `APP_LOG_LEVEL` environment variable.

### Environment Overrides
| Variable | Purpose | Default |
|----------|---------|---------|
| OTEL_EXPORTER_OTLP_ENDPOINT | Collector gRPC endpoint | otel-collector:4317 |
| OTEL_EXPORTER_OTLP_PROTOCOL | OTLP protocol | grpc |
| OTEL_SERVICE_NAME | Service name resource attr | o11y-python |
| APP_LOG_LEVEL | Logging level | info |

### Security (Demo Caveats)
No auth/TLS; not for production without hardening (dependency pin review, resource limits, structured logs routing, input validation, etc.).

## Cleanup
```bash
docker compose down
```

This does not stop the core observability stack (managed separately).
