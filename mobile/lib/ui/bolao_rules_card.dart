import 'package:flutter/material.dart';

import 'glass.dart';

/// Regras fixas alinhadas ao backend (`ScoreCalculator`, `PredictionWindow`).
class BolaoRulesCard extends StatefulWidget {
  const BolaoRulesCard({super.key});

  @override
  State<BolaoRulesCard> createState() => _BolaoRulesCardState();
}

class _BolaoRulesCardState extends State<BolaoRulesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.error;

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.rule_folder_outlined, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Regras do bolão',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: accent.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: accent.withValues(alpha: 0.35)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(theme, accent, 'Pontuação'),
                    _bullet(theme, 'Placar exato: 2 pontos'),
                    _bullet(theme, 'Resultado certo (vitória ou empate, sem placar exato): 1 ponto'),
                    _bullet(theme, 'Errou o resultado: 0 pontos'),
                    const SizedBox(height: 12),
                    _sectionTitle(theme, accent, 'Palpites'),
                    _bullet(
                      theme,
                      'Um palpite por jogo. Depois de salvar, não dá para alterar nem refazer.',
                      emphasize: true,
                    ),
                    _bullet(theme, 'Fase de grupos: envie até o prazo da fase (mostrado em cada jogo).'),
                    _bullet(theme, 'Mata-mata: palpites fecham 24 horas antes do horário do jogo.'),
                    const SizedBox(height: 12),
                    _sectionTitle(theme, accent, 'Ranking'),
                    _bullet(
                      theme,
                      'Desempate: total de pontos → placares exatos → acertos de resultado → '
                      'quem entrou antes no bolão.',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, Color accent, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: emphasize ? theme.colorScheme.error : null,
              fontWeight: emphasize ? FontWeight.w700 : null,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: emphasize ? theme.colorScheme.error : null,
                fontWeight: emphasize ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel lateral (endDrawer) com as regras do bolão, aberto pelo ícone no header.
class BolaoRulesDrawer extends StatelessWidget {
  const BolaoRulesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.error;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.rule_folder_outlined, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regras do bolão',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: accent.withValues(alpha: 0.35)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _section(theme, accent, 'Pontuação'),
                  _bullet(theme, 'Placar exato: 2 pontos'),
                  _bullet(theme, 'Resultado certo (vitória ou empate, sem placar exato): 1 ponto'),
                  _bullet(theme, 'Errou o resultado: 0 pontos'),
                  const SizedBox(height: 16),
                  _section(theme, accent, 'Palpites'),
                  _bullet(theme,
                      'Um palpite por jogo. Depois de salvar, não dá para alterar nem refazer.',
                      emphasize: true),
                  _bullet(theme, 'Fase de grupos: envie até o prazo da fase (mostrado em cada jogo).'),
                  _bullet(theme, 'Mata-mata: palpites fecham 24 horas antes do horário do jogo.'),
                  const SizedBox(height: 16),
                  _section(theme, accent, 'Ranking'),
                  _bullet(theme,
                      'Desempate: total de pontos → placares exatos → acertos de resultado → '
                      'quem entrou antes no bolão.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, Color accent, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: emphasize ? theme.colorScheme.error : null,
                fontWeight: emphasize ? FontWeight.w700 : null,
              )),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: emphasize ? theme.colorScheme.error : null,
                  fontWeight: emphasize ? FontWeight.w600 : null,
                )),
          ),
        ],
      ),
    );
  }
}
