#!/bin/bash

# Observability Stack Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
# Enable Kafka profile by default; can be disabled with --no-kafka
EXTRA_PROFILES="kafka"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[OBSERVABILITY]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
}

# Function to start the observability stack
start_stack() {
    print_header "Starting Observability Stack..."
    
    check_docker
    check_docker_compose
    
    # Create necessary directories if they don't exist
    mkdir -p "$SCRIPT_DIR/config"
    
    local compose_cmd=("$DOCKER_COMPOSE_CMD" -f "$COMPOSE_FILE")
    if [[ -n "$EXTRA_PROFILES" ]]; then
        print_status "Enabling profiles: $EXTRA_PROFILES"
        compose_cmd+=(--profile "$EXTRA_PROFILES")
    fi
    print_status "Starting services..."
    "${compose_cmd[@]}" up -d
    
    print_status "Waiting for services to be ready..."
    sleep 10
    
    print_header "Observability Stack Status:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ Service         │ URL                      │ Status         │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ Prometheus      │ http://localhost:9090    │ Metrics        │"
    echo "│ Grafana         │ http://localhost:3000    │ Dashboards     │"
    echo "│ Jaeger UI       │ http://localhost:16686   │ Tracing        │"
    echo "│ Kibana          │ http://localhost:5601    │ Logs           │"
    echo "│ AlertManager    │ http://localhost:9093    │ Alerts         │"
    echo "│ Elasticsearch   │ http://localhost:9200    │ Log Storage    │"
    echo "│ OTEL Collector  │ http://localhost:4317    │ Data Pipeline  │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    print_status "Default Grafana credentials: admin/admin"
    print_status "All services are starting up. Please wait a moment for full initialization."
}

# Function to stop the observability stack
stop_stack() {
    print_header "Stopping Observability Stack..."
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" down
    print_status "All services stopped."
}

# Function to restart the observability stack
restart_stack() {
    print_header "Restarting Observability Stack..."
    stop_stack
    sleep 5
    start_stack
}

# Function to show logs
show_logs() {
    local service="$1"
    if [ -z "$service" ]; then
        print_status "Showing logs for all services..."
        $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" logs -f
    else
        print_status "Showing logs for $service..."
        $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" logs -f "$service"
    fi
}

# Function to show status
show_status() {
    print_header "Observability Stack Status:"
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps
    
    echo ""
    print_header "Service Health Checks:"
    
    # Check service health
    services=(
        "Prometheus|http://localhost:9090/-/healthy"
        "Grafana|http://localhost:3000/api/health"
        "Jaeger|http://localhost:16686/"
        "Kibana|http://localhost:5601/api/status"
        "Elasticsearch|http://localhost:9200/_cluster/health"
        "AlertManager|http://localhost:9093/-/healthy"
    )
    
    for service_url in "${services[@]}"; do
        IFS='|' read -r service_name url <<< "$service_url"
        if curl -s "$url" >/dev/null 2>&1; then
            echo -e "✅ $service_name: ${GREEN}Healthy${NC}"
        else
            echo -e "❌ $service_name: ${RED}Unhealthy${NC}"
        fi
    done

    # Optional components (Kafka & UI) only if containers exist
    if $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps -q kafka >/dev/null 2>&1; then
        # Kafka health: simple TCP connectivity check to advertised host port 29092
        if bash -c '>/dev/tcp/127.0.0.1/29092' 2>/dev/null; then
            echo -e "✅ Kafka: ${GREEN}Reachable (port 29092)${NC}"
        else
            echo -e "❌ Kafka: ${RED}Port not reachable${NC}"
        fi
    fi
    if $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps -q kafka-ui >/dev/null 2>&1; then
        if curl -s http://localhost:8085/ >/dev/null 2>&1; then
            echo -e "✅ Kafka UI: ${GREEN}Healthy${NC}"
        else
            echo -e "❌ Kafka UI: ${RED}Unhealthy${NC}"
        fi
    fi
    if $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps -q kafka-jmx-exporter >/dev/null 2>&1; then
        if curl -s http://localhost:5556/metrics >/dev/null 2>&1; then
            echo -e "✅ Kafka JMX Exporter: ${GREEN}Healthy${NC}"
        else
            echo -e "❌ Kafka JMX Exporter: ${RED}Unhealthy${NC}"
        fi
    fi
}

# Function to clean up (remove containers and volumes)
cleanup() {
    print_warning "This will remove all containers and data volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_header "Cleaning up Observability Stack..."
        $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" down -v --remove-orphans
        docker system prune -f
        print_status "Cleanup completed."
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show help
show_help() {
    echo "Observability Stack Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start     Start the observability stack (Kafka enabled by default; use --no-kafka to disable)"
    echo "  stop      Stop the observability stack"
    echo "  restart   Restart the observability stack"
    echo "  status    Show status of all services"
    echo "  logs      Show logs (optional: specify service name)"
    echo "  cleanup   Remove all containers and volumes"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs prometheus"
    echo "  $0 status"
}

# Main script logic
while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-kafka)
            # Backwards compatibility: already default; no-op
            shift ;;
        --no-kafka)
            EXTRA_PROFILES=""
            shift ;;
        start|stop|restart|status|logs|cleanup|help|--help|-h)
            MAIN_CMD="$1"; shift; break ;;
        *)
            MAIN_CMD="$1"; shift; break ;;
    esac
done

case "${MAIN_CMD:-${1:-}}" in
    start)
        check_docker_compose
        start_stack
        ;;
    stop)
        check_docker_compose
        stop_stack
        ;;
    restart)
        check_docker_compose
        restart_stack
        ;;
    status)
        check_docker_compose
        show_status
        ;;
    logs)
        check_docker_compose
        show_logs "$2"
        ;;
    cleanup)
        check_docker_compose
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_error "No command specified."
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
