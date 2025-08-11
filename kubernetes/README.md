# Kubernetes Deployment

This directory contains Kubernetes manifests and Kustomize overlays to deploy the observability toolkit and the example `o11y-python` application onto a Kubernetes cluster (tested with Kind). It mirrors the docker-compose experience while adding namespace separation, optional in‑cluster image build, and auto‑provisioned Grafana dashboards.

## Layout

- `kustomization.yaml` – Root Kustomize entrypoint (deploys observability + app namespaces and aggregates resources).
- `observability/` – Prometheus, Grafana, Jaeger (all-in-one), OpenTelemetry Collector, Alertmanager, Elasticsearch, Kibana, Node Exporter, Kafka (optional), Kafka JMX exporter, internal registry (experimental).
- `observability/grafana/` – Deployment plus ConfigMaps for datasources and dashboards provisioning.
- `applications/o11y-python/` – Example Python service exporting OTLP traces/metrics/logs to the collector.
- `applications/o11y-python/build-job.yaml` – Kaniko Job template (generateName) for optional in‑cluster build.
- `applications/o11y-python/build.sh` – Helper to launch the build Job.
- `kind/` – Local Kind cluster definition & helper script (cluster with extraNodePorts & containerd patches attempt for internal registry).
- `deploy.sh` – Convenience script to apply everything with optional waits.

## Current Status

All core components (Prometheus, Grafana, Alertmanager, OpenTelemetry Collector, Jaeger, Elasticsearch, Kibana, Node Exporter) deploy and run successfully under the `observability` namespace. The sample app runs in its own `o11y-python` namespace.

Grafana dashboards are auto‑provisioned (see below). Kibana memory was tuned to avoid JavaScript heap OOM (increased limits + `NODE_OPTIONS`).

An internal registry + Kaniko build path exists but containerd inside Kind may not resolve the cluster-internal registry DNS without extra configuration; a reliable fallback (pre‑loading the image into Kind) is documented. See Build section & troubleshooting.

## Quick Start (Kind)

```bash
cd kubernetes/kind
./setup.sh
```

After pods are ready, either access via NodePort (if enabled) or port-forward:
```bash
kubectl -n observability port-forward svc/grafana 3000:3000 &
kubectl -n observability port-forward svc/prometheus 9090:9090 &
kubectl -n observability port-forward svc/jaeger-query 16686:16686 &
kubectl -n observability port-forward svc/kibana 5601:5601 &
```

NodePorts (example – adjust if you changed manifests):
- Grafana: 30000
- Prometheus: 30900
- Jaeger UI: 31686

You can instead expose via an Ingress (not yet provided – see Roadmap).

## Generic Cluster

```bash
cd kubernetes
./deploy.sh --wait
```
Then port-forward or expose via Ingress (not provided by default).

## Building the Example App Image

Two options:

1. External build (recommended & current default):
```bash
docker build -t o11y-python:latest ../../o11y-playground/o11y-python
kind load docker-image o11y-python:latest --name observability
```
Deployment `applications/o11y-python/deployment.yaml` should have `image: o11y-python:latest` for this path (default in repo).

2. In-cluster build (Kaniko + internal registry, experimental):
	- Registry Service: `registry.observability.svc:5000` (ClusterIP) & DNS FQDN `registry.observability.svc.cluster.local`.
	- Launch build using `build.sh` (creates a `kaniko` Job with a unique name via `generateName`).
	- The Job contains an inline Dockerfile with pinned dependencies (no context mount needed).
	- Limitation: Kind's containerd may not pull from the in‑cluster Service DNS without additional node-level registry mirror configuration. If image pulls fail (`ImagePullBackOff`), use the external build fallback above.

Run build:
```bash
cd kubernetes/applications/o11y-python
./build.sh
kubectl -n o11y-python logs -f job/$(kubectl -n o11y-python get jobs --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
```

After success (and once registry pull issues are resolved, if using internal registry), restart app:
```bash
kubectl -n o11y-python rollout restart deployment/o11y-python
```

If the rollout fails to pull, switch the image back to `o11y-python:latest` and pre‑load it with `kind load docker-image`.

### Switching Between Build Modes

Edit `applications/o11y-python/deployment.yaml`:
- Internal registry mode: `image: registry.observability.svc.cluster.local:5000/o11y-python:latest`
- Preloaded local image mode: `image: o11y-python:latest`

Remember to `kubectl apply -k kubernetes` (or re-run `deploy.sh`) after modifying the deployment.

## Grafana Dashboards Provisioning

Grafana is configured with:
- Datasources ConfigMap: automatically sets Prometheus, Elasticsearch, Jaeger, and Loki (if later added) endpoints.
- Dashboards ConfigMaps: JSON files mounted at `/var/lib/grafana/dashboards`.
- Provisioning provider ConfigMap: points Grafana to load all dashboards in that directory and auto‑scan (supports periodic reloads).

Add a new dashboard:
1. Export from the Grafana UI (or author JSON) with a unique `uid`.
2. Append it to the dashboards ConfigMap (or create a new one) under `observability/grafana/`.
3. Re-apply: `kubectl apply -k kubernetes/observability` (or root kustomization).
4. (Optional) Restart Grafana: `kubectl -n observability rollout restart deploy/grafana`.

Dashboards included: observability overview, node exporter overview, Kafka overview.

## Customization

You can adjust component resources or disable optional components by editing `observability/kustomization.yaml` (comment out resources).

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|--------------|-----------|
| `ImagePullBackOff` for app image referencing internal registry | Kind containerd can't resolve/pull from cluster Service DNS | Use external build + `kind load docker-image`, or configure Kind with a registry mirror mapping hostPort to the Service (future improvement) |
| Kibana `JavaScript heap out of memory` crash loops | Default memory limit too low for Kibana / Elasticsearch index patterns migration | Increased memory limit (1Gi) + set `NODE_OPTIONS=--max-old-space-size=1024` (already applied) |
| Grafana dashboards missing | ConfigMap not mounted / provisioning mismatch | Ensure deployment has volumes for dashboards + provider, verify ConfigMap names and re-apply |
| Kaniko Job fails to find context files | Inline Dockerfile expects no external context | Ensure you haven't edited build job to reference local files unless mounting them |

Collect diagnostics:
```bash
kubectl get pods -n observability
kubectl describe pod <pod> -n observability
kubectl logs -n observability <pod> --tail=200
```

## Roadmap / Next Steps

- Ingress / Gateway for external access.
- PersistentVolumeClaims for Prometheus & Grafana (and Elasticsearch tuning / PVC storage class parameterization).
- Optional Prometheus Operator (ServiceMonitor / PodMonitor resources) overlay.
- Refined internal registry solution (node-level mirror or local registry container bound to host network).
- Security hardening: RBAC least privilege, NetworkPolicies, PodSecurity standards, non-root containers, TLS.
- Parameterization via Kustomize vars / Helm chart for easier environment-specific overrides.
- Loki + Tempo optional add-ons for logs/traces alternative backends.

## Contributing

Improvements to this Kubernetes deployment are welcome. Keep the docker-compose and Kubernetes feature sets aligned where practical, document new components, and add minimal sane defaults (avoid over-complicating the demo footprint).

