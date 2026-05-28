#!/bin/sh
set -e

if [ ! -f .env ]; then
  cp .env.example .env
fi

set_env () {
  key="$1"
  value="$2"
  if [ -z "$key" ]; then
    return 0
  fi
  if grep -q "^${key}=" .env 2>/dev/null; then
    # shellcheck disable=SC2001
    sed -i.bak "s|^${key}=.*|${key}=${value}|" .env
  else
    echo "${key}=${value}" >> .env
  fi
}

# Garantir que o .env reflita as variáveis do compose
if [ -n "${APP_URL}" ]; then
  set_env "APP_URL" "${APP_URL}"
fi
if [ -n "${DB_CONNECTION}" ]; then
  set_env "DB_CONNECTION" "${DB_CONNECTION}"
fi
if [ -n "${DB_HOST}" ]; then
  set_env "DB_HOST" "${DB_HOST}"
fi
if [ -n "${DB_PORT}" ]; then
  set_env "DB_PORT" "${DB_PORT}"
fi
if [ -n "${DB_DATABASE}" ]; then
  set_env "DB_DATABASE" "${DB_DATABASE}"
fi
if [ -n "${DB_USERNAME}" ]; then
  set_env "DB_USERNAME" "${DB_USERNAME}"
fi
if [ -n "${DB_PASSWORD}" ]; then
  set_env "DB_PASSWORD" "${DB_PASSWORD}"
fi

if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
  php artisan key:generate --force
fi

if [ "${DB_CONNECTION}" = "pgsql" ]; then
  echo "Waiting for Postgres..."
  php -r '
  $host=getenv("DB_HOST") ?: "db";
  $port=getenv("DB_PORT") ?: "5432";
  $db=getenv("DB_DATABASE") ?: "btwobet";
  $user=getenv("DB_USERNAME") ?: "btwobet";
  $pass=getenv("DB_PASSWORD") ?: "btwobet";
  $dsn="pgsql:host=$host;port=$port;dbname=$db";
  $start=time();
  while (true) {
    try { new PDO($dsn, $user, $pass, [PDO::ATTR_TIMEOUT => 1]); break; }
    catch (Throwable $e) {
      if (time() - $start > 60) { fwrite(STDERR, "Postgres not ready after 60s\n"); exit(1); }
      usleep(500000);
    }
  }'
fi

php artisan migrate --force
php artisan storage:link || true

if [ "${RUN_SEED:-true}" = "true" ]; then
  php artisan db:seed --force
fi

if [ "${APP_ENV}" = "production" ]; then
  php artisan config:cache
  php artisan route:cache
fi

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec php artisan serve --host=0.0.0.0 --port=8000
