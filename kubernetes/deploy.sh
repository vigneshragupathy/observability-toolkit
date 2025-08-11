#!/usr/bin/env bash
set -euo pipefail

# Deploy full observability stack + example app using kustomize
# Usage: ./deploy.sh [--namespace-observability NAME] [--namespace-app NAME] [--wait]

OBS_NS=observability
APP_NS=o11y-python
WAIT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace-observability)
      OBS_NS=$2; shift 2;;
    --namespace-app)
      APP_NS=$2; shift 2;;
    --wait)
      WAIT=true; shift;;
    *) echo "Unknown flag $1"; exit 1;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -k "${SCRIPT_DIR}" >/dev/null

echo "Applied manifests. Namespaces: ${OBS_NS}, ${APP_NS}" >&2

if $WAIT; then
  echo "Waiting for core deployments..." >&2
  kubectl -n "$OBS_NS" rollout status deployment/prometheus --timeout=180s || true
  kubectl -n "$OBS_NS" rollout status deployment/grafana --timeout=180s || true
  kubectl -n "$OBS_NS" rollout status deployment/jaeger --timeout=180s || true
  kubectl -n "$OBS_NS" rollout status deployment/otel-collector --timeout=180s || true
  kubectl -n "$APP_NS" rollout status deployment/o11y-python --timeout=180s || true
fi

echo "To port-forward (example):" >&2
echo "kubectl -n ${OBS_NS} port-forward svc/grafana 3000:3000" >&2
echo "kubectl -n ${OBS_NS} port-forward svc/prometheus 9090:9090" >&2
echo "kubectl -n ${OBS_NS} port-forward svc/jaeger-query 16686:16686" >&2
