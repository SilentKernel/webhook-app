#!/usr/bin/env bash
set -euo pipefail

REGISTRY="registry.developpeur-freelance.io"
IMAGE_NAME="silent/hoostack"
COMPOSE_FILE="docker-compose.prod.yml"

# Resolve image tag from current commit
IMAGE_TAG="$(git rev-parse --short HEAD)"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "==> Deploying ${FULL_IMAGE}"

# Pull the new image
echo "==> Pulling image..."
docker pull "$FULL_IMAGE"

# Export tag so Compose picks it up
export IMAGE_TAG

# Rolling deploy of the app service (zero downtime)
echo "==> Rolling out app..."
docker rollout -f "$COMPOSE_FILE" app

# Update the worker (not user-facing, standard restart)
echo "==> Updating worker..."
docker compose -f "$COMPOSE_FILE" up -d worker

# Run database migrations
echo "==> Running migrations..."
docker compose -f "$COMPOSE_FILE" exec app bin/rails db:migrate

echo ""
echo "==> Deploy complete (${IMAGE_TAG})"
