#!/usr/bin/env bash
# Roda na EC2 após git pull / rsync do código.
set -euo pipefail

cd "${DEPLOY_DIR:-/opt/btwobet}"

if [ ! -f .env.production ]; then
  echo "Crie .env.production a partir de .env.production.example"
  exit 1
fi

if [[ ! -f deploy/caddy/certs/cert.pem ]]; then
  chmod +x deploy/caddy/generate-ip-cert.sh
  DEPLOY_IP="${DEPLOY_IP:-184.73.154.194}"
  DOMAIN="$(grep -E '^DOMAIN=' .env.production 2>/dev/null | cut -d= -f2- | tr -d '"' || echo btwobet.click)"
  ./deploy/caddy/generate-ip-cert.sh "$DEPLOY_IP" "$DOMAIN"
fi

# Gera APP_KEY se ainda não existir
if ! grep -q '^APP_KEY=base64:' .env.production 2>/dev/null; then
  KEY=$(docker compose -f docker-compose.prod.yml --env-file .env.production run --rm --no-deps \
    --entrypoint php app artisan key:generate --show)
  if grep -q '^APP_KEY=' .env.production; then
    awk -v key="$KEY" '/^APP_KEY=/{print "APP_KEY=" key; next} {print}' .env.production > .env.production.tmp \
      && mv .env.production.tmp .env.production
  else
    echo "APP_KEY=${KEY}" >> .env.production
  fi
fi

docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build --remove-orphans
docker compose -f docker-compose.prod.yml --env-file .env.production exec -T app php artisan migrate --force

echo "Deploy concluído. Teste: curl -s http://127.0.0.1/api/health"
