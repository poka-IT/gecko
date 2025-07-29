#!/usr/bin/env bash
set -euo pipefail

# Force English output for commands that honor locale
export LANG=C
export LC_ALL=C

trap clean_duniter EXIT ERR

clean_duniter() {
  docker compose down -v
  rm -rf data/chains/gdev
}

#############################################
# Ensure Docker daemon is running
#############################################
start_docker() {
  # Already running?
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  OS="$(uname -s)"
  case "$OS" in
    Linux)
      if command -v systemctl >/dev/null 2>&1; then
        echo "[INFO] Starting Docker via systemctl..."
        sudo systemctl start docker 2>/dev/null || true
      fi
      if ! docker info >/dev/null 2>&1 && command -v service >/dev/null 2>&1; then
        echo "[INFO] Starting Docker via service..."
        sudo service docker start 2>/dev/null || true
      fi
      if ! docker info >/dev/null 2>&1 && command -v dockerd >/dev/null 2>&1; then
        echo "[INFO] Launching dockerd directly in background..."
        sudo dockerd >/dev/null 2>&1 &
      fi
      ;;
    Darwin)
      # Try Docker Desktop
      if [ -d "/Applications/Docker.app" ] || [ -d "/Applications/Docker Desktop.app" ]; then
        echo "[INFO] Opening Docker Desktop..."
        open -ga "Docker" || open -ga "Docker Desktop" || true
      fi
      # Try Colima
      if ! docker info >/dev/null 2>&1 && command -v colima >/dev/null 2>&1; then
        echo "[INFO] Starting Colima..."
        colima start >/dev/null 2>&1 &
      fi
      ;;
    *)
      echo "[WARN] Unsupported OS: $OS" >&2
      ;;
  esac

  echo "[INFO] Waiting for Docker daemon..."
  for i in {1..60}; do
    if docker info >/dev/null 2>&1; then
      echo "[INFO] Docker is up."
      return 0
    fi
    sleep 1
  done

  echo "[ERROR] Docker did not respond after 60s. Exiting." >&2
  exit 1
}

#############################################
# Main script
#############################################
start_docker

cd integration_test/duniter/

echo "[INFO] Stopping and removing previous stack..."
docker compose down -v

echo "[INFO] Cleaning chain data..."
rm -rf /Users/poka/dev/gecko/integration_test/duniter/data/chains/gdev

echo "[INFO] Starting stack..."
docker compose up -d

echo "[INFO] Tailing last 50 lines of logs (follow mode)..."
docker compose logs -f -n50

# echo "[INFO] Waiting for Squid to be ready..."
# cd ../squid
# docker compose down -v
# docker compose up -d
