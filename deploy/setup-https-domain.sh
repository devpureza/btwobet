#!/usr/bin/env bash
# Ativa HTTPS (Let's Encrypt via Caddy) após o domínio apontar para esta EC2.
# Uso na EC2: ./deploy/setup-https-domain.sh btwobet.dev admin@example.com
set -euo pipefail

DOMAIN="${1:?Informe o domínio, ex: btwobet.dev}"
ACME_EMAIL="${2:?Informe e-mail ACME (Lets Encrypt), ex: admin@example.com}"

DEPLOY_DIR="${DEPLOY_DIR:-/opt/btwobet}"
cd "$DEPLOY_DIR"

CADDYFILE="deploy/caddy/Caddyfile"
sed -e "s|__DOMAIN__|${DOMAIN}|g" -e "s|__ACME_EMAIL__|${ACME_EMAIL}|g" \
  deploy/caddy/Caddyfile.https.tpl > "$CADDYFILE"
# Mantém HTTP no IP até o certificado do domínio estar ativo
if ! grep -q 'http://:80' "$CADDYFILE" 2>/dev/null; then
  cat >> "$CADDYFILE" <<'EOF'

http://:80 {
	reverse_proxy nginx:80
}

:443 {
	tls internal
	reverse_proxy nginx:80
}
EOF
fi

if [ -f .env.production ]; then
  if grep -q '^APP_URL=' .env.production; then
    sed -i "s|^APP_URL=.*|APP_URL=https://${DOMAIN}|" .env.production
  else
    echo "APP_URL=https://${DOMAIN}" >> .env.production
  fi
  if grep -q '^DOMAIN=' .env.production; then
    sed -i "s|^DOMAIN=.*|DOMAIN=${DOMAIN}|" .env.production
  else
    echo "DOMAIN=${DOMAIN}" >> .env.production
  fi
fi

docker compose -f docker-compose.prod.yml --env-file .env.production up -d caddy
docker compose -f docker-compose.prod.yml --env-file .env.production exec -T caddy caddy reload --config /etc/caddy/Caddyfile

echo "HTTPS configurado para https://${DOMAIN}"
echo "Teste: curl -sI https://${DOMAIN}/api/health"
