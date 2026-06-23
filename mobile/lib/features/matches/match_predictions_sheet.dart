import 'package:flutter/material.dart';

import '../../ui/glass.dart';
import '../../ui/user_avatar.dart';
import 'matches_repository.dart';

Future<void> showMatchPredictionsSheet(
  BuildContext context, {
  required MatchesRepository matches,
  required int matchId,
  required String homeTeamName,
  required String awayTeamName,
  required bool isFinished,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MatchPredictionsSheet(
      matches: matches,
      matchId: matchId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      isFinished: isFinished,
    ),
  );
}

class _OutcomeTotals {
  final int homeWins;
  final int draws;
  final int awayWins;

  const _OutcomeTotals({
    required this.homeWins,
    required this.draws,
    required this.awayWins,
  });

  int get total => homeWins + draws + awayWins;

  static _OutcomeTotals fromPredictions(List<Map<String, dynamic>> items) {
    var homeWins = 0;
    var draws = 0;
    var awayWins = 0;

    for (final row in items) {
      final home = row['home_score'] as num?;
      final away = row['away_score'] as num?;
      if (home == null || away == null) continue;

      if (home > away) {
        homeWins++;
      } else if (home == away) {
        draws++;
      } else {
        awayWins++;
      }
    }

    return _OutcomeTotals(homeWins: homeWins, draws: draws, awayWins: awayWins);
  }
}

class _MatchPredictionsSheet extends StatefulWidget {
  final MatchesRepository matches;
  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final bool isFinished;

  const _MatchPredictionsSheet({
    required this.matches,
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.isFinished,
  });

  @override
  State<_MatchPredictionsSheet> createState() => _MatchPredictionsSheetState();
}

class _MatchPredictionsSheetState extends State<_MatchPredictionsSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.matches.listMatchPredictions(widget.matchId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os palpites.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Glass(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Palpites do jogo',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.homeTeamName} × ${widget.awayTeamName}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(theme, scheme, scrollController)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme scheme, ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Ninguém registrou palpite para este jogo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final totals = _OutcomeTotals.fromPredictions(_items);

    return ListView(
      controller: scrollController,
      children: [
        _PredictionsTotalizer(
          theme: theme,
          scheme: scheme,
          totals: totals,
          homeTeamName: widget.homeTeamName,
          awayTeamName: widget.awayTeamName,
        ),
        const SizedBox(height: 16),
        Text(
          '${totals.total} palpite${totals.total == 1 ? '' : 's'}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _PredictionRow(
            theme: theme,
            scheme: scheme,
            row: _items[i],
            showPoints: widget.isFinished,
          ),
        ],
      ],
    );
  }
}

class _PredictionsTotalizer extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final _OutcomeTotals totals;
  final String homeTeamName;
  final String awayTeamName;

  const _PredictionsTotalizer({
    required this.theme,
    required this.scheme,
    required this.totals,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final total = totals.total;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribuição dos palpites',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _OutcomeBar(
            theme: theme,
            scheme: scheme,
            label: homeTeamName,
            count: totals.homeWins,
            total: total,
            color: scheme.primary,
          ),
          const SizedBox(height: 8),
          _OutcomeBar(
            theme: theme,
            scheme: scheme,
            label: 'Empate',
            count: totals.draws,
            total: total,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 8),
          _OutcomeBar(
            theme: theme,
            scheme: scheme,
            label: awayTeamName,
            count: totals.awayWins,
            total: total,
            color: scheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _OutcomeBar extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final String label;
  final int count;
  final int total;
  final Color color;

  const _OutcomeBar({
    required this.theme,
    required this.scheme,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    final percent = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$count · $percent%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme scheme;
  final Map<String, dynamic> row;
  final bool showPoints;

  const _PredictionRow({
    required this.theme,
    required this.scheme,
    required this.row,
    required this.showPoints,
  });

  @override
  Widget build(BuildContext context) {
    final user = (row['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = user['name'] as String? ?? '—';
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
    final homeScore = row['home_score'] as num?;
    final awayScore = row['away_score'] as num?;
    final points = row['points'] as num?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          UserAvatar(
            url: user['avatar_url'] as String?,
            size: 40,
            fallbackLetter: initial,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${homeScore ?? '—'} × ${awayScore ?? '—'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (showPoints && points != null) ...[
            const SizedBox(width: 8),
            PredictionPointsBadge(points: points.toInt()),
          ],
        ],
      ),
    );
  }
}

class PredictionPointsBadge extends StatelessWidget {
  final int points;

  const PredictionPointsBadge({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color background;
    final Color foreground;

    switch (points) {
      case 2:
        background = const Color(0xFF2E7D32).withValues(alpha: 0.14);
        foreground = const Color(0xFF1B5E20);
      case 1:
        background = const Color(0xFFF9A825).withValues(alpha: 0.20);
        foreground = const Color(0xFFE65100);
      default:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Text(
        '+$points',
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
