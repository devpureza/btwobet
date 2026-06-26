# Auto-preenchimento do mata-mata — Design

**Data:** 2026-06-26
**Branch:** `feat/mata-mata-auto-fill`
**Status:** aprovado (brainstorm), pendente implementação

## Problema

Os 31 jogos do mata-mata já existem no banco, mas com **times-placeholder** (`2A`, `1C`, `3A/B/C/D/F`, `W73`, `L101`…). Hoje **nada** preenche os times reais conforme a Copa avança:

- O sync (`WorldCupScoreSyncService`) só atualiza **placar e status** — nunca escreve `home_team_id`/`away_team_id`, e casa jogos por **nome dos times**, o que falha com placeholder.
- Não existe resolver de classificação de grupos, nem avançador de chaveamento.
- O endpoint admin `PATCH /admin/matches/{id}` nem aceita `home_team_id`/`away_team_id`.

Resultado: enquanto os times forem placeholder, o `PredictionWindow` bloqueia palpites com *"Aguardando definição dos times"* → **a galera não consegue palpitar a 2ª fase**.

## Insight central (valida a abordagem)

A API **football-data.org** (que já usamos para placares, competição `WC`) **resolve o chaveamento inteiro sozinha e progressivamente**. Verificado ao vivo em 26/06:

- 104 jogos, fases estruturadas: `LAST_32` (16), `LAST_16` (8), `QUARTER_FINALS` (4), `SEMI_FINALS` (2), `THIRD_PLACE` (1), `FINAL` (1).
- Conforme cada grupo termina, a API preenche os times reais dos `LAST_32` (ex.: já tínhamos `Brazil x Japan`, `Netherlands x Morocco`).
- O objeto do jogo traz `score.winner` (`HOME_TEAM`/`AWAY_TEAM`/`DRAW`) e `score.duration` (`REGULAR`/`EXTRA_TIME`/`PENALTY_SHOOTOUT`) → **quem avançou, inclusive nos pênaltis**.

**Consequência:** não precisamos computar classificação, melhores terceiros, nem resolver pênaltis. **Só espelhamos** o que a API já resolveu.

## Realidade do prod (validada via API admin, read-only)

- **31** jogos `stage=knockout`, **todos ainda placeholder** (sync atual não preenche).
- O jogo de **3º lugar existe mas está mal-rotulado**: `id=111`, 18/07, `L101 x L102`, Miami, com `stage="group"` (por isso aparecem 73 "group"). Precisa virar `knockout`.
- **Bug latente:** `TeamSlot::isPlaceholder()` só reconhece placeholders de grupo (`2A`, `3A/B/C/D/F`), **não** `W{n}`/`L{n}`. Por isso `L101 x L102` aparece com `teams_defined=true` e pode abrir pra palpite mostrando "W73 x W75".

## Objetivos

1. Preencher automaticamente os times reais do mata-mata conforme a API resolve, em cascata (16-avos → oitavas → … → final), incluindo pênaltis.
2. Override manual do admin como rede de segurança (atraso/erro da API).
3. Nenhum jogo "nasce fechado" na virada (janela mínima quando os times definem tarde).
4. Bloquear corretamente palpites em jogos ainda indefinidos (`W{n}`/`L{n}` incluídos).

### Não-objetivos
- Computar classificação de grupos / melhores terceiros internamente (a API faz).
- Pontuação de "quem passa" (Opção 2 da enquete) — **fora deste escopo**, fica plugável (ver §8).

## Arquitetura (abordagem: espelho da API + override admin)

### 1. Chave de ligação estável: `external_id`
- **Migration aditiva:** coluna `external_id` (nullable, unique) em `matches`.
- **Comando de backfill** (`worldcup:link-external-ids`, idempotente): casa cada jogo nosso ao da API por **`stage` + `utcDate`** (determinístico) e grava o `external_id` da API.
- **Reconciliação:** ao casar `id=111` (hoje `group`, 18/07) com o `THIRD_PLACE` da API, **corrige `stage` para `knockout`**. Loga jogos órfãos (nosso sem par / API sem par).
- A partir daí o sync casa por `external_id` → funciona com placeholder. Conserta de quebra o sync de placar do mata-mata.

### 2. Espelhamento dos times (o coração)
No sync, para cada jogo da API com times **reais** (nome não-placeholder):
- Resolve/cria o `Team` pelo nome (reusa `TeamNameMatcher` PT-BR).
- Seta `home_team_id`/`away_team_id` no jogo correspondente (via `external_id`).
- Idempotente, no mesmo ciclo de 5 min. Auto-preenche em cascata.
- **Não sobrescreve** se `teams_locked = true` (override admin).
- Ao definir os dois times pela primeira vez, grava `teams_defined_at = now()`.

### 3. Captura de quem avançou
- Estende o mapeamento do provider para ler `score.winner` e `score.duration`.
- Guarda o time que avançou (inclui pênaltis). Não é necessário para a cascata (a API já cascateia), mas é **pré-requisito da Opção 2** de pontuação e é barato/future-proof.

### 4. `TeamSlot` — reconhecer `W{n}`/`L{n}`
- Estender `TeamSlot::isPlaceholder()` para também tratar `^[WL]\d+$` (vencedor/perdedor do jogo N) como placeholder.
- Fecha o bug de jogos de oitavas+ e 3º lugar "abrindo" com nome lixo.

### 5. Override do admin
- `PATCH /admin/matches/{id}` passa a aceitar `home_team_id` / `away_team_id` (validados contra `teams`).
- **Migration aditiva:** `teams_locked` (bool, default false). Setar times manualmente liga o lock → sync não sobrescreve.
- UI admin Flutter: seletor de time no diálogo de edição do jogo (`admin_matches_screen.dart`).

### 6. Janela de palpite na definição tardia
- **Migration aditiva:** `teams_defined_at` (timestamp nullable).
- `PredictionWindow.deadlineForMatch` (mata-mata): normal = `kickoff − knockout_hours_before`; **se os times foram definidos tarde** (depois desse prazo), abre até `kickoff − LATE_MIN_HOURS` (default **3h**, mantém o reveal da comunidade de 2h relevante).

## §8. Pontuação (deferida, plugável)

A enquete da galera decide entre:
- **Opção 1** (status quo): 2 pts placar exato / 1 pt resultado / 0. **Nenhuma mudança.**
- **Opção 2**: +1 por "acertou quem passa" — exige campo "quem passa?" no palpite (só quando o usuário palpita empate) + `+1` no `ScoreCalculator` no mata-mata, usando `score.winner` (§3).

A engine de auto-preenchimento é **agnóstica à pontuação**. A Opção 2, se vencer, entra como peça separada depois — sem bloquear nada.

## Segurança de produção

- **Todas as migrations são aditivas** (`external_id`, `teams_locked`, `teams_defined_at` — colunas novas nullable). Seguras com o `migrate --force` que roda no push pra `main`.
- A correção de `stage` do `id=111` é **1 UPDATE** não-destrutivo (rótulo), idempotente, via comando de backfill — não toca palpite/pontuação.
- O espelhamento só **preenche** times que hoje estão vazios; nunca apaga palpites/pontos.

## Riscos e edge cases

- **Timing da API:** pode definir times poucas horas antes → mitigado pela janela mínima (§6).
- **Nome de time divergente** (API vs nosso): `TeamNameMatcher`; se não casar, loga e o admin resolve via override.
- **Pênalti/empate na pontuação:** decisão da enquete (§8); a captura de `score.winner` já fica pronta.
- **Jogo órfão no backfill:** logado explicitamente; admin decide.

## Estratégia de testes

- Unit: `TeamSlot` (novos casos `W12`/`L101`), `PredictionWindow` (janela tardia), backfill matcher (stage+date), sync espelhando times (mock do provider).
- Feature: `PATCH /admin/matches` com team ids + lock; sync não sobrescreve lock.
- Verificação manual no local espelhado (já reflete o prod): rodar backfill + sync e ver os times preenchendo.

## Rollout

1. Migration aditiva + backfill (`link-external-ids`, com reconciliação do 3º lugar).
2. `TeamSlot` + espelhamento no sync + captura de winner.
3. Admin override (endpoint + UI) + janela tardia.
4. Validar no local; deploy (migrations aditivas, prod seguro).
5. (Depois da enquete) pontuação Opção 1/2.
