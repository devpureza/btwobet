#!/usr/bin/env bash
# Certificado autoassinado para IP (e domínio opcional) — use na EC2 antes do primeiro up.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
IP="${1:-184.73.154.194}"
DOMAIN="${2:-btwobet.click}"
mkdir -p "$DIR/certs"
openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
  -keyout "$DIR/certs/key.pem" \
  -out "$DIR/certs/cert.pem" \
  -subj "/CN=$IP" \
  -addext "subjectAltName=IP:$IP,DNS:$DOMAIN,DNS:www.$DOMAIN"
echo "OK: $DIR/certs/cert.pem (SAN: IP:$IP, DNS:$DOMAIN)"
