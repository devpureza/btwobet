#!/usr/bin/env bash
# Verifica AWS CLI + credenciais no Mac (rode depois de `aws configure`).
set -euo pipefail

echo "== AWS CLI =="
if ! command -v aws >/dev/null 2>&1; then
  echo "Instale: brew install awscli"
  exit 1
fi
aws --version

echo ""
echo "== Credenciais =="
if aws sts get-caller-identity; then
  echo ""
  echo "OK — AWS conectada. Reinicie o Cursor para o MCP 'aws' funcionar."
else
  echo ""
  echo "Sem credenciais. Siga:"
  echo "  1. Console AWS → IAM → Users → Create user (btwobet-deploy)"
  echo "  2. Access key (programmatic)"
  echo "  3. Permissões: AmazonEC2FullAccess + AmazonVPCFullAccess (MVP)"
  echo "  4. No terminal: aws configure"
  echo "     Região sugerida: us-east-1"
  exit 1
fi
