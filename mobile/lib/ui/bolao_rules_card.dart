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

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
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
                  Icon(Icons.rule_folder_outlined, color: scheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regras do bolão',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(theme, 'Pontuação'),
                  _bullet(theme, 'Placar exato: 2 pontos'),
                  _bullet(theme, 'Resultado certo (vitória ou empate, sem placar exato): 1 ponto'),
                  _bullet(theme, 'Errou o resultado: 0 pontos'),
                  const SizedBox(height: 12),
                  _sectionTitle(theme, 'Palpites'),
                  _bullet(
                    theme,
                    'Um palpite por jogo. Depois de salvar, não dá para alterar nem refazer.',
                  ),
                  _bullet(theme, 'Fase de grupos: envie até o prazo da fase (mostrado em cada jogo).'),
                  _bullet(theme, 'Mata-mata: palpites fecham 24 horas antes do horário do jogo.'),
                  const SizedBox(height: 12),
                  _sectionTitle(theme, 'Ranking'),
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
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
          ),
        ],
      ),
    );
  }
}
