# Observability Toolkit

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.0%2B-blue)](https://docs.docker.com/compose/)

A comprehensive demo and learning observability stack that provides metrics collection, log aggregation, distributed tracing, and alerting capabilities using industry-standard open-source tools.

> **Disclaimer**: This project is intended for demonstration, experimentation, and educational purposes only. It is **NOT production ready**. It runs all components in single containers with minimal configuration and without hardening (no auth, no TLS, single-node Elasticsearch, in-container Prometheus storage, no HA, no backup/restore strategy). Before any production use you must implement security, scaling, persistence, resilience, and operational safeguards.

## ✨ Features

- **📊 Metrics Collection**: Prometheus with custom alerting rules
- **📈 Visualization**: Pre-configured Grafana dashboards
- **📋 Log Aggregation**: Elasticsearch + Kibana for centralized logging
- **🔍 Distributed Tracing**: Jaeger for request tracing
- **🚨 Alerting**: AlertManager with webhook integrations
- **🔄 Data Pipeline**: OpenTelemetry Collector for data processing
- **🖥️ System Monitoring**: Node Exporter for host metrics
- **🛠️ Easy Management**: Convenient shell script for operations
- **☸️ Kubernetes Ready**: Kustomize manifests for deploying the full stack + sample app (Kind or any cluster)

## 📋 Stack Components

| Component | Purpose | Port | UI/API |
|-----------|---------|------|--------|
| **Prometheus** | Metrics collection and storage | 9090 | http://localhost:9090 |
| **Grafana** | Metrics visualization and dashboards | 3000 | http://localhost:3000 |
| **Elasticsearch** | Log storage and search | 9200 | http://localhost:9200 |
| **Kibana** | Log visualization and analysis | 5601 | http://localhost:5601 |
| **Jaeger** | Distributed tracing | 16686 | http://localhost:16686 |
| **OpenTelemetry Collector** | Data pipeline and processing | 4317/4318 | - |
| **AlertManager** | Alert management and routing | 9093 | http://localhost:9093 |
| **Node Exporter** | System metrics collection | 9100 | - |
| **Kafka** | Log pipeline buffering | 29092 | - |
| **Kafka UI** | Inspect Kafka topics | 8085 | http://localhost:8085 |
| **Kafka JMX Exporter** | Kafka metrics for Prometheus | 5556 | http://localhost:5556/metrics |

## ⚠️ Security Notice

**This toolkit is configured for development/testing environments. For production use, please review and implement the security measures outlined in [SECURITY.md](SECURITY.md).**

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+ (either `docker-compose` or `docker compose`)
- At least 4GB of available RAM
- 10GB of free disk space

> **Note**: This toolkit supports both the standalone `docker-compose` binary and the newer `docker compose` plugin. The management script will automatically detect which version is available.

### Starting the Stack

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vigneshragupathy/observability-toolkit.git
   cd observability-toolkit
   ```

2. **Copy environment configuration (optional):**
   ```bash
   cp .env.example .env
   # Edit .env file to customize your environment
   ```

3. **Using the management script (Recommended):**
   ```bash
   ./manage-stack.sh start
   ```

4. **Using Docker Compose directly (Alternative to step 3 – choose one):**
   ```bash
   # Using docker-compose (standalone)
   docker-compose up -d
   
   # OR using docker compose (plugin)
   docker compose up -d
   ```

### Accessing the Services

After starting the stack, you can access the following services:

- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Jaeger Tracing**: http://localhost:16686
- **Kibana Logs**: http://localhost:5601
- **AlertManager**: http://localhost:9093

> **Note**: These URLs are only accessible when the stack is running locally.

### Demo Application (Independent)

A sample FastAPI + OpenTelemetry app lives under `o11y-playground/o11y-python`.
It runs in its own directory and just needs to share the Docker network named `observability`
so it can reach the toolkit's OpenTelemetry Collector at `otel-collector:4317`.

docker compose up -d --build
Run it separately (after starting the stack):
```bash
cd o11y-playground/o11y-python
chmod +x run.sh # first time only
./run.sh up     # build & start
./run.sh traffic # optional sample load
```
Stop it:
```bash
./run.sh down
```

Endpoints: `/`, `/work`, `/error` (http://localhost:8000)

These generate traces (Jaeger), metrics (Prometheus/Grafana), and logs (Kibana) independently of the core compose file.

### Kubernetes Deployment (Alternative Environment)

You can also deploy the same observability toolkit to a Kubernetes cluster (tested with Kind) with namespace separation and auto‑provisioned Grafana dashboards.

Quick Kind demo:
```bash
cd kubernetes/kind
./setup.sh  # creates kind cluster + applies kustomize
```

Generic cluster:
```bash
cd kubernetes
./deploy.sh --wait
```

Then port-forward (example):
```bash
kubectl -n observability port-forward svc/grafana 3000:3000 &
kubectl -n observability port-forward svc/prometheus 9090:9090 &
kubectl -n observability port-forward svc/jaeger-query 16686:16686 &
kubectl -n observability port-forward svc/kibana 5601:5601 &
```

Kubernetes docs, build modes (external vs in‑cluster Kaniko), and dashboard provisioning details live in `kubernetes/README.md`.

### Kafka-Based Log Pipeline (Default)

Kafka is enabled by default to demonstrate a decoupled log ingestion flow:

1. Applications send logs to the OpenTelemetry Collector (OTLP) as usual.
2. Collector (pipeline `logs_produce`) publishes log records to Kafka topic `otel-logs` in OTLP JSON encoding.
3. A second Collector pipeline (`logs_consume`) consumes from Kafka and forwards to Elasticsearch.
4. Kibana visualizes logs stored in Elasticsearch with no change required by applications.

Benefits demonstrated:
- Decouples ingestion from indexing (burst smoothing, backpressure handling concept).
- Provides a tap point to add stream processors / enrichment later.
- Shows how the Collector can both produce to and consume from Kafka.

Start the stack (Kafka already included):
```bash
./manage-stack.sh start
```

Opt-out (no Kafka buffering, logs go straight to Elasticsearch):
```bash
./manage-stack.sh start --no-kafka
```

Inspect the topic:
```bash
open http://localhost:8085  # Kafka UI
```

Produce a sample log burst (using the demo app traffic command):
```bash
cd o11y-playground/o11y-python
./run.sh traffic
```

If you disable Kafka, the Collector config still defines Kafka pipelines; without the broker they will error. For a cleaner no-Kafka run, use `--no-kafka` which suppresses starting broker/UI (logs may show Kafka exporter connection retries until you adjust the Collector config). Future improvement: conditional Collector config templating.

Topic & encoding details:
- Topic: `otel-logs`
- Encoding: `otlp_json` (human-inspectable payloads)
- Consumer group: `otel-collector-log-consumer`

If Kafka is down, the `logs_produce` pipeline retries (see exporter retry settings) and you may see backpressure in the Collector logs.

### Predefined Grafana Dashboards

Grafana auto-loads dashboard JSON files from `config/grafana/dashboards/` via provisioning (see `config/grafana/provisioning/dashboards/dashboards.yml`). Included demo dashboards:

| Dashboard Title | UID | File | Highlights |
|-----------------|-----|------|------------|
| Observability Stack Overview | `obs-overview` | `observability-overview.json` | System CPU %, Memory %, Service availability table, HTTP request rate example |
| Node Exporter Overview | `node-exporter-overview` | `node-exporter-overview.json` | CPU (avg & per-core), Memory, Load, Filesystem %, Disk IO, Network throughput, Uptime |
| Kafka Overview | `kafka-overview` | `kafka-overview.json` | Topic message/byte rates, partition count, consumer lag, under-replicated partitions, log flow from Kafka to Elasticsearch |

If a dashboard doesn’t appear:
1. Ensure the file exists under `config/grafana/dashboards/`.
2. Restart Grafana: `docker compose restart grafana` (or `./manage-stack.sh restart`).
3. Check logs: `docker compose logs grafana | grep -i provisioning`.

To add your own:
1. Create/export a dashboard JSON in the Grafana UI.
2. Save it into `config/grafana/dashboards/` (plain dashboard JSON, not wrapped).
3. Set a unique `uid` to avoid clashes.
4. Restart (or wait for the `updateIntervalSeconds` to reload).

## 📁 Configuration Structure

```
config/
├── prometheus/
│   ├── prometheus.yml          # Prometheus configuration
│   └── rules/
│       └── alerts.yml          # Alerting rules
├── otel/
│   └── otel-collector-config.yaml  # OpenTelemetry Collector config
├── alertmanager/
│   └── alertmanager.yml        # AlertManager configuration
└── grafana/
    ├── provisioning/
    │   ├── datasources/        # Auto-configured data sources
    │   └── dashboards/         # Dashboard provisioning
    └── dashboards/             # Dashboard JSON files
```

## 🔧 Management Commands

The `manage-stack.sh` script provides convenient management commands:

```bash
# Start the entire stack
./manage-stack.sh start

# Stop the stack
./manage-stack.sh stop

# Restart the stack
./manage-stack.sh restart

# Check status of all services
./manage-stack.sh status

# View logs (all services or specific service)
./manage-stack.sh logs
./manage-stack.sh logs prometheus

# Clean up everything (removes containers and volumes)
./manage-stack.sh cleanup

# Show help
./manage-stack.sh help
```

## 📊 Monitoring Setup

### Metrics Collection
- **Prometheus** scrapes metrics from:
  - Application services (when deployed)
  - System metrics via Node Exporter
  - OpenTelemetry Collector metrics
  - Custom exporters

### Log Aggregation
- **OpenTelemetry Collector** receives logs via OTLP
- If Kafka profile enabled: logs are first published to **Kafka** (topic `otel-logs`) then consumed and sent to **Elasticsearch**
- If Kafka not enabled: (baseline) logs go directly to **Elasticsearch**
- **Kibana** provides log visualization and search

### Distributed Tracing
- **OpenTelemetry Collector** receives traces via OTLP
- Traces are exported to **Jaeger**
- **Jaeger UI** provides trace visualization and analysis

### Alerting
- **Prometheus** evaluates alerting rules
- **AlertManager** handles alert routing and notifications
- Configured webhooks for integration with external systems

## 🔗 Integration Endpoints

### For Application Services

#### Metrics (Prometheus format)
- Expose metrics at `/metrics` endpoint
- Prometheus will auto-discover services in the `observability` network

#### Logs (OpenTelemetry)
- Send logs to: `http://otel-collector:4318/v1/logs` (HTTP)
- Or: `otel-collector:4317` (gRPC)

#### Traces (OpenTelemetry)
- Send traces to: `http://otel-collector:4318/v1/traces` (HTTP)
- Or: `otel-collector:4317` (gRPC)

### Environment Variables for Applications
```bash
# OpenTelemetry configuration
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=your-service-name
OTEL_RESOURCE_ATTRIBUTES=service.version=1.0.0,environment=dev

# Prometheus metrics
PROMETHEUS_METRICS_PORT=9090
PROMETHEUS_METRICS_PATH=/metrics
```

## 🛠 Customization

### Adding New Services to Monitor

1. **Update Prometheus configuration** (`config/prometheus/prometheus.yml`):
   ```yaml
   scrape_configs:
     - job_name: 'your-service'
       static_configs:
         - targets: ['your-service:port']
   ```

2. **Add alerting rules** (`config/prometheus/rules/alerts.yml`):
   ```yaml
   - alert: YourServiceDown
     expr: up{job="your-service"} == 0
     for: 1m
     annotations:
       summary: "Your service is down"
   ```

3. **Restart Prometheus**:
   ```bash
   # Using the management script
   ./manage-stack.sh restart
   
   # OR using Docker Compose directly
   docker-compose restart prometheus  # or: docker compose restart prometheus
   ```

### Custom Dashboards

1. Create dashboard JSON files in `config/grafana/dashboards/`
2. Restart Grafana or wait for auto-reload:
   ```bash
   # Using the management script
   ./manage-stack.sh restart
   
   # OR restart just Grafana
   docker-compose restart grafana  # or: docker compose restart grafana
   ```

## 📈 Performance Tuning

### Resource Allocation
- **Elasticsearch**: Adjust JVM heap size via `ES_JAVA_OPTS`
- **Prometheus**: Configure retention period and storage
- **Grafana**: Set up external database for production use

### Production Considerations
1. **Security**: Enable authentication and TLS
2. **Persistence**: Use external volumes for data
3. **Scaling**: Use external managed services for production
4. **Backup**: Implement regular backup strategies

## 🚨 Alerting Configuration

### Default Alerts Configured
- Database connection pool exhaustion
- High error rates (>10%)
- High response times (>2s)
- High memory usage (>90%)
- High CPU usage (>80%)
- Service availability

### Adding Custom Webhooks
Update `config/alertmanager/alertmanager.yml` to add your webhook endpoints:

```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
```

## 🔍 Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3000, 5601, 9090, 9093, 9200, 16686 are available
2. **Memory issues**: Increase Docker memory allocation (minimum 4GB recommended)
3. **Permission issues**: Ensure proper file permissions in config directories

### Checking Logs
```bash
# View logs for specific service
./manage-stack.sh logs elasticsearch

# View all logs
./manage-stack.sh logs
```

### Health Checks
```bash
# Check service status
./manage-stack.sh status

# Manual health checks
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health # Grafana
curl http://localhost:9200/_cluster/health # Elasticsearch
```

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- How to submit bug reports and feature requests
- Development setup and testing procedures  
- Code style and documentation standards
- Pull request process

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔒 Security

Security is important to us. Please review our [Security Policy](SECURITY.md) for:

- Reporting security vulnerabilities
- Production security considerations
- Best practices and recommendations

## 🆘 Support

- **Documentation**: Check this README and the [Contributing Guide](CONTRIBUTING.md)
- **Issues**: Open an issue on GitHub for bug reports
- **Discussions**: Use GitHub Discussions for questions and ideas

## 🙏 Acknowledgments

This project uses several excellent open-source tools:

- [Prometheus](https://prometheus.io/) - Metrics collection and alerting
- [Grafana](https://grafana.com/) - Metrics visualization
- [Elasticsearch](https://www.elastic.co/) - Search and analytics engine
- [Kibana](https://www.elastic.co/kibana) - Data visualization
- [Jaeger](https://www.jaegertracing.io/) - Distributed tracing
- [OpenTelemetry](https://opentelemetry.io/) - Observability framework

## 📊 Project Status

This project is actively maintained. We aim to:

- Keep dependencies updated
- Add new observability tools as they become stable
- Improve documentation and examples
- Enhance security and production readiness
- Evolve Kubernetes deployment (Ingress, persistence, security hardening, optional operator-based stack)

When adding new components or configurations:
1. Update this README
2. Test with the management script
3. Ensure proper service discovery configuration
4. Add appropriate alerting rules
 5. If applicable, mirror changes in `kubernetes/` manifests & docs
