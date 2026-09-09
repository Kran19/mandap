# ==============================================================================
# Mandap Live Server Deployment Script (PowerShell)
# Usage: .\deploy.ps1 [-Branch <branch>]
# Example: .\deploy.ps1 -Branch main
# ==============================================================================

param(
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) {
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-Success($msg) {
    Write-Host "[SUCCESS] $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}

function Write-Err($msg) {
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

$RootDir = $PSScriptRoot
$ComposeFile = Join-Path $RootDir "adminpanel\docker-compose.prod.yml"
$WorkDir = Join-Path $RootDir "adminpanel"

if (-not (Test-Path $ComposeFile)) {
    Write-Err "Could not find $ComposeFile"
    exit 1
}

# 1. Determine active branch if not specified
if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = git -C $RootDir rev-parse --abbrev-ref HEAD 2>$null
    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = "main"
    }
}

# 2. Git pull latest code
Write-Info "Pulling latest changes from branch: $Branch..."
git -C $RootDir fetch --all
git -C $RootDir pull origin $Branch

$LatestCommit = git -C $RootDir log -1 --oneline
Write-Success "Current commit: $LatestCommit"

# 3. Build Docker containers
Write-Info "Building Docker images..."
Set-Location $WorkDir
docker compose -f $ComposeFile build --pull

# 4. Run database migrations
Write-Info "Running database migrations..."
try {
    docker compose -f $ComposeFile run --rm api npx prisma migrate deploy
    Write-Success "Prisma migrations applied successfully."
} catch {
    Write-Warn "migrate deploy encountered an issue, running prisma db push as fallback..."
    docker compose -f $ComposeFile run --rm api npx prisma db push
}

# 5. Start / restart services in background
Write-Info "Starting containers..."
docker compose -f $ComposeFile up -d --remove-orphans

# 6. Cleanup dangling docker images
Write-Info "Cleaning up unused Docker images..."
docker image prune -f

# 7. Check container status
Write-Info "Container status:"
docker compose -f $ComposeFile ps

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Deployment completed successfully!" -ForegroundColor Green
Write-Host " API URL:      http://<SERVER_IP>:5000/api/v1" -ForegroundColor Green
Write-Host " Admin Panel:  http://<SERVER_IP>:5050" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
