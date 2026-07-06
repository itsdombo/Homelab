#!/usr/bin/env bash
#
# Homelab GitOps reconcile.
#
# Pulls the repo to match origin, then brings this host's stack up to date.
# Idempotent and safe to run on a timer. The repo is authoritative: local
# edits to tracked files are discarded on every run, so never edit the repo
# on a deploy host. Gitignored files (your .env) are untracked and survive.
#
# Runs as root (needs the Docker socket). Configure via environment:
#   HOMELAB_HOST      which hosts/<name>/ dir to deploy   (default: hostname)
#   HOMELAB_REPO_DIR  where the repo is cloned            (default: /opt/homelab)
#   HOMELAB_BRANCH    branch to track                     (default: main)

set -euo pipefail

REPO_DIR="${HOMELAB_REPO_DIR:-/opt/homelab}"
BRANCH="${HOMELAB_BRANCH:-main}"
HOST="${HOMELAB_HOST:-$(hostname)}"

cd "$REPO_DIR"

# 1. Make the working tree match origin exactly (authoritative pull).
git fetch --quiet origin "$BRANCH"
git reset --hard --quiet "origin/$BRANCH"

HOST_DIR="hosts/$HOST"
COMPOSE_FILE="$HOST_DIR/compose.yaml"
ENV_FILE="$HOST_DIR/.env"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "No compose file for '$HOST' ($COMPOSE_FILE); skipping." >&2
    exit 0
fi
if [ ! -f "$ENV_FILE" ]; then
    echo "Missing $ENV_FILE; copy $HOST_DIR/.env.example to it." >&2
    exit 1
fi

compose() {
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

# 2. Pull newer images (honours the tag you pinned in each service) and
#    reconcile running containers to the compose files.
compose pull --quiet
compose up -d --remove-orphans

# 3. Reclaim disk from images the pull just superseded.
docker image prune -f >/dev/null

echo "Reconciled host '$HOST' at $(git rev-parse --short HEAD)."
