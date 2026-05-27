# AWS — conectar do zero (iniciante)

Git já funciona; AWS é **outro login** (não usa GitHub).

## Passo 1 — Conta AWS

Se ainda não tiver: https://aws.amazon.com → **Criar conta AWS**.

## Passo 2 — Usuário IAM (não use a conta root no dia a dia)

1. Entre no [Console AWS](https://console.aws.amazon.com)
2. Busque **IAM** → **Users** → **Create user**
3. Nome: `btwobet-deploy`
4. Marque **Provide user access to the AWS Management Console** (opcional) **ou** só programmatic
5. **Attach policies directly** (MVP, simples):
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
6. Crie e abra o usuário → aba **Security credentials** → **Create access key** → **CLI**
7. Copie **Access key ID** e **Secret access key** (só aparece uma vez)

## Passo 3 — Configurar no Mac

No Terminal:

```bash
aws configure
```

| Pergunta | Resposta sugerida |
|----------|-------------------|
| Access Key ID | cole da IAM |
| Secret Access Key | cole da IAM |
| Default region | `us-east-1` |
| Default output format | `json` |

Teste:

```bash
cd /Users/mateuspureza/Documents/mateuspureza/btwobet
./deploy/setup-aws-local.sh
```

Deve mostrar JSON com `Account` e `Arn`.

## Passo 4 — MCP no Cursor

O projeto já tem servidor **aws** em `.cursor/mcp.json` (região `us-east-1`).

1. **Cmd+Q** no Cursor e abra de novo
2. **Settings → MCP** → bolinha verde em **aws**

## Passo 5 — Criar a máquina (EC2)

No chat (com MCP aws verde), peça:

> Crie uma EC2 Ubuntu 24.04 t3.small em us-east-1, security group com portas 22 e 80, e me dê o IP público.

Ou manualmente no console: **EC2 → Launch instance** (ver [deploy-aws.md](./deploy-aws.md)).

## Passo 6 — Deploy do btwobet na EC2

1. Baixe o arquivo `.pem` da chave SSH ao criar a EC2
2. Na EC2 (SSH):

```bash
git clone https://github.com/devpureza/btwobet.git /opt/btwobet
cd /opt/btwobet
./deploy/setup-ec2.sh
cp .env.production.example .env.production
# edite senha do banco e APP_URL
./deploy/remote-deploy.sh
```

3. No GitHub → repo **devpureza/btwobet** → Settings → Secrets → Actions:
   - `EC2_HOST`, `EC2_USER` (`ubuntu`), `EC2_SSH_KEY` (conteúdo do `.pem`)

Depois cada push em `main` roda o workflow **Deploy EC2**.

## Passo 7 — Domínio e HTTPS

1. **Elastic IP** já deve estar associado à EC2 (IP fixo para DNS).
2. Conta no **Paid plan** (Free Plan não registra domínio no Route 53).
3. `cp deploy/domain-contact.env.example deploy/domain-contact.env` e preencha.
4. `./deploy/aws-register-domain.sh btwobet.dev`
5. `./deploy/aws-setup-domain-https.sh btwobet.dev seu@email.com`
6. No GitHub Secrets: `EC2_HOST` = IP elástico ou domínio; variável `APP_URL` = `https://btwobet.dev` no workflow.

Detalhes: [deploy-aws.md](./deploy-aws.md) seção 5.
