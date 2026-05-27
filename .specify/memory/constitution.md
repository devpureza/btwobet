# Constituição do Projeto — Bolão Copa do Mundo 2026

Este projeto será um bolão da Copa do Mundo 2026 com **backend em Laravel** e **app em Flutter** (mobile-first e responsivo).

## Core Principles

### I. Produto primeiro (MVP fatiado)
Entregaremos em fatias independentes e demonstráveis. Cada fatia deve ser utilizável sozinha (ex.: cadastro/login + listar jogos + palpite).

### II. Fonte de verdade do domínio no backend
Regras de pontuação, fechamento de palpites, ranking e validações vivem no backend (Laravel). O app apenas consome e apresenta.

### III. Segurança por padrão
Autenticação, autorização e validação de entrada são obrigatórias. Nunca versionar segredos (API keys, tokens, `.env`).

### IV. Testes no que importa (domínio)
Cobrir principalmente: cálculo de pontuação, ranking, permissões (quem pode ver/alterar o quê) e regras de deadline de palpites.

### V. Simplicidade e evolução
Evitar over-engineering. Começar com o essencial e evoluir o modelo conforme surgirem necessidades reais (YAGNI).

## Restrições e decisões

- **Stack**:
  - Backend: Laravel (API)
  - App: Flutter
- **Autenticação**: login obrigatório para palpites e ranking (sessão/token a definir no plano).
- **Pontuação**:
  - Acertou placar exato: 2 pontos
  - Acertou apenas vencedor/empate (resultado): 1 ponto
  - Errou: 0
- **Base de jogos**: terá todos os jogos da Copa 2026 com datas/horários e bandeiras. (Fonte de dados e formato de import serão definidos no plano.)

## Workflow e qualidade

- Seguir Spec Kit: `spec -> plan -> tasks -> implement`.
- Qualquer mudança de regra de domínio precisa atualizar spec e testes.

## Governance

- Esta constituição prevalece sobre preferências locais.
- Mudanças relevantes devem ser registradas aqui com nova versão.

**Version**: 0.1.0 | **Ratified**: 2026-05-27 | **Last Amended**: 2026-05-27
