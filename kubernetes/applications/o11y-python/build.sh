#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS=$(date +%s)
TMP=$(mktemp)
# Substitute build timestamp annotation to ensure a unique job name and avoid cache reuse issues
sed "s/{{BUILD_TIMESTAMP}}/${TS}/g" "${DIR}/build-job.yaml" > "${TMP}"
# Ensure namespace exists
kubectl apply -f "${DIR}/../namespace.yaml" >/dev/null 2>&1 || true
# Apply (or re-apply) source ConfigMap (it's embedded in build-job.yaml already but kept separate step if later extracted)
# kubectl apply -f "${DIR}/o11y-python-source-configmap.yaml" 2>/dev/null || true
# Create a new build job (generateName ensures uniqueness)
kubectl create -f "${TMP}"
JOB_NAME=$(kubectl -n o11y-python get jobs --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
rm -f "${TMP}"
echo "Created job: ${JOB_NAME}" >&2
echo "Follow logs: kubectl -n o11y-python logs -f job/${JOB_NAME}" >&2
