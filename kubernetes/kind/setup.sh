#!/usr/bin/env bash
set -euo pipefail
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
