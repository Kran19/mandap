#!/usr/bin/env bash
# ==============================================================================
# Mandap Live Server Deployment Script
# Usage: ./deploy.sh [branch]
# Example: ./deploy.sh main
# ==============================================================================

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

if [ -f "$ROOT_DIR/docker-compose.prod.yml" ]; then
    COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"
    WORKDIR="$ROOT_DIR"
elif [ -f "$ROOT_DIR/adminpanel/docker-compose.prod.yml" ]; then
    COMPOSE_FILE="$ROOT_DIR/adminpanel/docker-compose.prod.yml"
    WORKDIR="$ROOT_DIR/adminpanel"
else
    echo_error "Could not locate docker-compose.prod.yml"
    exit 1
fi

echo_info "Deployment Root: $ROOT_DIR"
echo_info "Compose File: $COMPOSE_FILE"

# 2. Check Docker command
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo_error "Neither 'docker compose' nor 'docker-compose' was found. Please install Docker."
    exit 1
fi

echo_info "Using compose tool: $DOCKER_COMPOSE"

# 3. Git pull latest code
BRANCH="${1:-$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")}"
echo_info "Pulling latest changes from branch: ${CYAN}$BRANCH${NC}..."

git -C "$ROOT_DIR" fetch --all
git -C "$ROOT_DIR" pull origin "$BRANCH"

LATEST_COMMIT=$(git -C "$ROOT_DIR" log -1 --oneline)
echo_success "Current commit: $LATEST_COMMIT"

# 4. Build Docker containers
echo_info "Building Docker images..."
cd "$WORKDIR"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" build --pull

# 5. Run Prisma migrations / sync database schema
echo_info "Running database migrations..."
if $DOCKER_COMPOSE -f "$COMPOSE_FILE" run --rm api npx prisma migrate deploy; then
    echo_success "Prisma migrations applied successfully."
else
    echo_warn "migrate deploy encountered an issue, running prisma db push as fallback..."
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" run --rm api npx prisma db push
fi

# 6. Start / restart services in background
echo_info "Starting containers..."
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d --remove-orphans

# 7. Cleanup dangling docker images
echo_info "Cleaning up unused Docker images..."
docker image prune -f || true

# 8. Show container status
echo_info "Checking container status:"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" ps

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN} Deployment completed successfully!${NC}"
echo -e "${GREEN} API URL:      http://<SERVER_IP>:5000/api/v1${NC}"
echo -e "${GREEN} Admin Panel:  http://<SERVER_IP>:5050${NC}"
echo -e "${GREEN}======================================================${NC}"
