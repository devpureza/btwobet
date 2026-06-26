import 'package:flutter/material.dart';

import '../../ui/avatar_image.dart';
import '../../ui/flag_image.dart';
import '../../ui/glass.dart';
import '../matches/match_predictions_sheet.dart' show PredictionPointsBadge;
import 'ranking_repository.dart';

void showRankingUserDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> row,
  required RankingRepository ranking,
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
  final userId = (row['user_id'] as num).toInt();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final tabViewHeight = MediaQuery.sizeOf(ctx).height * 0.5;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.paddingOf(ctx).bottom),
        child: DefaultTabController(
          length: 2,
          child: Glass(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────
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
                const SizedBox(height: 20),

                // ── Tabs ─────────────────────────────────────────────────
                TabBar(
                  tabs: const [
                    Tab(text: 'Estatísticas'),
                    Tab(text: 'Últimos palpites'),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Tab views ────────────────────────────────────────────
                SizedBox(
                  height: tabViewHeight,
                  child: TabBarView(
                    children: [
                      // Tab 1: Estatísticas
                      SingleChildScrollView(
                        child: Column(
                          children: [
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
                          ],
                        ),
                      ),

                      // Tab 2: Últimos palpites
                      _UserPredictionsTab(
                        userId: userId,
                        ranking: ranking,
                      ),
                    ],
                  ),
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
    },
  );
}

// ── Predictions tab ──────────────────────────────────────────────────────────

class _UserPredictionsTab extends StatefulWidget {
  final int userId;
  final RankingRepository ranking;

  const _UserPredictionsTab({required this.userId, required this.ranking});

  @override
  State<_UserPredictionsTab> createState() => _UserPredictionsTabState();
}

class _UserPredictionsTabState extends State<_UserPredictionsTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _predictions = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await widget.ranking.getUserPredictions(widget.userId);
      if (mounted) setState(() { _predictions = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Não foi possível carregar os palpites.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, textAlign: TextAlign.center),
      );
    }

    if (_predictions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum palpite em jogo finalizado ainda.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _predictions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = _predictions[index] as Map<String, dynamic>;
        final home = p['home_team'] as Map<String, dynamic>;
        final away = p['away_team'] as Map<String, dynamic>;
        final pred = p['prediction'] as Map<String, dynamic>;
        final result = p['result'] as Map<String, dynamic>;
        final points = (p['points'] as num?)?.toInt() ?? 0;

        final homeName = home['name'] as String? ?? '—';
        final awayName = away['name'] as String? ?? '—';
        final homeFlagUrl = home['flag_url'] as String?;
        final awayFlagUrl = away['flag_url'] as String?;
        final predH = (pred['home_score'] as num?)?.toInt() ?? 0;
        final predA = (pred['away_score'] as num?)?.toInt() ?? 0;
        final resH = (result['home_score'] as num?)?.toInt() ?? 0;
        final resA = (result['away_score'] as num?)?.toInt() ?? 0;

        final scheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teams row
              Row(
                children: [
                  FlagImage(url: homeFlagUrl, size: 28),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      homeName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'vs',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Text(
                      awayName,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FlagImage(url: awayFlagUrl, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              // Scores + badge row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Palpite: $predH × $predA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Resultado: $resH × $resA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PredictionPointsBadge(points: points),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat tile ────────────────────────────────────────────────────────────────

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
