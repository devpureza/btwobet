import 'package:flutter/material.dart';

import '../../ui/avatar_image.dart';
import '../../ui/glass.dart';

void showRankingUserDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> row,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final pos = (row['position'] as num).toInt();
  final name = row['name'] as String? ?? '—';
  final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
  final avatarUrl = row['avatar_url'] as String?;
  final totalPoints = (row['total_points'] as num?)?.toInt() ?? 0;
  final totalPredictions = (row['total_predictions'] as num?)?.toInt() ?? 0;
  final scoredPredictions = (row['scored_predictions'] as num?)?.toInt() ?? 0;
  final exactHits = (row['exact_hits'] as num?)?.toInt() ?? 0;
  final resultHits = (row['result_hits'] as num?)?.toInt() ?? 0;
  final exactPercent = (row['exact_hit_percent'] as num?)?.toInt() ?? 0;
  final resultPercent = (row['result_hit_percent'] as num?)?.toInt() ?? 0;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.paddingOf(ctx).bottom),
      child: Glass(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(
              url: avatarUrl,
              size: 132,
              fallbackLetter: initial,
            ),
            const SizedBox(height: 18),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '#$pos no ranking • $totalPoints pts',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            RankingStatTile(
              icon: Icons.sports_soccer_outlined,
              label: 'Palpites',
              value: '$totalPredictions',
              subtitle: scoredPredictions > 0
                  ? '$scoredPredictions já avaliados'
                  : 'Nenhum jogo finalizado ainda',
            ),
            const SizedBox(height: 12),
            RankingStatTile(
              icon: Icons.emoji_events_outlined,
              label: 'Placar exato',
              value: '$exactPercent%',
              subtitle: '$exactHits de $scoredPredictions jogos avaliados',
            ),
            const SizedBox(height: 12),
            RankingStatTile(
              icon: Icons.trending_up_rounded,
              label: 'Resultado (V/E/D)',
              value: '$resultPercent%',
              subtitle: '$resultHits de $scoredPredictions jogos avaliados',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class RankingStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const RankingStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: scheme.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
