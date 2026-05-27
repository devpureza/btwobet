---
description: "Tasks for Bolão Copa do Mundo 2026"
---

# Tasks: Bolão Copa do Mundo 2026

**Input**: Design documents from `/specs/bolao-copa-2026/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Estruturar monorepo conforme `specs/bolao-copa-2026/plan.md` (dirs `backend/`, `mobile/`, `design/`, `docker/`)
- [ ] T002 Garantir Docker Compose do backend (`docker-compose.yml`, `docker/Dockerfile`, `docker/entrypoint.sh`)
- [ ] T003 Fixar contexto do Spec Kit em `.cursor/rules/specify-rules.mdc` apontando para `plan.md` e `quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T010 Implementar autenticação via Sanctum no backend (tokens Bearer) e rotas protegidas
- [ ] T011 Criar migrations e models (`Team`, `Match`, `Prediction`) com constraints e casts
- [ ] T012 Implementar serviços de domínio (ScoreCalculator, RankingService) e testes unitários
- [ ] T013 Criar seed de dados (times, jogos e alguns resultados) para ambiente testável
- [ ] T014 Definir e documentar contrato mínimo da API (ref. `contracts/openapi.yaml`)

**Checkpoint**: Backend sobe e endpoints principais respondem com seed.

---

## Phase 3: User Story 1 — Login e sessão (Priority: P1) 🎯 MVP

**Goal**: Usuário cria conta/entra e obtém token para consumir a API.

**Independent Test**: `POST /register` e `POST /login` retornam token e `GET /me` funciona.

- [ ] T020 [P] Backend: endpoints `POST /register`, `POST /login`, `GET /me` (`backend/routes/api.php`, controllers)
- [ ] T021 [P] Flutter: criar projeto `mobile/` e configurar builds (Android/iOS) + flavors (opcional)
- [ ] T022 Flutter: implementar tela **Boas-vindas e Login** (UI baseada em `design/stitch/exports/boas-vindas-e-login/`)
- [ ] T023 Flutter: implementar armazenamento do token (secure storage) e interceptors HTTP

---

## Phase 4: User Story 2 — Ver jogos e registrar palpites (Priority: P1)

**Goal**: Usuário autenticado lista jogos e salva palpite antes do kickoff.

**Independent Test**: `GET /matches` lista jogos; `POST /predictions` cria/atualiza palpite e reflete em `/matches`.

- [ ] T030 Backend: endpoint `GET /matches` com times + flags + `my_prediction`
- [ ] T031 Backend: endpoint `POST /predictions` com regra de deadline
- [ ] T032 Flutter: tela **Painel de Palpites** (listagem + inputs de placar + salvar)
- [ ] T033 Flutter: cliente API (login, matches, predictions) com tratamento de erros

---

## Phase 5: User Story 3 — Histórico e ranking (Priority: P1)

**Goal**: Usuário vê histórico de palpites/pontos e ranking geral.

**Independent Test**: `GET /me/history` e `GET /ranking` retornam dados coerentes e ordenados.

- [ ] T040 Backend: endpoint `GET /me/history` com total e itens
- [ ] T041 Backend: endpoint `GET /ranking` com desempate (pontos, exatos, resultado, created_at)
- [ ] T042 Flutter: tela **Meu Histórico**
- [ ] T043 Flutter: tela **Ranking Geral**

---

## Phase 6: Polish & Cross-Cutting

- [ ] T050 Ajustar tema Flutter com tokens do `design/stitch/DESIGN.md`
- [ ] T051 Garantir navegação (tabs/bottom nav) entre Palpites / Ranking / Histórico
- [ ] T052 Documentar como rodar e testar (`specs/bolao-copa-2026/quickstart.md`)
- [ ] T053 Hardening: validações, estados vazios, loading, offline básico (opcional)

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 bloqueia o resto.
- US1 pode começar assim que Phase 2 estiver OK (token).
- US2 depende de US1 (token) e endpoint `/matches`.
- US3 depende de US1 e de pontuação calculada no seed.

