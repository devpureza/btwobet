#!/usr/bin/env bash
# Executar UMA VEZ na EC2 (Ubuntu 22.04/24.04) como usuário com sudo.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl git

# Docker
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "Reconecte o SSH para usar docker sem sudo."
fi

# Docker Compose plugin
if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get install -y docker-compose-plugin
fi

DEPLOY_DIR="${DEPLOY_DIR:-/opt/btwobet}"
sudo mkdir -p "$DEPLOY_DIR"
sudo chown "$USER:$USER" "$DEPLOY_DIR"

echo "OK. Clone o repositório em $DEPLOY_DIR e configure .env.production"
