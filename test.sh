#!/usr/bin/env bash
echo "pwd= $(pwd)"

DOCKER_COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/docker-compose.yml"
echo "DOCKER_COMPOSE_FILE= $DOCKER_COMPOSE_FILE"