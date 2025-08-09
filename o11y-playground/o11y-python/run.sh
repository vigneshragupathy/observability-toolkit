#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="o11y-python"
NETWORK="observability"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }

# Detect docker compose command (plugin vs legacy)
compose_cmd() {
  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo "docker compose"
  fi
}

ensure_network() {
  if ! docker network inspect "${NETWORK}" >/dev/null 2>&1; then
    log "Creating network ${NETWORK}"
    docker network create "${NETWORK}"
  else
    log "Network ${NETWORK} already exists"
  fi
}

up() {
  ensure_network
  local CMD
  CMD="$(compose_cmd) -f ${COMPOSE_FILE} up -d --build"
  log "Starting ${APP_NAME} container"
  eval "$CMD"
  # Simple reachability check to collector (graceful warning only)
  if ! docker run --rm --network ${NETWORK} busybox sh -c "nc -z otel-collector 4317" >/dev/null 2>&1; then
    warn "Could not reach otel-collector:4317. Ensure the observability stack is running if you expect telemetry export."
  else
    log "otel-collector reachable. Telemetry should flow."
  fi
  log "${APP_NAME} running at http://localhost:8000"
}

down() {
  local CMD
  CMD="$(compose_cmd) -f ${COMPOSE_FILE} down"
  log "Stopping ${APP_NAME} container"
  eval "$CMD"
}

restart() {
  down || true
  up
}

logs() {
  local CMD
  CMD="$(compose_cmd) -f ${COMPOSE_FILE} logs -f ${APP_NAME}"
  log "Tailing logs (Ctrl+C to exit)"
  eval "$CMD"
}

status() {
  local CMD
  CMD="$(compose_cmd) -f ${COMPOSE_FILE} ps"
  eval "$CMD"
}

sample_traffic() {
  log "Sending sample traffic to endpoints"
  for ep in / /work /error; do
    echo "---- GET $ep"; curl -s -w "\n" "http://localhost:8000$ep" || true
  done
  log "Burst /work requests"
  for i in $(seq 1 10); do curl -s "http://localhost:8000/work" >/dev/null || true; done
  log "Done"
}

usage() {
  cat <<EOF
Usage: ./run.sh <command>

Commands:
  up             Build & start the demo app
  down           Stop and remove the container
  restart        Restart the container
  logs           Follow logs
  status         Show container status
  traffic        Generate sample traffic
  help           Show this help

Examples:
  ./run.sh up
  ./run.sh logs
  ./run.sh traffic
EOF
}

cmd="${1:-help}"
case "$cmd" in
  up) up ;;
  down) down ;;
  restart) restart ;;
  logs) logs ;;
  status) status ;;
  traffic) sample_traffic ;;
  help|-h|--help) usage ;;
  *) err "Unknown command: $cmd"; usage; exit 1 ;;
esac
