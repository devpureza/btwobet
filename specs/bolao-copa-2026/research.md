# Research — Bolão Copa do Mundo 2026

## Autenticação API

- **Decision**: Laravel Sanctum (token Bearer) para o app Flutter.
- **Rationale**: Nativo no ecossistema Laravel, simples para mobile, suporta registro/login e rotas protegidas.
- **Alternatives considered**: Passport (OAuth2 completo — overkill para MVP), JWT manual (mais manutenção).

## Fonte de dados Copa 2026

- **Decision**: Seed inicial em JSON no repositório + comando Artisan `worldcup:import` para reimportar/atualizar.
- **Rationale**: Garante ambiente reproduzível offline; depois pode integrar API externa (FIFA/ESPN/etc.).
- **Alternatives considered**: Scraping em tempo real (instável), banco manual (lento para MVP).

## Desempate no ranking

- **Decision**: (1) total de pontos DESC → (2) acertos de placar exato DESC → (3) acertos de resultado DESC → (4) data de cadastro ASC.
- **Rationale**: Recompensa precisão e desempata de forma determinística.
- **Alternatives considered**: Sorteio, último palpite mais cedo (menos justo para quem acerta mais placares).

## Deadline de palpite

- **Decision**: Bloquear criação/edição quando `now >= match.kickoff_at`.
- **Rationale**: Regra padrão de bolão, fácil de entender e testar.
- **Alternatives considered**: Deadline fixo (ex. 1h antes) — pode virar config futura.

## Banco de dados local/dev

- **Decision**: SQLite no MVP local; PostgreSQL no Docker Compose para ambiente compartilhado.
- **Rationale**: SQLite acelera bootstrap; Postgres prepara produção.
- **Alternatives considered**: MySQL only — Postgres é padrão comum em Laravel moderno.

## Frontend Flutter (fase 2)

- **Decision**: Consumir API REST; UI baseada no design Stitch (`design/stitch/DESIGN.md`).
- **Rationale**: Backend como fonte de verdade; Flutter apenas apresenta.
- **Alternatives considered**: WebView do HTML Stitch — não atende mobile nativo/responsivo.
