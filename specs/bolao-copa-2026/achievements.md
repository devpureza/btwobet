# Conquistas (Achievements) — Bolão Copa do Mundo 2026

**Status**: MVP + v2 (33 no catálogo, regras live para dados existentes)  
**Criado**: 2026-06-02  
**Atualizado**: 2026-06-02  
**Relacionado**: [spec.md](./spec.md), [data-model.md](./data-model.md), `ScoreCalculator`, `RankingService`, `PredictionWindow`

---

## Status de implementação

| Conjunto | Qtd | Status |
|----------|-----|--------|
| Catálogo completo (slugs PT-BR) | 33 | **Live** — seed em `2026_06_02_000002_expand_achievements_catalog.php` |
| Regras avaliadas automaticamente | 33 | **Live** — `AchievementEvaluator` + hooks em palpite/jogo/ranking |
| `bem-vindo` | 1 | **Live** — desbloqueio na primeira avaliação via API (sem duplicar regra de palpite no evaluator) |

### Regras live (por gatilho)

**Palpite (`on_prediction`)**: `primeiro-palpite`, `em-campo`, `dez-palpites`, `maratonista`, `presenca-confirmada`, `meia-centuria`, `mata-mata-chegou`, `fase-grupos-firme`, `estreia-da-copa`, `jogo-decisivo`, `grande-final`, `perfil-com-cara`, `semana-ativa`, `sem-miss-no-fds`, `bem-vindo` (via `AchievementService`)

**Jogo finalizado (`on_match_finished`)**: `placar-na-mosca`, `trio-perfeito`, `pontuador`, `artilheiro-de-acertos`, `sequencia-de-resultado`, `dupla-exata`, `empate-certeiro`, `zerinho`, `goleada-prevista`, `underdog-do-dia`, `oraculo`

**Ranking (`on_ranking_update`)**: `no-topo`, `podio`, `top-10`, `recuperacao`, `invicto-no-topo`, `vice-campeao`*, `campeao-do-bolao`*

\* `vice-campeao` e `campeao-do-bolao` exigem `tournament.tournament_closed = true` (setting admin).

---

## 1. Princípios de produto

| Princípio | Implicação para conquistas |
|-----------|----------------------------|
| **Sem dinheiro** | Nenhuma conquista concede prêmio em dinheiro, cashback ou “aposta”. Copy e UI falam em diversão, coleção e status social leve. |
| **Diversão e reconhecimento** | Conquistas celebram marcos jogáveis (primeiro palpite, sequências, pódio), não punem quem erra. Evitar conquistas negativas (“pior do bolão”). |
| **Justo para quem entra tarde** | Metas absolutas (ex.: “50 palpites”) continuam alcançáveis. Metas de “cobertura total” usam janela **desde o primeiro palpite** ou “jogos ainda abertos na conta do usuário”. Conquistas de **fim de torneio** comparam só quem teve oportunidade mínima (ex.: ≥ N jogos pontuados). |
| **Alinhado à pontuação oficial** | Regras usam `predictions.points` (0 / 1 / 2) após `match.status = finished`, como em [data-model.md](./data-model.md). |
| **Sem editar palpite** | O produto atual **não permite alterar** palpite após envio (`PredictionWindow`). Conquistas não assumem edição; ver edge cases. |
| **Transparência** | Cada conquista tem regra implementável, momento de avaliação e progresso numérico quando fizer sentido. |

---

## 2. Catálogo resumido

### MVP — 8 conquistas (lançamento)

| id | Nome (PT-BR) | Tier |
|----|----------------|------|
| `primeiro-palpite` | Primeiro Palpite | bronze |
| `em-campo` | Em Campo | bronze |
| `placar-na-mosca` | Placar na Mosca | silver |
| `trio-perfeito` | Trio Perfeito | silver |
| `pontuador` | Pontuador | bronze |
| `no-topo` | No Topo | gold |
| `podio` | Pódio | silver |
| `presenca-confirmada` | Presença Confirmada | bronze |

### Catálogo estendido — +17 conquistas (v2), por categoria

**Entrada & perfil**  
`bem-vindo`, `perfil-com-cara`

**Participação**  
`dez-palpites`, `meia-centuria`, `maratonista`, `fase-grupos-firme`, `mata-mata-chegou`

**Precisão**  
`artilheiro-de-acertos`, `sequencia-de-resultado`, `dupla-exata`, `empate-certeiro`, `zerinho`, `goleada-prevista`

**Ranking & competição**  
`top-10`, `vice-campeao`, `campeao-do-bolao`, `recuperacao`

**Ritmo & consistência**  
`semana-ativa`, `sem-miss-no-fds`

**Copa & momento**  
`estreia-da-copa`, `jogo-decisivo`, `grande-final`, `underdog-do-dia`

**Lendário**  
`oraculo`, `invicto-no-topo`

**Total no documento**: 8 (MVP) + 17 (v2) = **25 conquistas** (resumo); **33 slugs** no catálogo completo das seções detalhadas abaixo.

### Status de implementação (backend)

| Slug | Status | Notas |
|------|--------|-------|
| `primeiro-palpite` | ✅ | `on_prediction` |
| `em-campo` | ✅ | progresso 5 palpites |
| `placar-na-mosca` | ✅ | `on_match_finished` |
| `trio-perfeito` | ✅ | progresso 3 exatos |
| `pontuador` | ✅ | progresso 10 pts |
| `no-topo` | ✅ | `on_ranking_update`, ≥2 usuários pontuados |
| `podio` | ✅ | top 3, ≥3 usuários pontuados |
| `presenca-confirmada` | ✅ | 3 dias UTC de `kickoff_at` |
| `bem-vindo` | ✅ | desbloqueio no fluxo de avaliação (API) |
| `perfil-com-cara` | ✅ | `users.avatar_url`; reavalia no upload |
| `dez-palpites` | ✅ | progresso 10 |
| `meia-centuria` | ✅ | progresso 50 |
| `maratonista` | ✅ | 10 dias de kickoff distintos |
| `fase-grupos-firme` | ✅ | cobertura grupos após 1º palpite, min 8 jogos |
| `mata-mata-chegou` | ✅ | `stage != group` |
| `artilheiro-de-acertos` | ✅ | 10 exatos |
| `sequencia-de-resultado` | ✅ | 5 acertos seguidos |
| `dupla-exata` | ✅ | 2 exatos consecutivos |
| `empate-certeiro` | ✅ | empate previsto e real |
| `zerinho` | ✅ | 0x0 exato |
| `goleada-prevista` | ✅ | exato com ≥5 gols |
| `top-10` | ✅ | top 10, ≥10 usuários pontuados |
| `vice-campeao` | ✅ | `tournament_closed` + 2º + ≥20 jogos pontuados |
| `campeao-do-bolao` | ✅ | `tournament_closed` + 1º + ≥20 jogos pontuados |
| `recuperacao` | ✅ | sobe ≥5 posições entre snapshots |
| `semana-ativa` | ✅ | 7 dias seguidos com palpite |
| `sem-miss-no-fds` | ✅ | todos jogos sáb/dom de um fim de semana (≥4) |
| `estreia-da-copa` | ✅ | `matches.is_opening` ou menor `kickoff_at` |
| `jogo-decisivo` | ✅ | semifinal (`knockout_round = semi`) |
| `grande-final` | ✅ | palpite na final |
| `underdog-do-dia` | ✅ | vitória visitante + `home_is_favorite` no jogo |
| `oraculo` | ✅ | 15 placares exatos |
| `invicto-no-topo` | ✅ | 5 updates em 1º (`users.ranking_first_streak`) |

**Operação admin**: `settings.tournament_closed = 1` libera campeão/vice ao fechar a Copa.  
**Backfill**: `php artisan achievements:backfill`  
**Flags de jogo**: `matches.is_opening`, `matches.home_is_favorite` (seed/admin).

---

## 3. Definição completa por conquista

Convenções:

- **Jogo pontuado**: `match.status = finished` e `predictions.points` recalculado (0, 1 ou 2).
- **Placar exato**: `points = 2`.
- **Resultado correto** (inclui empate): `points >= 1`.
- **Dia de jogos**: data UTC de `matches.kickoff_at` (documentar no backend; app pode exibir em fuso local).
- **Posição no ranking**: mesma ordenação de `RankingService`: `total_points DESC`, `exact_hits DESC`, `result_hits DESC`, `users.created_at ASC`.

---

### MVP

#### `primeiro-palpite`

| Campo | Valor |
|-------|--------|
| **Nome** | Primeiro Palpite |
| **Descrição (UI)** | Você entrou em campo: registrou seu primeiro palpite. |
| **Regra** | `COUNT(predictions WHERE user_id = U) >= 1` após criar o primeiro registro. |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Não (desbloqueio binário) |
| **Ícone** | `Icons.sports_soccer` ou ⚽ |

#### `em-campo`

| Campo | Valor |
|-------|--------|
| **Nome** | Em Campo |
| **Descrição (UI)** | Cinco palpites registrados — você está jogando o bolão de verdade. |
| **Regra** | `COUNT(predictions WHERE user_id = U) >= 5` |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Sim — `current = count`, `max = 5` |
| **Ícone** | `Icons.directions_run` ou 🏃 |

#### `placar-na-mosca`

| Campo | Valor |
|-------|--------|
| **Nome** | Placar na Mosca |
| **Descrição (UI)** | Acertou o placar exato em um jogo (2 pontos). |
| **Regra** | `EXISTS(prediction P JOIN match M ON P.match_id = M.id WHERE P.user_id = U AND M.status = finished AND P.points = 2)` |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não |
| **Ícone** | `Icons.adjust` ou 🎯 |

#### `trio-perfeito`

| Campo | Valor |
|-------|--------|
| **Nome** | Trio Perfeito |
| **Descrição (UI)** | Três placares exatos no bolão — precisão de craque. |
| **Regra** | `COUNT(predictions WHERE user_id = U AND points = 2) >= 3` |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Sim — `current = exact_hits`, `max = 3` |
| **Ícone** | `Icons.looks_3` ou 🎩 |

#### `pontuador`

| Campo | Valor |
|-------|--------|
| **Nome** | Pontuador |
| **Descrição (UI)** | Somou 10 pontos no ranking do bolão. |
| **Regra** | `SUM(predictions.points WHERE user_id = U AND match finished) >= 10` |
| **Tier** | bronze |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Sim — `current = total_points`, `max = 10` |
| **Ícone** | `Icons.star` ou ⭐ |

#### `no-topo`

| Campo | Valor |
|-------|--------|
| **Nome** | No Topo |
| **Descrição (UI)** | Chegou ao 1º lugar do ranking geral (mesmo que por um instante). |
| **Regra** | Após `on_ranking_update`, usuário `U` tem `position = 1` na lista completa (mínimo 2 usuários com ≥1 jogo pontuado; se só 1 usuário, não desbloqueia). |
| **Tier** | gold |
| **Avaliar em** | `on_ranking_update` |
| **Progresso** | Não |
| **Ícone** | `Icons.emoji_events` ou 🏆 |

#### `podio`

| Campo | Valor |
|-------|--------|
| **Nome** | Pódio |
| **Descrição (UI)** | Entrou no top 3 do ranking geral. |
| **Regra** | `position <= 3` após ranking update; mínimo 3 usuários com `scored_predictions >= 1`. |
| **Tier** | silver |
| **Avaliar em** | `on_ranking_update` |
| **Progresso** | Não |
| **Ícone** | `Icons.workspace_premium` ou 🥉 |

#### `presenca-confirmada`

| Campo | Valor |
|-------|--------|
| **Nome** | Presença Confirmada |
| **Descrição (UI)** | Palpitou em 3 dias diferentes com jogos — ritmo de torcedor. |
| **Regra** | Conjunto `D = DISTINCT(DATE(kickoff_at))` de jogos em que `U` tem prediction; desbloqueia se `|D| >= 3`. |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` (e opcionalmente `daily_cron` para backfill) |
| **Progresso** | Sim — `current = |D|`, `max = 3` |
| **Ícone** | `Icons.event_available` ou 📅 |

---

### Estendido — Entrada & perfil

#### `bem-vindo`

| Campo | Valor |
|-------|--------|
| **Nome** | Bem-vindo |
| **Descrição (UI)** | Conta criada — a Copa te espera. |
| **Regra** | `users.id = U` existe (desbloqueio no primeiro login autenticado bem-sucedido após cadastro). |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` (primeiro evento pós-login) ou no login se houver hook |
| **Progresso** | Não |
| **Ícone** | `Icons.waving_hand` ou 👋 |

#### `perfil-com-cara`

| Campo | Valor |
|-------|--------|
| **Nome** | Perfil com Cara |
| **Descrição (UI)** | Adicionou foto no perfil. |
| **Regra** | `users.avatar_url IS NOT NULL` (e não vazio). |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` ou endpoint de update de perfil (avaliar ao salvar avatar) |
| **Progresso** | Não |
| **Ícone** | `Icons.face` ou 🙂 |

---

### Estendido — Participação

#### `dez-palpites`

| Campo | Valor |
|-------|--------|
| **Nome** | Dez Palpites |
| **Descrição (UI)** | Dez jogos com palpite registrado. |
| **Regra** | `COUNT(predictions WHERE user_id = U) >= 10` |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Sim — `max = 10` |
| **Ícone** | `Icons.filter_9_plus` ou 🔟 |

#### `meia-centuria`

| Campo | Valor |
|-------|--------|
| **Nome** | Meia Centúria |
| **Descrição (UI)** | Cinquenta palpites — veterano do bolão. |
| **Regra** | `COUNT(predictions WHERE user_id = U) >= 50` |
| **Tier** | gold |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Sim — `max = 50` |
| **Ícone** | `Icons.military_tech` ou 💯 |

#### `maratonista`

| Campo | Valor |
|-------|--------|
| **Nome** | Maratonista |
| **Descrição (UI)** | Dez dias de jogos com pelo menos um palpite. |
| **Regra** | `|DISTINCT DATE(kickoff_at) com prediction de U| >= 10` |
| **Tier** | silver |
| **Avaliar em** | `on_prediction`, `daily_cron` |
| **Progresso** | Sim — `max = 10` |
| **Ícone** | `Icons.calendar_month` ou 🗓️ |

#### `fase-grupos-firme`

| Campo | Valor |
|-------|--------|
| **Nome** | Fase de Grupos Firme |
| **Descrição (UI)** | Palpitou em todos os jogos de grupos que ainda estavam abertos quando você começou. |
| **Regra** | Seja `M_open` = jogos com `stage = group` e `kickoff_at > first_prediction_at(U)`. Desbloqueia se `COUNT(predictions de U em M_open) = COUNT(M_open)` e `COUNT(M_open) >= 8` (evita conquista vazia em bolão de teste). |
| **Tier** | gold |
| **Avaliar em** | `on_prediction`, `daily_cron` (após fechar último grupo aberto na janela) |
| **Progresso** | Sim — `current / COUNT(M_open)` |
| **Ícone** | `Icons.groups` ou 🌍 |

#### `mata-mata-chegou`

| Campo | Valor |
|-------|--------|
| **Nome** | Mata-mata Chegou |
| **Descrição (UI)** | Primeiro palpite em jogo de mata-mata (`stage` ≠ `group`). |
| **Regra** | `EXISTS(prediction JOIN match WHERE user_id = U AND match.stage IN ('round_of_32','quarter','semi','final','knockout'))` — alinhar enum real do schema. |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Não |
| **Ícone** | `Icons.sports` ou ⚔️ |

---

### Estendido — Precisão

#### `artilheiro-de-acertos`

| Campo | Valor |
|-------|--------|
| **Nome** | Artilheiro de Acertos |
| **Descrição (UI)** | Dez placares exatos no bolão. |
| **Regra** | `COUNT(points = 2) >= 10` |
| **Tier** | gold |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Sim — `max = 10` |
| **Ícone** | `Icons.sports_score` ou 🥅 |

#### `sequencia-de-resultado`

| Campo | Valor |
|-------|--------|
| **Nome** | Sequência de Resultado |
| **Descrição (UI)** | Acertou o resultado (vitória ou empate) em 5 jogos seguidos no tempo. |
| **Regra** | Ordenar jogos pontuados de `U` por `kickoff_at ASC`. Maior sequência contígua com `points >= 1` >= 5. |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Sim — `current = melhor sequência`, `max = 5` |
| **Ícone** | `Icons.trending_up` ou 📈 |

#### `dupla-exata`

| Campo | Valor |
|-------|--------|
| **Nome** | Dupla Exata |
| **Descrição (UI)** | Dois placares exatos seguidos (por ordem de kickoff). |
| **Regra** | Existe par consecutivo na ordem `kickoff_at` com `points = 2` em ambos. |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não (ou `current` 0/1/2 para “quase”) |
| **Ícone** | `Icons.done_all` ou ✌️ |

#### `empate-certeiro`

| Campo | Valor |
|-------|--------|
| **Nome** | Empate Certeiro |
| **Descrição (UI)** | Previu empate e o jogo terminou empatado (vale 1 ou 2 pts). |
| **Regra** | `EXISTS` jogo finished onde `actual_home = actual_away` e `predicted_home = predicted_away` e `points >= 1`. |
| **Tier** | bronze |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não |
| **Ícone** | `Icons.balance` ou ⚖️ |

#### `zerinho`

| Campo | Valor |
|-------|--------|
| **Nome** | Zerinho |
| **Descrição (UI)** | Palpitou 0x0 e saiu 0x0 (placar exato). |
| **Regra** | `EXISTS` prediction com `home_score=0, away_score=0` e match finished `0-0`, `points=2`. |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não |
| **Ícone** | `Icons.exposure_zero` ou 0️⃣ |

#### `goleada-prevista`

| Campo | Valor |
|-------|--------|
| **Nome** | Goleada Prevista |
| **Descrição (UI)** | Acertou placar exato com soma de gols ≥ 5 no jogo. |
| **Regra** | `points = 2` e `(actual_home + actual_away) >= 5` e placar previsto igual ao real. |
| **Tier** | gold |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não |
| **Ícone** | `Icons.whatshot` ou 🔥 |

---

### Estendido — Ranking & competição

#### `top-10`

| Campo | Valor |
|-------|--------|
| **Nome** | Top 10 |
| **Descrição (UI)** | Entrou entre os dez primeiros do ranking. |
| **Regra** | `position <= 10` após ranking update; mínimo 10 usuários com `scored_predictions >= 1`. |
| **Tier** | silver |
| **Avaliar em** | `on_ranking_update` |
| **Progresso** | Não |
| **Ícone** | `Icons.format_list_numbered` ou 🔟 |

#### `vice-campeao`

| Campo | Valor |
|-------|--------|
| **Nome** | Vice do Bolão |
| **Descrição (UI)** | Terminou a Copa em 2º no ranking (fechamento oficial). |
| **Regra** | Job manual/admin marca `tournament_closed = true`; então `position = 2` e `scored_predictions >= 20` (anti late-join de 1 jogo). |
| **Tier** | gold |
| **Avaliar em** | `daily_cron` ou ação admin `on_tournament_closed` |
| **Progresso** | Não |
| **Ícone** | `Icons.looks_two` ou 🥈 |

#### `campeao-do-bolao`

| Campo | Valor |
|-------|--------|
| **Nome** | Campeão do Bolão |
| **Descrição (UI)** | 1º lugar no ranking final da Copa. |
| **Regra** | `tournament_closed` e `position = 1` e `scored_predictions >= 20`. |
| **Tier** | legendary |
| **Avaliar em** | `on_tournament_closed` |
| **Progresso** | Não |
| **Ícone** | `Icons.emoji_events` (dourado) ou 👑 |

#### `recuperacao`

| Campo | Valor |
|-------|--------|
| **Nome** | Recuperação |
| **Descrição (UI)** | Subiu pelo menos 5 posições no ranking entre duas atualizações consecutivas. |
| **Regra** | Persistir `last_position` por usuário; se `last_position - current_position >= 5`, desbloqueia (uma vez). |
| **Tier** | silver |
| **Avaliar em** | `on_ranking_update` |
| **Progresso** | Não |
| **Ícone** | `Icons.rocket_launch` ou 🚀 |

---

### Estendido — Ritmo & consistência

#### `semana-ativa`

| Campo | Valor |
|-------|--------|
| **Nome** | Semana Ativa |
| **Descrição (UI)** | Palpitou em pelo menos um jogo em 7 dias corridos diferentes. |
| **Regra** | Existe janela deslizante de 7 dias UTC com ≥1 prediction por dia (dias com jogos ou não — usar dias do calendário em que houve palpite). |
| **Tier** | silver |
| **Avaliar em** | `daily_cron` |
| **Progresso** | Sim — `current` dias na melhor janela, `max = 7` |
| **Ícone** | `Icons.date_range` ou 📆 |

#### `sem-miss-no-fds`

| Campo | Valor |
|-------|--------|
| **Nome** | Fim de Semana Completo |
| **Descrição (UI)** | Palpitou em todos os jogos de um fim de semana (sáb+dom UTC) que ainda estavam abertos. |
| **Regra** | Para um fim de semana `W`, `M_W` = jogos sáb/dom com deadline após início de `W`. Desbloqueia se usuário tem prediction em cada jogo de `M_W` e `|M_W| >= 4`. |
| **Tier** | gold |
| **Avaliar em** | `daily_cron` (segunda-feira) |
| **Progresso** | Parcial por fim de semana |
| **Ícone** | `Icons.weekend` ou 🎉 |

---

### Estendido — Copa & momento

#### `estreia-da-copa`

| Campo | Valor |
|-------|--------|
| **Nome** | Estreia da Copa |
| **Descrição (UI)** | Palpitou no jogo de abertura (match marcado `is_opening = true` ou menor `kickoff_at` do torneio). |
| **Regra** | Prediction no jogo configurado como abertura no seed/admin. |
| **Tier** | bronze |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Não |
| **Ícone** | `Icons.flag` ou 🏁 |

#### `jogo-decisivo`

| Campo | Valor |
|-------|--------|
| **Nome** | Jogo Decisivo |
| **Descrição (UI)** | Palpitou em uma semifinal ou jogo configurado como “decisivo”. |
| **Regra** | `stage IN ('semi')` ou flag `is_knockout_decider` no match. |
| **Tier** | silver |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Não |
| **Ícone** | `Icons.bolt` ou ⚡ |

#### `grande-final`

| Campo | Valor |
|-------|--------|
| **Nome** | Grande Final |
| **Descrição (UI)** | Enviou palpite na final da Copa. |
| **Regra** | Prediction em match com `stage = final`. |
| **Tier** | gold |
| **Avaliar em** | `on_prediction` |
| **Progresso** | Não |
| **Ícone** | `Icons.stadium` ou 🏟️ |

#### `underdog-do-dia`

| Campo | Valor |
|-------|--------|
| **Nome** | Underdog do Dia |
| **Descrição (UI)** | Acertou vitória do visitante (resultado correto) quando o mandante era favorito. |
| **Regra** | Match finished; `actual_away > actual_home`; prediction acertou resultado (`points >= 1`); `home_team.fifa_ranking > away_team.fifa_ranking` ou flag `home_is_favorite` no match (definir fonte no seed). Se ranking indisponível, usar `home_team.code` seed do admin. |
| **Tier** | silver |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Não |
| **Ícone** | `Icons.pets` ou 🦊 |

---

### Estendido — Lendário

#### `oraculo`

| Campo | Valor |
|-------|--------|
| **Nome** | Oráculo |
| **Descrição (UI)** | Quinze placares exatos na mesma Copa — raríssimo. |
| **Regra** | `COUNT(points = 2) >= 15` |
| **Tier** | legendary |
| **Avaliar em** | `on_match_finished` |
| **Progresso** | Sim — `max = 15` |
| **Ícone** | `Icons.auto_awesome` ou 🔮 |

#### `invicto-no-topo`

| Campo | Valor |
|-------|--------|
| **Nome** | Invicto no Topo |
| **Descrição (UI)** | Ficou 5 atualizações de ranking seguidas em 1º lugar. |
| **Regra** | Contador `streak_at_first`; incrementa em cada `on_ranking_update` se `position=1`, zera caso contrário; desbloqueia em `>= 5`. |
| **Tier** | legendary |
| **Avaliar em** | `on_ranking_update` |
| **Progresso** | Sim — `max = 5` |
| **Ícone** | `Icons.shield` ou 🛡️ |

---

## 4. Modelo de dados proposto

### Tabela `achievements` (catálogo estático)

| Campo | Tipo | Notas |
|-------|------|-------|
| id | bigint PK | |
| slug | string unique | ex.: `primeiro-palpite` |
| name | string | PT-BR |
| description | string | Uma linha para UI |
| tier | enum | bronze, silver, gold, legendary |
| category | string | entrada, participacao, precisao, ranking, ritmo, copa, lendario |
| icon_key | string | Nome Material Icons |
| evaluate_on | set/json | on_prediction, on_match_finished, … |
| rule_version | int | Incrementar se regra mudar (migração de progresso) |
| is_active | boolean | Permite desligar sem apagar histórico |
| sort_order | int | Grid na UI |
| max_progress | int nullable | Null = não rastreia progresso |
| created_at | timestamp | |

Seed via migration ou `AchievementSeeder` alinhado a este documento.

### Tabela `user_achievements` (desbloqueios)

| Campo | Tipo | Notas |
|-------|------|-------|
| id | bigint PK | |
| user_id | FK users | |
| achievement_id | FK achievements | |
| unlocked_at | datetime | |
| progress_at_unlock | int nullable | Snapshot do progresso |
| notified_at | datetime nullable | App já mostrou toast |

**Unique**: `(user_id, achievement_id)`.

### Tabela `user_achievement_progress` (opcional, recomendada)

Para barras “2/3” sem recalcular agregações pesadas a cada request.

| Campo | Tipo | Notas |
|-------|------|-------|
| user_id | FK | |
| achievement_id | FK | |
| current_value | int | |
| updated_at | datetime | |

**Unique**: `(user_id, achievement_id)`.

Alternativa MVP: calcular progresso on-the-fly só para conquistas com `max_progress` e cache curto (Redis 60s). v2: materializar em `user_achievement_progress`.

### Tabela auxiliar `user_ranking_snapshots` (v2, ranking)

| Campo | Tipo | Notas |
|-------|------|-------|
| user_id | FK | |
| position | int | |
| total_points | int | |
| captured_at | datetime | |

Alimentada em `on_ranking_update` para `recuperacao` e `invicto-no-topo`.

### Flag global `bolao_settings.tournament_closed` (v2)

Boolean setado pelo admin ao fim da Copa; dispara avaliação de `campeao-do-bolao` e `vice-campeao`.

---

## 5. Esboço de API

Autenticação: Bearer token (mesmo padrão atual). Sem endpoints admin especiais para conquistas no MVP — catálogo é seed; desbloqueio é server-side.

### `GET /api/me/achievements`

Lista conquistas para o usuário autenticado.

**Query**: `?category=precisao` (opcional), `?unlocked_only=false` (default: todas).

**Response 200**:

```json
{
  "data": {
    "summary": {
      "unlocked_count": 3,
      "total_active": 8,
      "by_tier": { "bronze": 2, "silver": 1, "gold": 0, "legendary": 0 }
    },
    "achievements": [
      {
        "slug": "trio-perfeito",
        "name": "Trio Perfeito",
        "description": "Três placares exatos no bolão — precisão de craque.",
        "tier": "silver",
        "category": "precisao",
        "icon_key": "looks_3",
        "unlocked": false,
        "unlocked_at": null,
        "progress": { "current": 2, "max": 3 }
      }
    ],
    "recent_unlocks": [
      {
        "slug": "placar-na-mosca",
        "name": "Placar na Mosca",
        "unlocked_at": "2026-06-15T22:05:00Z"
      }
    ]
  }
}
```

`recent_unlocks`: últimos 5 com `notified_at IS NULL` ou últimas 24h — app marca como visto via `POST /api/me/achievements/dismiss-notifications` (v2 opcional).

### `GET /api/users/{id}/achievements`

**Público entre participantes autenticados** (mesmo bolão): exibe apenas conquistas **desbloqueadas** + contagem total (não expõe progresso parcial de terceiros — privacidade e anti-gaming).

**Response 200**:

```json
{
  "data": {
    "user_id": 42,
    "name": "Maria",
    "unlocked_count": 12,
    "achievements": [
      {
        "slug": "podio",
        "name": "Pódio",
        "tier": "silver",
        "icon_key": "workspace_premium",
        "unlocked_at": "2026-07-01T10:00:00Z"
      }
    ]
  }
}
```

**404** se usuário não existir. **401** se não autenticado.

### Eventos internos (não REST)

| Hook | Ação |
|------|------|
| Após `PredictionController@store` | `AchievementEvaluator::onPrediction($user, $prediction)` |
| Após `RankingService::recalculateForMatch` | `onMatchFinished` + `onRankingUpdate` |
| Scheduler diário | `evaluateDaily()` — semana ativa, fim de semana, backfill presença |

---

## 6. Esboço de UI (Flutter)

### Navegação

- Rota: `/profile/achievements` (filha de `/profile`).
- Entrada: card “Conquistas” na `ProfileScreen` com badge `3/8` (MVP).
- Deep link opcional v2: `/users/:id/achievements` a partir do ranking (toque no avatar).

Registrar em `app_router.dart` dentro do `ShellRoute`, similar a `/history`.

### Tela `AchievementsScreen`

- **AppBar**: “Conquistas” + chip resumo (`3 de 8`).
- **Filtros** (v2): chips por categoria.
- **Grid** 2 colunas (mobile), 3–4 (desktop ≥900px).
- **Card desbloqueado**: ícone colorido (tier → cor: bronze `#CD7F32`, silver `#C0C0C0`, gold `#FFD700` alinhado ao design system), nome, data “Desbloqueou em 15/06”.
- **Card bloqueado**: ícone em `onSurface` 38% opacidade, cadeado pequeno, descrição, barra de progresso se `max != null`, texto “2/3”.
- **Detalhe** (bottom sheet ao toque): descrição completa, regra amigável (“Acerte 3 placares exatos”), tier.

### Toast / celebração no desbloqueio

- Ao receber `recent_unlocks` no poll pós-jogo ou após salvar palpite: `SnackBar` ou overlay glass com ícone, nome e tier.
- Marcar `notified_at` no backend no próximo `GET /me/achievements` ou endpoint dismiss.
- Não bloquear fluxo de palpite — toast não modal.

### Ranking / perfil público

- Na lista do ranking: até 3 ícones mini das conquistas **legendary/gold** mais recentes (v2).
- Perfil de outro usuário: grid só desbloqueadas (read-only).

---

## 7. Fases de implementação

### Fase MVP (8 conquistas)

1. Migrations: `achievements`, `user_achievements`, seed das 8.
2. `AchievementEvaluator` com handlers `on_prediction`, `on_match_finished`, `on_ranking_update`.
3. Integrar chamadas em `PredictionController` e `RankingService`.
4. `GET /api/me/achievements` + modelos Eloquent.
5. Flutter: tela grid + link no perfil + snackbar simples.
6. Testes unitários das regras críticas (pontos 0/1/2, contagem, posição ranking).

**Fora do MVP**: progress table materializada, perfil público, cron diário, conquistas de fechamento de torneio.

### Fase v2 (catálogo completo + polish)

1. Seed +17 conquistas; `user_achievement_progress`; cron diário.
2. `GET /api/users/{id}/achievements`; snapshots de ranking.
3. `tournament_closed` + campeão/vice.
4. Filtros, detalhe, mini-badges no ranking, dismiss notifications.
5. Job de **reavaliação** após reset admin (ver §8).

---

## 8. Casos de borda e políticas

### Entrada tardia

- Conquistas por **volume** (`em-campo`, `dez-palpites`) permanecem justas — meta absoluta.
- Conquistas de **cobertura** (`fase-grupos-firme`, `sem-miss-no-fds`) usam janela desde `first_prediction_at` ou jogos ainda abertos; exigir mínimo de jogos na janela.
- `campeao-do-bolao` / `vice-campeao`: exigir `scored_predictions >= 20` (ajustar ao total real de jogos da Copa × % mínima, ex. 30%).

### Jogo adiado (`postponed`)

- Palpite **mantido**; deadline recalculada quando voltar `scheduled`.
- Conquistas por **dia** usam `kickoff_at` **atual** (não a data original) para evitar duplicar dias.
- Não desbloquear/lockar até o jogo ser `finished` para conquistas de precisão.

### Jogo anulado / sem resultado válido

- Se admin marcar jogo como `postponed` indefinidamente ou criar status futuro `voided`: `points = null` ou não recalcular; conquistas de precisão **não** contam esse jogo; sequências **não quebram** (ignorar jogo no encadeamento).
- Documentar: apenas `finished` com placar entra em agregações.

### Palpite “editado”

- Produto atual: **sem edição** após envio. Conquistas avaliam no `on_prediction` do create.
- Se no futuro existir update: reavaliar só conquistas de participação; precisão só após `finished`.

### Admin limpa palpites (`clearUserPredictions` / `resetGameState`)

- **Limpar palpites de um usuário**: remover `user_achievements` desse usuário **ou** rodar `AchievementReconciler` para recalcular do zero; zerar `user_achievement_progress`.
- **Reset global de jogos/palpites**: opcional manter conquistas (coleção “histórica”) **ou** wipe total — recomendação: **wipe** `user_achievements` + progress em reset global; aviso na UI admin.
- **migrate:fresh**: conquistas resetam naturalmente.

### Ranking com poucos usuários

- `no-topo` exige ≥2 usuários com pelo menos 1 jogo pontuado.
- `podio` exige ≥3; `top-10` exige ≥10.

### Empate no ranking

- Vários usuários podem ter `position = 1` nos critérios de desempate — todos elegíveis a `no-topo` naquela snapshot.

### Usuário sem palpite em jogo já iniciado

- Não penaliza conquistas de participação; apenas não conta para cobertura daquele jogo.

---

## 9. Métricas de sucesso (pós-lançamento)

- % usuários com ≥1 conquista na primeira semana.
- Média de conquistas desbloqueadas por usuário ativo.
- Taxa de abertura da tela Conquistas (evento analytics).
- Correlação entre conquistas de participação e retenção de palpites na rodada seguinte.

---

## 10. Referência rápida — regras de pontuação (inalteradas)

```
placar exato     → 2 pontos
resultado certo  → 1 ponto  (inclui empate)
erro             → 0 pontos
```

Implementação: `App\Services\ScoreCalculator`.

---

*Documento para revisão. Não substitui tasks de implementação em [tasks.md](./tasks.md); adicionar work items quando aprovado.*
