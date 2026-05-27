# Data Model — Bolão Copa do Mundo 2026

## Team

| Field | Type | Notes |
|-------|------|-------|
| id | bigint PK | |
| code | string(3) unique | ISO/FIFA code (BRA, ARG) |
| name | string | Nome oficial |
| flag_url | string nullable | URL da bandeira |
| group_name | string nullable | Grupo na fase de grupos |

## Match

| Field | Type | Notes |
|-------|------|-------|
| id | bigint PK | |
| home_team_id | FK teams | |
| away_team_id | FK teams | |
| kickoff_at | datetime | Início do jogo (UTC) |
| stage | string | group, round_of_32, quarter, semi, final |
| group_name | string nullable | |
| venue | string nullable | |
| status | enum | scheduled, live, finished, postponed |
| home_score | int nullable | Resultado oficial |
| away_score | int nullable | Resultado oficial |

**Rules**: `home_team_id != away_team_id`. Scores só preenchidos quando `status = finished`.

## Prediction

| Field | Type | Notes |
|-------|------|-------|
| id | bigint PK | |
| user_id | FK users | |
| match_id | FK matches | |
| home_score | int >= 0 | Palpite mandante |
| away_score | int >= 0 | Palpite visitante |
| points | int default 0 | Calculado após resultado |
| created_at / updated_at | timestamps | |

**Unique**: `(user_id, match_id)` — um palpite por usuário por jogo.

**Validation**: Só permitir upsert se `now < match.kickoff_at` e `match.status = scheduled`.

## User (Laravel default + extensões)

| Field | Type | Notes |
|-------|------|-------|
| id | bigint PK | |
| name | string | |
| email | string unique | |
| password | hashed | |
| created_at | timestamp | Usado no desempate |

## Score calculation (derived)

```
if match not finished -> points = null
if predicted == actual -> 2
else if sign(predicted_diff) == sign(actual_diff) -> 1  // includes draw
else -> 0
```

## Ranking (view/query)

Agregação por `user_id`:
- `total_points = SUM(predictions.points)`
- `exact_hits = COUNT(points = 2)`
- `result_hits = COUNT(points >= 1)`
- Ordenação: total_points DESC, exact_hits DESC, result_hits DESC, users.created_at ASC
