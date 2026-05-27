#!/usr/bin/env bash
# ÚNICA etapa manual: autorizar no navegador quando abrir (~10s).
# Depois disso: ./deploy/setup-aws-local.sh e o agente pode criar EC2 via CLI/MCP.
set -euo pipefail

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Região: $AWS_DEFAULT_REGION"
echo "Abrindo login AWS no navegador — clique em Permitir/Authorize."
echo ""

printf '%s\n' "$AWS_DEFAULT_REGION" | aws login --no-cli-pager

echo ""
aws sts get-caller-identity
echo ""
echo "Pronto. Reinicie o Cursor (Cmd+Q) para o MCP aws."
