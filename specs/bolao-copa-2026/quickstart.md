# Quickstart — Bolão Copa 2026

## Pré-requisitos

- Docker Desktop
- curl ou Postman/Insomnia

## Subir ambiente

```bash
cd /Users/mateuspureza/Documents/mateuspureza/btwobet
docker compose up -d --build
```

Aguarde ~30s e teste:

```bash
curl http://localhost:8080/api/health
```

## Banco de dados

- **Postgres** roda no Docker.
- **Porta local**: `5433` (para não conflitar com um Postgres já instalado na máquina).

## Seed (primeira vez / reset)

```bash
docker compose exec app php artisan migrate --force
docker compose exec app php artisan db:seed --force
```

## Importar a tabela “real” de jogos (slots) — Copa 2026

Como os confrontos (times) dependem do sorteio, o import usa um dataset público com **datas/horários/locais** e placeholders em fases finais.

```bash
docker compose exec app php artisan worldcup:import-openfootball
```

## Placares automáticos (ge.globo)

A cada 30 minutos o backend lê a página da Copa no GE e atualiza placares dos jogos que aparecem no widget (JSON embutido na página).

```bash
# Rodar manualmente
docker compose exec app php artisan worldcup:sync-scores
```

Em produção (`docker-compose.prod.yml`) o serviço `scheduler` executa `php artisan schedule:work` (o `entrypoint.sh` repassa o comando do container em vez de subir apenas o `serve` da API).

Variável opcional: `GE_COPA_URL` (padrão `https://ge.globo.com/futebol/copa-do-mundo/`).

## Foto de perfil

Upload via `POST /api/me/avatar` (multipart, campo `file`). Na tela **Conta**, use **Trocar foto** ou o ícone da câmera.

## Fluxo de teste manual

### 1. Cadastro

```bash
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Seu Nome","email":"seu@email.com","password":"sua-senha","password_confirmation":"sua-senha"}'
```

Guarde o `token` da resposta.

### 2. Listar jogos

```bash
curl http://localhost:8080/api/matches \
  -H "Authorization: Bearer SEU_TOKEN"
```

### 3. Registrar palpite

```bash
curl -X POST http://localhost:8080/api/predictions \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"match_id":1,"home_score":2,"away_score":1}'
```

### 4. Ranking

```bash
curl http://localhost:8080/api/ranking \
  -H "Authorization: Bearer SEU_TOKEN"
```

### 5. Meu histórico

```bash
curl http://localhost:8080/api/me/history \
  -H "Authorization: Bearer SEU_TOKEN"
```

## Preview UI (Stitch)

Abra no navegador os HTMLs exportados:

- `design/stitch/exports/boas-vindas-e-login/index.html`
- `design/stitch/exports/painel-de-palpites/index.html`

## Parar ambiente

```bash
docker compose down
```
