#!/usr/bin/env bash
#
# Starts a socat listener that reroutes traffic between internal network
# interfaces, runs the Docker container that depends on it, and tears the
# listener down automatically once the container exits.

set -euo pipefail

DOCKER_COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"
# echo "BASH_SOURCE[0] $DOCKER_COMPOSE_FILE"

# echo "Running Docker container..."
docker compose -f "$DOCKER_COMPOSE_FILE" run -it \
--rm claude
# --volume "$(pwd)":/home/claudia/work \
# --volume "$(pwd)/.claude_config":/home/claudia/.claude \

# # When docker compose returns (utility finished), the EXIT trap runs cleanup.
echo "Container finished; listener will be closed."