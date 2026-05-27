# Implementation Plan: Bolão Copa do Mundo 2026

**Branch**: `000-bolao-copa-2026` | **Date**: 2026-05-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/bolao-copa-2026/spec.md`

## Summary

Bolão da Copa 2026 com backend Laravel (API REST) e app Flutter. Participantes autenticados registram palpites de placar; pontuação 2/1/0; ranking e histórico. Design UI referenciado do Stitch (`design/stitch/`).

## Technical Context

**Language/Version**: PHP 8.3+ (Laravel 13), Dart 3+ (Flutter — fase 2)

**Primary Dependencies**: Laravel 13, Sanctum, Flutter (fase 2)

**Storage**: SQLite (dev local), PostgreSQL (Docker Compose)

**Testing**: PHPUnit (ScoreCalculator, PredictionPolicy, Ranking)

**Target Platform**: API Linux/Docker; app iOS/Android/Web (Flutter)

**Project Type**: Mobile + API

**Performance Goals**: <200ms p95 para listagens em dev; suportar centenas de usuários no MVP

**Constraints**: Regras de domínio no backend; deadline até kickoff; sem secrets no git

**Scale/Scope**: ~104 jogos Copa; dezenas-centenas de participantes no MVP

## Constitution Check

| Princípio | Status |
|-----------|--------|
| MVP fatiado | ✅ Fase 1 = API testável; Fase 2 = Flutter |
| Domínio no backend | ✅ ScoreCalculator, ranking, validações no Laravel |
| Segurança | ✅ Sanctum, validação, .env gitignored |
| Testes domínio | ✅ Unit tests pontuação/ranking |
| Simplicidade | ✅ Sem microserviços |

## Project Structure

```text
backend/                    # Laravel API
├── app/Models/
├── app/Services/
├── app/Http/Controllers/Api/
├── database/migrations/
├── database/seeders/
└── routes/api.php

mobile/                     # Flutter (fase 2)
design/stitch/              # UI export Stitch
specs/bolao-copa-2026/      # Spec, plan, contracts
docker-compose.yml
```

**Structure Decision**: Monorepo com `backend/` (Laravel) + `mobile/` (Flutter futuro) + `design/stitch/` (referência UI).

## Phases

### Phase 0 — Research ✅
- Ver [research.md](./research.md)

### Phase 1 — Design ✅
- [data-model.md](./data-model.md)
- [contracts/openapi.yaml](./contracts/openapi.yaml)
- [quickstart.md](./quickstart.md)

### Phase 2 — Implement MVP API (current)
1. Docker Compose (app + postgres)
2. Migrations: teams, matches, predictions
3. Sanctum auth (register/login)
4. Endpoints: matches, predictions, ranking, history
5. Seeder Copa 2026 (times + jogos amostra)
6. Unit tests ScoreCalculator

### Phase 3 — Flutter app
1. Theme from DESIGN.md
2. Telas Stitch → widgets
3. Integração API

## Complexity Tracking

Nenhuma violação da constituição que exija justificativa extra.
