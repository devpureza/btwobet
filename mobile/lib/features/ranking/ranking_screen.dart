import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
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

                          Color? accent;
                          if (pos == 1) accent = const Color(0xFFFCD400); // gold
                          if (pos == 2) accent = scheme.surfaceContainerHigh;
                          if (pos == 3) accent = const Color(0xFFCD7F32); // bronze-ish

                          final zebra = index.isOdd ? scheme.primary.withValues(alpha: 0.04) : Colors.transparent;

                          return Container(
                            decoration: BoxDecoration(
                              color: zebra,
                              border: Border(
                                bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.18)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (accent ?? scheme.secondary).withValues(alpha: 0.95),
                                  ),
                                  child: Text(
                                    '$pos',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row['name'] as String,
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
