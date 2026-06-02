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

echo ">> Reiniciando apenas nginx (DB e app intactos)"
docker compose -f docker-compose.prod.yml --env-file .env.production restart nginx

echo "OK. Valide: curl -sS \"${BASE}/main.dart.js\" | head -c 200"
echo "     No navegador: Ctrl+Shift+R (hard refresh)."
