#!/usr/bin/env bash
# Sobe conta AWS de FREE para PAID (necessário para registrar domínio no Route 53).
set -euo pipefail

STATE="$(aws freetier get-account-plan-state --region us-east-1 --query accountPlanType --output text)"
echo "Plano atual: $STATE"

if [ "$STATE" = "PAID" ]; then
  echo "Conta já está no plano PAID."
  exit 0
fi

aws freetier upgrade-account-plan --account-plan-type PAID --region us-east-1
echo "Upgrade solicitado. Aguarde alguns minutos antes de registrar domínio."
