#!/usr/bin/env bash
# Sobe o ambiente local de forma segura (preserva o volume Postgres).
# - Nunca usa `docker compose down -v`
# - Roda migrate; seed só se não existir nenhum usuário (count = 0)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

API_URL="${API_URL:-http://localhost:8080}"
SPA_PORT="${SPA_PORT:-4173}"
SPA_PID_FILE="${ROOT}/.local-spa-server.pid"
SPA_LOG="${ROOT}/.local-spa-server.log"

echo ">> Docker Compose (sem apagar volumes)"
docker compose up -d

echo ">> Aguardando Postgres + API..."
for i in $(seq 1 60); do
  if curl -fsS "${API_URL}/api/health" >/dev/null 2>&1; then
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "ERRO: API não respondeu em ${API_URL}/api/health"
    docker compose ps
    docker compose logs --tail=40 app db
    exit 1
  fi
  sleep 1
done

echo ">> Migrations"
docker compose exec -T app php artisan migrate --force

echo ">> Seed condicional (apenas se users = 0)"
USER_COUNT="$(docker compose exec -T app php artisan tinker --execute='echo App\Models\User::count();' 2>/dev/null | tr -d '\r' | tail -1)"
if [[ "${USER_COUNT:-}" =~ ^[0-9]+$ ]] && [[ "$USER_COUNT" -eq 0 ]]; then
  docker compose exec -T app php artisan db:seed --force
  echo "   Seed executado (banco vazio)."
else
  echo "   Pulando seed (${USER_COUNT:-?} usuário(s) no banco)."
fi

start_spa() {
  if [[ ! -d mobile/build/web ]] || [[ ! -f mobile/build/web/index.html ]]; then
    echo ">> SPA: mobile/build/web ausente — rode: cd mobile && flutter build web --dart-define=API_BASE_URL=${API_URL}/api"
    return 0
  fi
  if [[ -f "$SPA_PID_FILE" ]]; then
    old_pid="$(cat "$SPA_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo ">> SPA já em execução (PID $old_pid) — http://127.0.0.1:${SPA_PORT}"
      return 0
    fi
  fi
  if lsof -i ":${SPA_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo ">> Porta ${SPA_PORT} em uso — assumindo SPA já rodando"
    return 0
  fi
  echo ">> Iniciando spa_server na porta ${SPA_PORT}"
  nohup python3 mobile/tools/spa_server.py --directory mobile/build/web --port "${SPA_PORT}" \
    >"$SPA_LOG" 2>&1 &
  echo $! >"$SPA_PID_FILE"
  sleep 0.5
}

start_spa

echo ""
echo "=== Ambiente local ==="
echo "API:     ${API_URL}/api/health"
echo "Flutter: http://127.0.0.1:${SPA_PORT} (proxy /api → ${API_URL})"
echo ""
echo "Dev admin (seed): devpureza@gmail.com / 12345678"
echo "Volume DB: btwobet_postgres_data (persiste entre restarts; NÃO use down -v)"
