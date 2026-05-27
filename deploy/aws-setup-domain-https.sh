#!/usr/bin/env bash
# Configura Elastic IP, DNS (Route 53) e prepara HTTPS na EC2.
# Uso local (Mac com aws configure):
#   ./deploy/aws-setup-domain-https.sh btwobet.dev admin@email.com
#
# Registro do domínio na AWS (conta precisa sair do AWS Free Plan):
#   cp deploy/domain-contact.env.example deploy/domain-contact.env
#   # edite com seus dados reais
#   ./deploy/aws-register-domain.sh btwobet.dev
set -euo pipefail

DOMAIN="${1:?Domínio, ex: btwobet.dev}"
ACME_EMAIL="${2:?E-mail ACME/Let's Encrypt}"
REGION="${AWS_REGION:-us-east-1}"
INSTANCE_NAME="${INSTANCE_NAME:-btwobet}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Conta AWS =="
aws sts get-caller-identity --output table

echo "== EC2 ($INSTANCE_NAME) =="
INSTANCE_ID="$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)"
if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
  echo "Instância '$INSTANCE_NAME' não encontrada."
  exit 1
fi

echo "Instance: $INSTANCE_ID"

# Elastic IP estável
ALLOCATION_ID="$(aws ec2 describe-addresses --region "$REGION" \
  --filters "Name=instance-id,Values=$INSTANCE_ID" \
  --query 'Addresses[0].AllocationId' --output text 2>/dev/null || true)"
if [ -z "$ALLOCATION_ID" ] || [ "$ALLOCATION_ID" = "None" ]; then
  echo "Alocando Elastic IP..."
  read -r ALLOCATION_ID PUBLIC_IP <<< "$(aws ec2 allocate-address --domain vpc --region "$REGION" \
    --query '[AllocationId,PublicIp]' --output text)"
  aws ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOCATION_ID" --region "$REGION" >/dev/null
else
  PUBLIC_IP="$(aws ec2 describe-addresses --allocation-ids "$ALLOCATION_ID" --region "$REGION" \
    --query 'Addresses[0].PublicIp' --output text)"
fi
echo "IP público (use no DNS): $PUBLIC_IP"

SG_ID="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)"
for PORT in 80 443; do
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port "$PORT" \
    --cidr 0.0.0.0/0 --region "$REGION" 2>/dev/null || true
done
echo "Security group $SG_ID: portas 80 e 443 abertas."

# Hosted zone + registro A
ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN." \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id" --output text | head -1 | sed 's|/hostedzone/||')"
if [ -z "$ZONE_ID" ]; then
  echo "Criando hosted zone Route 53 para $DOMAIN..."
  ZONE_ID="$(aws route53 create-hosted-zone --name "$DOMAIN" --caller-reference "btwobet-$(date +%s)" \
    --query 'HostedZone.Id' --output text | sed 's|/hostedzone/||')"
fi

aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${DOMAIN}.",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${PUBLIC_IP}"}]
    }
  }, {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "www.${DOMAIN}.",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${PUBLIC_IP}"}]
    }
  }]
}
EOF
)" >/dev/null

echo "DNS A e www → $PUBLIC_IP (zone $ZONE_ID)"

NS="$(aws route53 get-hosted-zone --id "$ZONE_ID" --query 'DelegationSet.NameServers' --output text)"
echo ""
echo "Se o domínio foi registrado FORA da AWS, configure estes name servers no registrador:"
echo "$NS" | tr '\t' '\n' | sed 's/^/  /'

echo ""
echo "== Deploy HTTPS na EC2 =="
EC2_HOST="${EC2_HOST:-$PUBLIC_IP}"
if [ -f deploy/domain-contact.env ]; then
  # shellcheck disable=SC1091
  source deploy/domain-contact.env
fi

if command -v ssh >/dev/null && [ -n "${EC2_SSH_KEY_PATH:-}" ] && [ -f "${EC2_SSH_KEY_PATH}" ]; then
  RSYNC_SSH="ssh -i $EC2_SSH_KEY_PATH -o StrictHostKeyChecking=accept-new"
  rsync -az docker-compose.prod.yml -e "$RSYNC_SSH" "ubuntu@${EC2_HOST}:/opt/btwobet/"
  rsync -az deploy/caddy deploy/setup-https-domain.sh -e "$RSYNC_SSH" "ubuntu@${EC2_HOST}:/opt/btwobet/deploy/"
  $RSYNC_SSH "ubuntu@${EC2_HOST}" "chmod +x /opt/btwobet/deploy/setup-https-domain.sh && cd /opt/btwobet && docker compose -f docker-compose.prod.yml --env-file .env.production up -d caddy && ./deploy/setup-https-domain.sh $DOMAIN $ACME_EMAIL"
else
  echo "Defina EC2_SSH_KEY_PATH=/caminho/key.pem para aplicar HTTPS via SSH."
  echo "Ou na EC2: ./deploy/setup-https-domain.sh $DOMAIN $ACME_EMAIL"
fi

echo ""
echo "Próximo: aguarde DNS propagar (5–30 min) e teste:"
echo "  curl -sI https://${DOMAIN}/api/health"
echo "Atualize GitHub secret EC2_HOST para ${PUBLIC_IP} ou ${DOMAIN}"
