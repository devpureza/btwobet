# Configurar GitHub + AWS (passo a passo para iniciantes)

Este guia é para quem **não conhece AWS**. Depois de seguir estes passos, um agente no Cursor (com MCP) pode ajudar a criar EC2, secrets e deploy.

## O que o agente NÃO consegue fazer sozinho

- Entrar na sua conta AWS ou GitHub no navegador
- Adivinhar se você está logado como `devpureza@gmail.com`
- Criar chaves de acesso sem você copiar/colar uma vez

## O que já verificamos nesta máquina

| Item | Status |
|------|--------|
| Git configurado | email `mateus.pureza@eplugin.app.br` (não `devpureza@gmail.com`) |
| Repositório GitHub remoto | ainda **não** configurado |
| `gh` (GitHub CLI) | instalar com Homebrew (ver abaixo) |
| `aws` (AWS CLI) | instalar com Homebrew (ver abaixo) |
| MCP no projeto | só **Stitch** — falta **AWS** e **GitHub** |

---

## Parte A — GitHub (~15 min)

### 1. Instalar GitHub CLI

```bash
brew install gh
```

### 2. Login (escolha a conta certa)

```bash
gh auth login
```

- GitHub.com → HTTPS → **Login with browser**
- Confira no navegador se a conta é **devpureza@gmail.com** (ou a que quiser usar)
- Volte ao terminal até aparecer “Logged in”

Confirme:

```bash
gh auth status
```

### 3. Criar repositório e enviar o código

Na pasta do monorepo (pai de `btwobet/`):

```bash
cd /Users/mateuspureza/Documents/mateuspureza
git init
git add btwobet
git commit -m "feat: bolão copa 2026 — API Laravel + app Flutter"
gh repo create btwobet --private --source=. --remote=origin --push
```

(Ajuste o nome `btwobet` se quiser outro.)

### 4. Token para MCP GitHub (opcional mas útil)

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained  
2. Repositório `btwobet`, permissões: Contents, Actions, Secrets (read/write)  
3. Copie o token e no Mac:

```bash
echo 'export GITHUB_TOKEN="ghp_..."' >> ~/.zshrc
source ~/.zshrc
```

Reinicie o Cursor (Cmd+Q e abra de novo).

---

## Parte B — AWS (~20 min)

### 1. Criar conta AWS (se ainda não tiver)

1. Acesse https://aws.amazon.com e crie conta com o email que preferir  
2. Ative MFA no root (recomendado)

### 2. Usuário IAM para o deploy (não use root no dia a dia)

Console AWS → **IAM** → Users → Create user:

- Nome: `btwobet-deploy`
- Acesso programático: **Access key**
- Permissões (MVP): anexe `AmazonEC2FullAccess` + `AmazonVPCFullAccess`  
  (depois podemos reduzir para política mínima)

Guarde:

- Access Key ID  
- Secret Access Key (só aparece uma vez)

### 3. Instalar e configurar AWS CLI

```bash
brew install awscli
aws configure
```

Informe Access Key, Secret, região `us-east-1`, formato `json`.

Teste:

```bash
aws sts get-caller-identity
```

Deve retornar JSON com `Account` e `Arn`.

---

## Parte C — MCP no Cursor

O arquivo `.cursor/mcp.json` do projeto já inclui entradas para **aws** e **github** (além do Stitch).

1. Configure `GITHUB_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (ou `aws configure`)  
2. **Cmd+Q** no Cursor e abra de novo  
3. Settings → **MCP** → dots verdes em `aws` e `github`

Depois disso, peça no chat:

> “Crie uma EC2 Ubuntu t3.small em us-east-1, security group com 22/80, e me dê o IP para deploy do btwobet.”

---

## Parte D — Secrets do GitHub Actions

No repositório: **Settings → Secrets and variables → Actions**

| Secret | Valor |
|--------|--------|
| `EC2_HOST` | IP público da EC2 |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | conteúdo do arquivo `.pem` da chave SSH da EC2 |

Variable:

| Name | Valor |
|------|--------|
| `APP_URL` | `http://SEU_IP` ou `https://seu-dominio.com` |

Workflow: `.github/workflows/deploy-ec2.yml` (já no projeto).

---

## Ordem recomendada

1. `gh auth login` + criar repo  
2. `aws configure` + MCP aws verde no Cursor  
3. Pedir ao agente: criar EC2 + security group  
4. SSH na EC2 → `setup-ec2.sh` → `.env.production`  
5. Secrets no GitHub → rodar workflow **Deploy EC2**

Guia de deploy na máquina: [deploy-aws.md](./deploy-aws.md)
