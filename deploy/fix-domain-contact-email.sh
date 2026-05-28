#!/usr/bin/env bash
# Atualiza e-mail de contato do domínio no Route 53 (após registro concluído).
# Uso: ./deploy/fix-domain-contact-email.sh btwobet.xyz devpureza@gmail.com
set -euo pipefail

DOMAIN="${1:?ex: btwobet.xyz}"
NEW_EMAIL="${2:?ex: devpureza@gmail.com}"
REGION="${AWS_REGION:-us-east-1}"

DETAIL="$(aws route53domains get-domain-detail --domain-name "$DOMAIN" --region "$REGION")"

patch() {
  echo "$DETAIL" | jq --arg em "$NEW_EMAIL" ".$1 | .Email = \$em"
}

OP_ID="$(aws route53domains update-domain-contact \
  --domain-name "$DOMAIN" \
  --region "$REGION" \
  --admin-contact "$(patch AdminContact)" \
  --registrant-contact "$(patch RegistrantContact)" \
  --tech-contact "$(patch TechContact)" \
  --query OperationId --output text)"

echo "Atualização enviada (OperationId: $OP_ID). Confirme no e-mail $NEW_EMAIL se a AWS pedir."
