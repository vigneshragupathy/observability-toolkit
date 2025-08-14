#!/usr/bin/env bash
set -euo pipefail

# Show help function
show_help() {
  cat << EOF
Usage: $0 [OPTIONS]

Set up a Kind Kubernetes cluster with observability stack.

OPTIONS:
  -h, --help          Show this help message and exit
  --cluster-name NAME Set cluster name (default: observability)
  --config FILE       Path to Kind cluster config (default: ./cluster.yaml)

ENVIRONMENT VARIABLES:
  CLUSTER_NAME        Cluster name to use (default: observability)
  KIND_CONFIG         Path to Kind cluster config file

EXAMPLES:
  $0                           # Create cluster with defaults
  $0 --cluster-name my-cluster # Create cluster with custom name
  $0 --config /path/to/config  # Use custom config file

SERVICES EXPOSED:
  Grafana:      http://localhost:3000
  Prometheus:   http://localhost:9090
  Jaeger UI:    http://localhost:16686
  Kibana:       http://localhost:5601
  Alertmanager: http://localhost:9093

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --config)
      KIND_CONFIG="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information." >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME=${CLUSTER_NAME:-observability}
KIND_CONFIG=${KIND_CONFIG:-${SCRIPT_DIR}/cluster.yaml}

if ! command -v kind >/dev/null 2>&1; then
  echo "Kind not installed. Install from https://kind.sigs.k8s.io/" >&2
  exit 1
fi

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster ${CLUSTER_NAME} already exists. Skipping creation." >&2
else
  echo "Creating kind cluster ${CLUSTER_NAME}..." >&2
  kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}" >&2
fi

echo "Applying kustomize manifests..." >&2
kubectl apply -k "${SCRIPT_DIR}/.." >&2

echo "Waiting for core deployments..." >&2
kubectl -n observability rollout status deployment/prometheus --timeout=180s || true
kubectl -n observability rollout status deployment/grafana --timeout=180s || true
kubectl -n observability rollout status deployment/jaeger --timeout=180s || true
kubectl -n observability rollout status deployment/otel-collector --timeout=180s || true
kubectl -n o11y-python rollout status deployment/o11y-python --timeout=180s || true

echo "Done. Access UIs:" >&2
echo "Grafana:     http://localhost:3000" >&2
echo "Prometheus:  http://localhost:9090" >&2
echo "Jaeger UI:   http://localhost:16686" >&2
echo "Kibana:      http://localhost:5601" >&2
echo "Alertmanager:http://localhost:9093" >&2
