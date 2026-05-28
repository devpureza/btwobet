import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/avatar_image.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class RankingScreen extends StatefulWidget {
  final SessionController session;

  const RankingScreen({super.key, required this.session});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _ranking = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> row) {
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarImage(
                url: avatarUrl,
                size: 96,
                fallbackLetter: initial,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '#$pos no ranking • $totalPoints pts',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _StatTile(
                label: 'Palpites',
                value: '$totalPredictions',
                subtitle: scoredPredictions > 0
                    ? '$scoredPredictions já avaliados'
                    : 'Nenhum jogo finalizado ainda',
              ),
              const SizedBox(height: 10),
              _StatTile(
                label: 'Placar exato',
                value: '$exactPercent%',
                subtitle: '$exactHits de $scoredPredictions jogos avaliados',
              ),
              const SizedBox(height: 10),
              _StatTile(
                label: 'Resultado (V/E/D)',
                value: '$resultPercent%',
                subtitle: '$resultHits de $scoredPredictions jogos avaliados',
              ),
              const SizedBox(height: 20),
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.session.ranking.getRanking();
      setState(() => _ranking = data);
    } catch (e) {
      setState(() => _error = 'Falha ao carregar ranking.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ShellPage(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: StadiumGradient(
                          assetPath: 'assets/images/hero-stadium.png',
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ranking',
                                    style: theme.textTheme.headlineLarge?.copyWith(color: scheme.onPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Top 3 com destaque, linhas zebra e pontuação total.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onPrimary.withValues(alpha: 0.90),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Glass(
                      blur: 12,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: List.generate(_ranking.length, (index) {
                          final row = _ranking[index] as Map<String, dynamic>;
                          final pos = (row['position'] as num).toInt();
                          final name = row['name'] as String? ?? '—';
                          final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
                          final avatarUrl = row['avatar_url'] as String?;

                          Color? accent;
                          if (pos == 1) accent = const Color(0xFFFCD400); // gold
                          if (pos == 2) accent = scheme.surfaceContainerHigh;
                          if (pos == 3) accent = const Color(0xFFCD7F32); // bronze-ish

                          final zebra = index.isOdd ? scheme.primary.withValues(alpha: 0.04) : Colors.transparent;

                          return InkWell(
                            onTap: () => _showUserDetail(context, row),
                            child: Container(
                            decoration: BoxDecoration(
                              color: zebra,
                              border: Border(
                                bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.18)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AvatarImage(
                                      url: avatarUrl,
                                      size: 44,
                                      fallbackLetter: initial,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accent ?? scheme.primary,
                                          border: Border.all(color: scheme.surface, width: 2),
                                        ),
                                        child: Text(
                                          '$pos',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onPrimary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Exatos: ${row['exact_hits']} • Resultado: ${row['result_hits']}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${row['total_points']} pts',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _StatTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
