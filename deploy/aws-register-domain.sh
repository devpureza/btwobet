#!/usr/bin/env bash
# Registra domínio no Route 53 (requer conta AWS fora do Free Plan).
#   cp deploy/domain-contact.env.example deploy/domain-contact.env
#   # preencha endereço, telefone (+55.11...) e e-mail reais
#   ./deploy/aws-register-domain.sh btwobet.dev
set -euo pipefail

DOMAIN="${1:?ex: btwobet.dev}"
REGION="${AWS_REGION:-us-east-1}"
CONTACT_FILE="${CONTACT_FILE:-deploy/domain-contact.env}"

if [ ! -f "$CONTACT_FILE" ]; then
  echo "Crie $CONTACT_FILE a partir de deploy/domain-contact.env.example"
  exit 1
fi
# shellcheck disable=SC1090
source "$CONTACT_FILE"

required_vars=(CONTACT_FIRST_NAME CONTACT_LAST_NAME CONTACT_ADDRESS CONTACT_CITY \
  CONTACT_STATE CONTACT_COUNTRY CONTACT_ZIP CONTACT_PHONE CONTACT_EMAIL)
for v in "${required_vars[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "Variável $v não definida em $CONTACT_FILE"
    exit 1
  fi
done

echo "Verificando disponibilidade de $DOMAIN..."
AVAIL="$(aws route53domains check-domain-availability --domain-name "$DOMAIN" --region "$REGION" \
  --query 'Availability' --output text 2>&1)" || {
  echo "$AVAIL"
  echo ""
  echo "Sua conta retornou erro no Route 53 Domains (comum no AWS Free Plan)."
  echo "Upgrade: Console AWS → conta → Billing → mude para Paid plan."
  echo "Ou registre o domínio em outro registrador e rode só:"
  echo "  ./deploy/aws-setup-domain-https.sh $DOMAIN $CONTACT_EMAIL"
  exit 1
}

if [ "$AVAIL" != "AVAILABLE" ] && [ "$AVAIL" != "AVAILABLE_PREORDER" ]; then
  echo "Domínio não disponível: $AVAIL"
  exit 1
fi
echo "Disponível: $DOMAIN"

CONTACT_JSON="$(jq -n \
  --arg fn "$CONTACT_FIRST_NAME" --arg ln "$CONTACT_LAST_NAME" \
  --arg a1 "$CONTACT_ADDRESS" --arg city "$CONTACT_CITY" --arg st "$CONTACT_STATE" \
  --arg cc "$CONTACT_COUNTRY" --arg zip "$CONTACT_ZIP" --arg ph "$CONTACT_PHONE" --arg em "$CONTACT_EMAIL" \
  '{
    FirstName: $fn, LastName: $ln, ContactType: "PERSON",
    AddressLine1: $a1, City: $city, State: $st, CountryCode: $cc, ZipCode: $zip,
    PhoneNumber: $ph, Email: $em
  }')"

REGISTER_JSON="$(jq -n \
  --arg domain "$DOMAIN" \
  --argjson contact "$CONTACT_JSON" \
  '{
    DomainName: $domain,
    DurationInYears: 1,
    AutoRenew: true,
    AdminContact: $contact,
    RegistrantContact: $contact,
    TechContact: $contact,
    PrivacyProtectAdminContact: true,
    PrivacyProtectRegistrantContact: true,
    PrivacyProtectTechContact: true
  }')"

echo "Registrando (cobrança no cartão da conta AWS)..."
OP_ID="$(aws route53domains register-domain --region "$REGION" --cli-input-json "$REGISTER_JSON" \
  --query 'OperationId' --output text)"
echo "OperationId: $OP_ID (pode levar alguns minutos)"

echo "Quando concluir, rode:"
echo "  ./deploy/aws-setup-domain-https.sh $DOMAIN $CONTACT_EMAIL"
