import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/achievement_tier_style.dart';
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

  Future<void> _submitPrediction(BuildContext context, int matchId, int home, int away) async {
    try {
      final unlocked = await widget.session.matches.upsertPrediction(
        matchId: matchId,
        homeScore: home,
        awayScore: away,
      );
      await _load();
      if (!context.mounted) return;
      showSnack(context, 'Palpite salvo. Não será possível alterar.');
      widget.session.presentUnlockedAchievements(unlocked);
    } catch (e) {
      if (context.mounted) {
        showSnack(context, dioErrorMessage(e), error: true);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _applyFilters(_matches);
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList()..sort();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return ShellPage(
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final unreadUnlocks = widget.session.unreadRecentUnlocks;

          return _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      if (unreadUnlocks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1280),
                                child: _RecentUnlocksBanner(
                                  session: widget.session,
                                  unlocks: unreadUnlocks,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, unreadUnlocks.isEmpty ? 16 : 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: SizedBox(
                                height: isDesktop ? 168 : 128,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: StadiumGradient(
                                    assetPath: 'assets/images/hero-stadium.png',
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Seus Palpites',
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Preveja os placares e suba no ranking global.',
                                              style: theme.textTheme.bodySmall?.copyWith(
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
                              child: const BolaoRulesCard(),
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
                                      mainAxisExtent: 296,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final m = grouped[dateKey]![index];
                                        return MatchCard(
                                          key: ValueKey(m['id']),
                                          match: m,
                                          onSave: (home, away) => _submitPrediction(
                                            context,
                                            m['id'] as int,
                                            home,
                                            away,
                                          ),
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
                                            onSave: (home, away) => _submitPrediction(
                                              context,
                                              m['id'] as int,
                                              home,
                                              away,
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: grouped[dateKey]!.length,
                                    ),
                                  ),
                          ),
                        ],
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
                      ),
                    ],
                  ),
                );
        },
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

class _RecentUnlocksBanner extends StatelessWidget {
  final SessionController session;
  final List<Map<String, dynamic>> unlocks;

  const _RecentUnlocksBanner({
    required this.session,
    required this.unlocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = unlocks.first;
    final name = latest['name'] as String? ?? 'Conquista';
    final tier = latest['tier'] as String? ?? 'bronze';
    final tierColor = achievementTierColor(tier, scheme);
    final extra = unlocks.length - 1;

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(16),
      border: BorderSide(color: tierColor.withValues(alpha: 0.45)),
      child: Row(
        children: [
          Icon(
            achievementTierIcon(tier, unlocked: true),
            color: tierColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você conquistou: $name',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (extra > 0)
                  Text(
                    extra == 1 ? '+1 conquista recente' : '+$extra conquistas recentes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => session.dismissRecentUnlockBanner(),
            icon: Icon(Icons.close, color: scheme.outline, size: 20),
          ),
        ],
      ),
    );
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
  static const double _flagSize = 56;
  static const double _scoreSize = 56;

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
    final teamsDefined = widget.match['teams_defined'] as bool? ?? true;
    final open = widget.match['open_for_predictions'] as bool? ?? false;
    final lockReason = widget.match['prediction_lock_reason'] as String?;
    final awaitingTeams = !teamsDefined;
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _teamName(homeTeam, alignRight: true),
                    ),
                    const SizedBox(width: 6),
                    _teamFlag(homeTeam),
                    const SizedBox(width: 6),
                    _scoreInputs(
                      theme: theme,
                      scheme: scheme,
                      homeEnabled: open && !awaitingTeams,
                      awayEnabled: open && !awaitingTeams,
                    ),
                    const SizedBox(width: 6),
                    _teamFlag(awayTeam),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _teamName(awayTeam),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (deadline != null && open)
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(deadline)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
                  ),
                if (awaitingTeams) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Aguardando definição dos times',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else if (lockReason != null && !open) ...[
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
                    onPressed: (!open || awaitingTeams || _saving)
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
                        : Text(
                            awaitingTeams
                                ? 'Times pendentes'
                                : (hasPrediction ? 'Registrado' : (open ? 'Salvar palpite' : 'Fechado')),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreInputs({
    required ThemeData theme,
    required ColorScheme scheme,
    required bool homeEnabled,
    required bool awayEnabled,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScoreBox(
          controller: _home,
          enabled: homeEnabled,
          size: _scoreSize,
        ),
        SizedBox(
          width: 24,
          height: _scoreSize,
          child: Center(
            child: Text(
              '×',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.outline,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
        ScoreBox(
          controller: _away,
          enabled: awayEnabled,
          size: _scoreSize,
        ),
      ],
    );
  }

  Widget _teamName(Map<String, dynamic> team, {bool alignRight = false}) {
    final theme = Theme.of(context);
    final isPlaceholder = team['is_placeholder'] as bool? ?? false;
    final name = isPlaceholder ? 'A definir' : (team['name'] as String).toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 88;
        return Text(
          name,
          maxLines: wide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: (wide ? theme.textTheme.titleSmall : theme.textTheme.labelLarge)?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0.2,
          ),
        );
      },
    );
  }

  Widget _teamFlag(Map<String, dynamic> team) {
    final isPlaceholder = team['is_placeholder'] as bool? ?? false;
    if (isPlaceholder) {
      return SizedBox(width: _flagSize, height: _flagSize);
    }
    return FlagImage(url: team['flag_url'] as String?, size: _flagSize);
  }
}
