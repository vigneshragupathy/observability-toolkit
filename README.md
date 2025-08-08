# Observability Toolkit

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.0%2B-blue)](https://docs.docker.com/compose/)

A comprehensive, production-ready observability stack that provides metrics collection, log aggregation, distributed tracing, and alerting capabilities using industry-standard open-source tools.

## ✨ Features

- **📊 Metrics Collection**: Prometheus with custom alerting rules
- **📈 Visualization**: Pre-configured Grafana dashboards
- **📋 Log Aggregation**: Elasticsearch + Kibana for centralized logging
- **🔍 Distributed Tracing**: Jaeger for request tracing
- **🚨 Alerting**: AlertManager with webhook integrations
- **🔄 Data Pipeline**: OpenTelemetry Collector for data processing
- **🖥️ System Monitoring**: Node Exporter for host metrics
- **🛠️ Easy Management**: Convenient shell script for operations

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

## ⚠️ Security Notice

**This toolkit is configured for development/testing environments. For production use, please review and implement the security measures outlined in [SECURITY.md](SECURITY.md).**

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB of available RAM
- 10GB of free disk space

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

4. **Using Docker Compose directly:**
   ```bash
   docker-compose up -d
   ```

### Accessing the Services

After starting the stack, you can access the following services:

- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Jaeger Tracing**: http://localhost:16686
- **Kibana Logs**: http://localhost:5601
- **AlertManager**: http://localhost:9093

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
- Logs are forwarded to **Elasticsearch**
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
   docker-compose restart prometheus
   ```

### Custom Dashboards

1. Create dashboard JSON files in `config/grafana/dashboards/`
2. Restart Grafana or wait for auto-reload:
   ```bash
   docker-compose restart grafana
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

When adding new components or configurations:
1. Update this README
2. Test with the management script
3. Ensure proper service discovery configuration
4. Add appropriate alerting rules
