import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/avatar_image.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';
import 'ranking_user_detail_sheet.dart';

class RankingScreen extends StatefulWidget {
  final SessionController session;

  const RankingScreen({super.key, required this.session});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 60);

  bool _loading = true;
  bool _silentRefreshing = false;
  String? _error;
  List<dynamic> _ranking = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_syncPolling);
    _load();
    _bootstrapPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_syncPolling);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.session.hasLiveMatches) {
      _load(silent: true);
    }
  }

  Future<void> _bootstrapPolling() async {
    await widget.session.ensureLiveMatchPresence();
    if (mounted) _syncPolling();
  }

  void _syncPolling() {
    if (!widget.session.hasLiveMatches) {
      _stopPolling();
      return;
    }
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _silentRefreshing = true);
    }

    try {
      final data = await widget.session.ranking.getRanking();
      if (mounted) setState(() => _ranking = data);
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _error = 'Falha ao carregar ranking.');
      }
    } finally {
      if (mounted) {
        setState(() {
          if (!silent) _loading = false;
          _silentRefreshing = false;
        });
      }
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
                    if (_silentRefreshing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Atualizando...',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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

                          const avatarSize = 68.0;
                          const badgeSize = 26.0;

                          return InkWell(
                            onTap: () => showRankingUserDetailSheet(context, row: row, ranking: widget.session.ranking),
                            child: Container(
                            decoration: BoxDecoration(
                              color: zebra,
                              border: Border(
                                bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.18)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AvatarImage(
                                      url: avatarUrl,
                                      size: avatarSize,
                                      fallbackLetter: initial,
                                    ),
                                    Positioned(
                                      right: -3,
                                      bottom: -3,
                                      child: Container(
                                        width: badgeSize,
                                        height: badgeSize,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accent ?? scheme.primary,
                                          border: Border.all(color: scheme.surface, width: 2.5),
                                        ),
                                        child: Text(
                                          '$pos',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onPrimary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
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
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                          color: scheme.onSurfaceVariant,
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
