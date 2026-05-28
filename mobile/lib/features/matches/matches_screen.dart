import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/bolao_fund_card.dart';
import '../../ui/bolao_rules_card.dart';
import '../../ui/flag_image.dart';
import '../../ui/glass.dart';
import '../../ui/match_filters.dart';
import '../../ui/score_sync_banner.dart';
import '../../ui/shell_header.dart';

class MatchesScreen extends StatefulWidget {
  final SessionController session;

  const MatchesScreen({super.key, required this.session});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _matches = [];
  Map<String, dynamic>? _fund;
  String? _group;
  String? _stage;
  bool _onlyOpen = false;

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
      final results = await Future.wait([
        widget.session.matches.listMatches(),
        widget.session.bolaoFund.getFund(),
      ]);
      setState(() {
        _matches = results[0] as List<dynamic>;
        _fund = (results[1] as Map).cast<String, dynamic>();
      });
    } catch (e) {
      setState(() => _error = 'Falha ao carregar jogos.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<dynamic> filtered) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final raw in filtered) {
      final m = raw as Map<String, dynamic>;
      final kickoff = DateTime.parse(m['kickoff_at'] as String).toLocal();
      final key = DateFormat('yyyy-MM-dd').format(kickoff);
      map.putIfAbsent(key, () => []).add(m);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _applyFilters(_matches);
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList()..sort();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return ShellPage(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: SizedBox(
                                height: isDesktop ? 240 : 200,
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
                                              'Seus Palpites',
                                              style: theme.textTheme.headlineLarge?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Preveja os placares e suba no ranking global.',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.90),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_fund != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1280),
                                child: BolaoFundCard(
                                  participantCount: (_fund!['participant_count'] as num?)?.toInt() ?? 0,
                                  amountPerParticipantBrl:
                                      (_fund!['amount_per_participant_brl'] as num?)?.toInt() ?? 50,
                                  totalAmountBrl: (_fund!['total_amount_brl'] as num?)?.toInt() ?? 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: const BolaoRulesCard(),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: Glass(
                                blur: 12,
                                borderRadius: BorderRadius.circular(20),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: ScoreSyncBanner(repository: widget.session.scoreSync),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: Glass(
                                blur: 12,
                                borderRadius: BorderRadius.circular(20),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: MatchFilters(
                                  group: _group,
                                  stage: _stage,
                                  onlyOpen: _onlyOpen,
                                  onGroupChanged: (v) => setState(() => _group = v),
                                  onStageChanged: (v) => setState(() => _stage = v),
                                  onOnlyOpenChanged: (v) => setState(() => _onlyOpen = v),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('Nenhum jogo encontrado com esses filtros.')),
                        )
                      else
                        for (final dateKey in dateKeys) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1280),
                                  child: _DateHeader(
                                    label: DateFormat('EEEE, dd MMMM', 'pt_BR').format(
                                      DateTime.parse('${dateKey}T12:00:00'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            sliver: isDesktop
                                ? SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 620,
                                      mainAxisExtent: 280,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final m = grouped[dateKey]![index];
                                        return MatchCard(
                                          key: ValueKey(m['id']),
                                          match: m,
                                          onSave: (home, away) async {
                                            try {
                                              await widget.session.matches.upsertPrediction(
                                                matchId: m['id'] as int,
                                                homeScore: home,
                                                awayScore: away,
                                              );
                                              await _load();
                                              if (context.mounted) {
                                                showSnack(context, 'Palpite salvo. Não será possível alterar.');
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                showSnack(context, dioErrorMessage(e), error: true);
                                              }
                                              rethrow;
                                            }
                                          },
                                        );
                                      },
                                      childCount: grouped[dateKey]!.length,
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final m = grouped[dateKey]![index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: MatchCard(
                                            key: ValueKey(m['id']),
                                            match: m,
                                            onSave: (home, away) async {
                                              try {
                                                await widget.session.matches.upsertPrediction(
                                                  matchId: m['id'] as int,
                                                  homeScore: home,
                                                  awayScore: away,
                                                );
                                                await _load();
                                                if (context.mounted) {
                                                  showSnack(context, 'Palpite salvo. Não será possível alterar.');
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  showSnack(context, dioErrorMessage(e), error: true);
                                                }
                                                rethrow;
                                              }
                                            },
                                          ),
                                        );
                                      },
                                      childCount: grouped[dateKey]!.length,
                                    ),
                                  ),
                          ),
                        ],
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> raw) {
    final items = raw.whereType<Map<String, dynamic>>().toList();

    bool match(Map<String, dynamic> m) {
      if (_group != null && _group!.isNotEmpty) {
        final g = (m['group_name'] as String?)?.toUpperCase();
        if (g != _group) return false;
      }
      if (_stage != null && _stage!.isNotEmpty) {
        final s = (m['stage'] as String?) ?? '';
        if (s != _stage) return false;
      }
      if (_onlyOpen) {
        final open = (m['open_for_predictions'] as bool?) ?? false;
        if (!open) return false;
      }
      return true;
    }

    return items.where(match).toList();
  }
}

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final formatted = label[0].toUpperCase() + label.substring(1);

    return Row(
      children: [
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            formatted,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
      ],
    );
  }
}

class MatchCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final Future<void> Function(int homeScore, int awayScore) onSave;

  const MatchCard({super.key, required this.match, required this.onSave});

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late final TextEditingController _home;
  late final TextEditingController _away;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final my = widget.match['my_prediction'] as Map<String, dynamic>?;
    _home = TextEditingController(text: (my?['home_score']?.toString() ?? ''));
    _away = TextEditingController(text: (my?['away_score']?.toString() ?? ''));
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final my = widget.match['my_prediction'] as Map<String, dynamic>?;
    _home.text = my?['home_score']?.toString() ?? '';
    _away.text = my?['away_score']?.toString() ?? '';
  }

  @override
  void dispose() {
    _home.dispose();
    _away.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final homeTeam = widget.match['home_team'] as Map<String, dynamic>;
    final awayTeam = widget.match['away_team'] as Map<String, dynamic>;

    final kickoff = DateTime.parse(widget.match['kickoff_at'] as String).toLocal();
    final open = widget.match['open_for_predictions'] as bool? ?? false;
    final lockReason = widget.match['prediction_lock_reason'] as String?;
    final deadlineRaw = widget.match['prediction_deadline_at'] as String?;
    final deadline = deadlineRaw != null ? DateTime.tryParse(deadlineRaw)?.toLocal() : null;
    final hasPrediction = widget.match['my_prediction'] != null;

    final result = widget.match['result'] as Map<String, dynamic>?;
    final liveScore = widget.match['live_score'] as Map<String, dynamic>?;
    final venue = widget.match['venue'] as String?;
    final group = widget.match['group_name'] as String?;

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.65),
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.20)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    venue ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (group != null && group.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.primaryContainer.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Grupo $group',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm', 'pt_BR').format(kickoff),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _team(homeTeam, alignRight: true)),
                    const SizedBox(width: 10),
                    ScoreBox(controller: _home, enabled: open),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('X', style: theme.textTheme.headlineMedium?.copyWith(color: scheme.outline)),
                    ),
                    ScoreBox(controller: _away, enabled: open),
                    const SizedBox(width: 10),
                    Expanded(child: _team(awayTeam)),
                  ],
                ),
                const SizedBox(height: 12),
                if (deadline != null && open)
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(deadline)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
                  ),
                if (lockReason != null && !open) ...[
                  const SizedBox(height: 8),
                  Text(
                    lockReason,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                if (hasPrediction && !open && lockReason == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Palpite registrado.',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                if (result != null) ...[
                  Text(
                    'Resultado: ${result['home_score']} x ${result['away_score']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                ] else if (liveScore != null) ...[
                  Text(
                    'Ao vivo: ${liveScore['home_score']} x ${liveScore['away_score']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: (!open || _saving)
                        ? null
                        : () async {
                            final hs = int.tryParse(_home.text) ?? 0;
                            final as = int.tryParse(_away.text) ?? 0;
                            setState(() => _saving = true);
                            try {
                              await widget.onSave(hs, as);
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(hasPrediction ? 'Registrado' : (open ? 'Salvar palpite' : 'Fechado')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _team(Map<String, dynamic> team, {bool alignRight = false}) {
    final theme = Theme.of(context);
    final name = (team['name'] as String).toUpperCase();
    final flag = FlagImage(url: team['flag_url'] as String?, size: 48);
    final label = Flexible(
      child: Text(
        name,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight
          ? [label, const SizedBox(width: 8), flag]
          : [flag, const SizedBox(width: 8), label],
    );
  }
}
