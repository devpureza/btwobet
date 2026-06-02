#!/usr/bin/env bash
# Atualiza só o bundle Flutter Web em produção (volume ./mobile/build/web → nginx).
# Não recria DB, não roda migrate/seed/import. Uso na EC2:
#   cd /opt/btwobet && git pull origin main && ./deploy/flutter-web-prod.sh
set -euo pipefail

ROOT="${DEPLOY_DIR:-/opt/btwobet}"
cd "$ROOT"

if [[ ! -f .env.production ]]; then
  echo "ERRO: .env.production ausente em $ROOT"
  exit 1
fi

DOMAIN="$(grep -E '^APP_URL=' .env.production 2>/dev/null | cut -d= -f2- | tr -d '"' | sed 's#/$##')"
BASE="${DOMAIN:-https://btwobet.click}"
API_BASE_URL="${API_BASE_URL:-${BASE}/api}"

if command -v flutter >/dev/null 2>&1; then
  echo ">> flutter build web (API_BASE_URL=$API_BASE_URL)"
  (cd mobile && flutter pub get && flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL")
elif [[ ! -f mobile/build/web/main.dart.js ]]; then
  echo "ERRO: Flutter não instalado e mobile/build/web/main.dart.js ausente."
  echo "      Faça build local/CI e rsync de mobile/build/web/ para o servidor."
  exit 1
else
  echo ">> Usando bundle existente em mobile/build/web (sem rebuild)"
fi

if [[ ! -f deploy/caddy/certs/cert.pem || ! -f deploy/caddy/certs/key.pem ]]; then
  echo ">> Cert TLS ausente; gerando autoassinado (IP/domínio)"
  chmod +x deploy/caddy/generate-ip-cert.sh
  mkdir -p deploy/caddy/certs
  if command -v sudo >/dev/null 2>&1; then
    sudo -n chown -R "$(id -u)":"$(id -g)" deploy/caddy/certs 2>/dev/null || true
  fi
  DEPLOY_IP="${DEPLOY_IP:-184.73.154.194}"
  DOMAIN="$(grep -E '^DOMAIN=' .env.production 2>/dev/null | cut -d= -f2- | tr -d '\"' || echo btwobet.click)"
  ./deploy/caddy/generate-ip-cert.sh "$DEPLOY_IP" "$DOMAIN"
fi

echo ">> Recriando nginx/caddy (sem tocar DB/app)"
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --no-deps nginx caddy

echo ">> Verificando containers e endpoints locais"
docker compose -f docker-compose.prod.yml --env-file .env.production ps nginx caddy

for url in "http://127.0.0.1/" "http://127.0.0.1/api/health"; do
  ok=0
  for i in {1..12}; do
    if curl -fsSI "$url" >/dev/null; then
      ok=1
      break
    fi
    sleep 1
  done
  if [[ "$ok" != "1" ]]; then
    echo "ERRO: endpoint não respondeu OK: $url"
    docker compose -f docker-compose.prod.yml --env-file .env.production ps nginx caddy || true
    docker compose -f docker-compose.prod.yml --env-file .env.production logs --tail=200 nginx caddy || true
    exit 1
  fi
done

echo "OK. Valide: curl -sS \"${BASE}/main.dart.js\" | head -c 200"
echo "     No navegador: Ctrl+Shift+R (hard refresh)."
