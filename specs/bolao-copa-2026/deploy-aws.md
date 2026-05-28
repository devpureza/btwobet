# Deploy na AWS (EC2)

Guia para subir o Bolão Copa 2026 em uma máquina Amazon EC2 com Docker Compose + GitHub Actions.

## Arquitetura

```text
Internet :80
    └── nginx (Flutter Web + proxy /api)
            └── app (Laravel)
            └── db (PostgreSQL)
```

## 1. Criar a EC2

1. **AMI**: Ubuntu 22.04 ou 24.04 LTS  
2. **Tipo**: `t3.small` (MVP) ou `t3.micro` (teste)  
3. **Security Group** (inbound):
   - SSH `22` — só seu IP
   - HTTP `80` — `0.0.0.0/0` (ou restrinja)
   - HTTPS `443` — se for usar TLS depois
4. **Par de chaves**: baixe o `.pem` (vai virar `EC2_SSH_KEY` no GitHub)

Elastic IP (opcional, recomendado): associe um IP fixo à instância.

## 2. Preparar a máquina (uma vez)

```bash
ssh -i sua-chave.pem ubuntu@SEU_IP_EC2

git clone https://github.com/SEU_USUARIO/btwobet.git /opt/btwobet
cd /opt/btwobet
chmod +x deploy/setup-ec2.sh deploy/remote-deploy.sh
./deploy/setup-ec2.sh

# sair e entrar de novo se o script adicionou você ao grupo docker
exit
ssh -i sua-chave.pem ubuntu@SEU_IP_EC2

cp .env.production.example .env.production
nano .env.production   # APP_URL, DB_PASSWORD, RUN_SEED=true no 1º deploy
```

Primeiro deploy manual:

```bash
cd /opt/btwobet
# Instale Flutter na EC2 OU faça build local e rsync mobile/build/web antes
./deploy/remote-deploy.sh
curl http://127.0.0.1/api/health
```

## 3. GitHub Actions (deploy automático)

Workflow: `.github/workflows/deploy-ec2.yml`

### Secrets (Settings → Secrets and variables → Actions)

| Secret | Exemplo |
|--------|---------|
| `EC2_HOST` | `3.15.xxx.xxx` ou Elastic IP |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | conteúdo completo do `.pem` |

### Variables (opcional)

| Variable | Uso |
|----------|-----|
| `APP_URL` | `https://bolao.seudominio.com` — passa para build Flutter |

Dispare: push em `main` ou **Actions → Deploy EC2 → Run workflow**.

## 4. MCP no Cursor

Hoje o projeto só tem MCP **Stitch** em `.cursor/mcp.json`. **Não há MCP AWS** configurado.

Para gerenciar EC2/S3/Route53 pelo chat, adicione um servidor MCP AWS (ex.: pacotes da comunidade ou AWS API MCP) em:

- `.cursor/mcp.json` (time) ou  
- Cursor Settings → MCP

Exemplo genérico (ajuste conforme o pacote que escolher):

```json
{
  "mcpServers": {
    "stitch": { "...": "..." },
    "aws": {
      "command": "npx",
      "args": ["-y", "@aws/mcp-server-aws-api"],
      "env": {
        "AWS_REGION": "us-east-1",
        "AWS_PROFILE": "default"
      }
    }
  }
}
```

Credenciais: `aws configure` na máquina ou variáveis `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` com IAM mínimo (EC2, opcional Route53/ACM).

**Importante**: não commite chaves em `mcp.local.json`. Use `${VAR}` no `mcp.json` e valores locais no `.gitignore`.

## 5. Domínio + HTTPS

**IP fixo da EC2:** use o Elastic IP (ex.: `184.73.154.194`). Atualize o secret `EC2_HOST` no GitHub.

### Conta AWS Free Plan

Registro de domínio no Route 53 **não funciona** no Free Plan. Rode `./deploy/aws-upgrade-paid.sh` ou no console: Billing → Upgrade account.

Domínio mais barato na AWS: **`btwobet.click`** (~**US$ 3/ano**). Segunda opção: **`btwobet.link`** (~US$ 5/ano). Evite `.xyz` (~US$ 18) salvo preferência explícita.

E-mail de contato do domínio: **devpureza@gmail.com** (mesmo da conta AWS).

### Fluxo recomendado (Caddy + Let's Encrypt)

```bash
# 1) Contato para registro (não commitar)
cp deploy/domain-contact.env.example deploy/domain-contact.env
# edite com dados reais

# 2) Registrar domínio na AWS (após Paid plan)
./deploy/aws-upgrade-paid.sh
./deploy/aws-register-domain.sh btwobet.click

# 3) DNS + HTTPS na EC2
export EC2_SSH_KEY_PATH=~/Downloads/sua-chave.pem
./deploy/aws-setup-domain-https.sh btwobet.click devpureza@gmail.com
```

Na EC2, após DNS propagar:

```bash
./deploy/setup-https-domain.sh btwobet.dev seu@email.com
```

Caddy termina HTTPS na frente do nginx (portas 80/443 no `docker-compose.prod.yml`).

## 6. Checklist pós-deploy

- [ ] `curl http://SEU_IP/api/health` → `200`  
- [ ] App web abre em `http://SEU_IP`  
- [ ] Login com usuário do seed (se `RUN_SEED=true` no primeiro deploy)  
- [ ] `RUN_SEED=false` nos deploys seguintes  
- [ ] Backup do volume Docker `postgres_data`

## Comandos úteis na EC2

```bash
cd /opt/btwobet
docker compose -f docker-compose.prod.yml --env-file .env.production logs -f app
docker compose -f docker-compose.prod.yml --env-file .env.production exec app php artisan migrate --force
docker compose -f docker-compose.prod.yml --env-file .env.production down
```
