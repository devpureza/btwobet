# Feature Specification: Bolão Copa do Mundo 2026

**Feature Branch**: `[000-bolao-copa-2026]`

**Created**: 2026-05-27

**Status**: Draft

**Input**: User description: "Projeto de bolão da copa do mundo de 2026. Backend Laravel + app Flutter. Ter todos os jogos (datas, jogos, bandeiras). Usuário participa, marca placar e pontua: placar exato 2, resultado 1, erro 0. Usuários precisam login."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Entrar e participar do bolão (Priority: P1)

Como participante, quero criar conta e entrar no app para participar do bolão e registrar meus palpites.

**Why this priority**: Sem login não existe participação, pontuação nem ranking por usuário.

**Independent Test**: Criar um usuário, fazer login, receber sessão/token e acessar uma rota autenticada (ex.: meu perfil/participações).

**Acceptance Scenarios**:

1. **Given** que não estou autenticado, **When** eu faço cadastro com credenciais válidas, **Then** minha conta é criada e consigo autenticar.
2. **Given** que estou autenticado, **When** eu abro o app, **Then** vejo meu estado (ex.: nome, bolões que participo) sem pedir login novamente (enquanto a sessão for válida).

---

### User Story 2 - Ver jogos e registrar palpites (Priority: P1)

Como participante, quero ver a lista de jogos da Copa 2026 e registrar um palpite de placar por jogo.

**Why this priority**: É a funcionalidade central do produto (o “bolão”).

**Independent Test**: Com o banco populado com jogos, autenticar e enviar palpite para um jogo, depois ler o palpite salvo.

**Acceptance Scenarios**:

1. **Given** que existem jogos importados, **When** eu acesso a lista de jogos, **Then** eu vejo data/hora, times e bandeiras.
2. **Given** que um jogo ainda não começou, **When** eu envio meu palpite (ex.: 2x1), **Then** o sistema salva/atualiza meu palpite para aquele jogo.

---

### User Story 3 - Ver pontuação e ranking (Priority: P1)

Como participante, quero ver minha pontuação e o ranking geral para acompanhar meu desempenho.

**Why this priority**: Recompensa e engajamento dependem do ranking e do histórico de pontos.

**Independent Test**: Com resultados oficiais cadastrados para jogos, rodar cálculo de pontuação e consultar ranking.

**Acceptance Scenarios**:

1. **Given** que existem resultados oficiais para alguns jogos, **When** eu acesso meu histórico, **Then** vejo os pontos por jogo e o total.
2. **Given** que existem múltiplos participantes com palpites, **When** eu acesso o ranking geral, **Then** vejo os usuários ordenados por pontuação (com critério de desempate a definir).

---

### Edge Cases

- Palpite enviado para um jogo que já começou (ou após deadline): deve ser bloqueado.
- Jogo adiado/alterado: o sistema deve refletir a nova data/hora sem perder o palpite.
- Placar inválido (negativo, não inteiro): deve ser rejeitado.
- Empate: “resultado correto” conta 1 ponto quando o usuário acertar empate (mesmo sem acertar o placar).
- Desempate no ranking: **NEEDS CLARIFICATION** (ex.: mais acertos de placar, mais acertos de resultado, data do palpite, etc.).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sistema MUST permitir cadastro e login de usuários.
- **FR-002**: Sistema MUST manter uma lista completa de jogos da Copa 2026 (data/hora, times, fase/grupo quando aplicável).
- **FR-003**: Sistema MUST armazenar a identidade dos times e seus assets de bandeira (ou links/ids para bandeiras).
- **FR-004**: Usuários MUST conseguir registrar/editar palpite de placar por jogo antes do início do jogo (deadline).
- **FR-005**: Sistema MUST armazenar o resultado oficial do jogo (placar final) quando disponível.
- **FR-006**: Sistema MUST calcular pontuação por palpite com as regras:
  - placar exato: 2
  - resultado (vencedor/empate) correto: 1
  - erro: 0
- **FR-007**: Sistema MUST expor ranking geral por pontuação.
- **FR-008**: Sistema MUST expor “meu histórico” com pontos por jogo e total.

### Key Entities *(include if feature involves data)*

- **User**: participante autenticado.
- **Team**: seleção (nome, código, bandeira).
- **Match**: jogo (times, data/hora, fase/grupo, status).
- **Prediction**: palpite (user, match, placar previsto).
- **MatchResult**: resultado oficial (match, placar final).
- **Score**: pontos computados por prediction (derivado, mas pode ser materializado).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário consegue criar conta e fazer login com sucesso.
- **SC-002**: Um usuário consegue registrar palpite para um jogo futuro e ver o palpite salvo.
- **SC-003**: Após inserir resultados oficiais, o sistema calcula pontos consistentes com as regras em 100% dos casos de teste.
- **SC-004**: Ranking geral ordena corretamente os participantes por pontuação.

## Assumptions

- Os dados da Copa 2026 (jogos/times/bandeiras) virão de uma fonte externa (API/dataset) e serão importados para o backend.
- O backend será uma API consumida pelo app Flutter.
- Regras de deadline: padrão será “até o início do jogo” (pode ser ajustado depois).
