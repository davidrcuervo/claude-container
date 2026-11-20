#!/usr/bin/env bash
#
# Starts a socat listener that reroutes traffic between internal network
# interfaces, runs the Docker container that depends on it, and tears the
# listener down automatically once the container exits.

set -euo pipefail

# PID of the background socat process; populated once it starts.
SOCAT_PID=""
DOCKER_COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/docker-compose.yml"

cleanup() {
    if [[ -n "${SOCAT_PID}" ]] && kill -0 "${SOCAT_PID}" 2>/dev/null; then
        echo "Stopping socat listener (PID ${SOCAT_PID})..."
        kill "${SOCAT_PID}" 2>/dev/null || true
        wait "${SOCAT_PID}" 2>/dev/null || true
    fi
}

# Ensure the listener is closed on normal exit, Ctrl-C, or termination.
trap cleanup EXIT INT TERM

echo "Starting socat listener on 172.17.0.1:7755 -> 127.0.0.1:6655..."
socat TCP-LISTEN:7755,fork,reuseaddr,bind=172.17.0.1 TCP:127.0.0.1:6655 & SOCAT_PID=$!

# Give socat a moment to bind before launching the dependent container.
sleep 1

echo "Running Docker container..."
docker compose -f "$DOCKER_COMPOSE_FILE" run -it \
--volume "$(pwd)":/home/claudia/work \
--volume "$(pwd)/.claude_config":/home/claudia/.claude \
--rm claude

# When docker compose returns (utility finished), the EXIT trap runs cleanup.
echo "Container finished; listener will be closed."