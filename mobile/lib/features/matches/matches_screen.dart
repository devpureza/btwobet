import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import 'match_live.dart';
import 'match_predictions_sheet.dart';
import 'matches_repository.dart';
import '../../ui/achievement_tier_style.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/bolao_fund_card.dart';
import '../../ui/flag_image.dart';
import '../../ui/glass.dart';
import 'hall_entry.dart';
import '../../ui/hall_highlights_row.dart';
import '../../ui/match_filters.dart';
import '../../ui/score_sync_banner.dart';
import '../../ui/shell_header.dart';

class MatchesScreen extends StatefulWidget {
  final SessionController session;

  const MatchesScreen({super.key, required this.session});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 60);

  bool _loading = true;
  bool _silentRefreshing = false;
  String? _error;
  List<dynamic> _matches = [];
  Map<String, dynamic>? _fund;
  HallOfWeekData _hall = HallOfWeekData.empty;
  String? _group;
  String? _stage;
  bool _onlyOpen = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && hasLiveMatchesInList(_matches)) {
      _load(silent: true);
    }
  }

  void _syncPolling() {
    if (!hasLiveMatchesInList(_matches)) {
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
      final results = await Future.wait([
        widget.session.matches.listMatches(),
        widget.session.bolaoFund.getFund(),
        widget.session.hall.getHallOfWeek(),
      ]);
      if (!mounted) return;
      setState(() {
        _matches = results[0] as List<dynamic>;
        _fund = (results[1] as Map).cast<String, dynamic>();
        _hall = results[2] as HallOfWeekData;
      });
      widget.session.setLiveMatchPresence(_matches);
      _syncPolling();
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _error = 'Falha ao carregar jogos.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _silentRefreshing = false;
        });
      }
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
    final groupPhaseClosed = _isGroupPhasePredictionsClosed(_matches);

    return ShellPage(
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final unreadUnlocks = widget.session.unreadRecentUnlocks;
          final now = DateTime.now();
          bool isToday(Map<String, dynamic> m) {
            final k = DateTime.parse(m['kickoff_at'] as String).toLocal();
            return k.year == now.year && k.month == now.month && k.day == now.day;
          }
          // Jogos de hoje: ao vivo primeiro, depois por horário.
          final todayGames = _matches
              .whereType<Map<String, dynamic>>()
              .where(isToday)
              .toList()
            ..sort((a, b) {
              final la = isMatchLive(a);
              final lb = isMatchLive(b);
              if (la != lb) return la ? -1 : 1;
              return DateTime.parse(a['kickoff_at'] as String)
                  .compareTo(DateTime.parse(b['kickoff_at'] as String));
            });

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
                      if (_silentRefreshing)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1280),
                                child: Text(
                                  'Atualizando...',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                              child: Text(
                                'Meus Palpites',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (todayGames.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1280),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                                      child: Text(
                                        'Próximos Jogos',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onBackground,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 290,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: todayGames.length,
                                        itemBuilder: (context, index) {
                                          final m = todayGames[index];
                                          return Container(
                                            width: 320,
                                            margin: const EdgeInsets.only(right: 12),
                                            child: MatchCard(
                                              key: ValueKey('next-${m['id']}'),
                                              match: m,
                                              matches: widget.session.matches,
                                              onSave: (home, away) => _submitPrediction(
                                                context,
                                                m['id'] as int,
                                                home,
                                                away,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (groupPhaseClosed)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1280),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Os palpites da primeira fase estão encerrados.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onError,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                              child: HallHighlightsRow(data: _hall),
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
                      else ...[
                        ..._matchSection(
                          context,
                          'Jogos que não aconteceram',
                          filtered
                              .whereType<Map<String, dynamic>>()
                              .where((m) => m['status'] != 'finished')
                              .toList(),
                        ),
                        ..._matchSection(
                          context,
                          'Jogos finalizados',
                          filtered
                              .whereType<Map<String, dynamic>>()
                              .where((m) => m['status'] == 'finished')
                              .toList(),
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

  /// Renderiza uma seção rotulada (título + grupos por data), ou nada se vazia.
  List<Widget> _matchSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return const [];
    final theme = Theme.of(context);
    final grouped = _groupByDate(items);
    final dateKeys = grouped.keys.toList()..sort();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      for (final dateKey in dateKeys) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final twoCol = c.maxWidth >= 760;
                    final cardWidth = twoCol ? (c.maxWidth - 16) / 2 : c.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (final m in grouped[dateKey]!)
                          SizedBox(
                            width: cardWidth,
                            child: MatchCard(
                              key: ValueKey(m['id']),
                              match: m,
                              matches: widget.session.matches,
                              onSave: (home, away) => _submitPrediction(
                                context,
                                m['id'] as int,
                                home,
                                away,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ];
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

  bool _isGroupPhasePredictionsClosed(List<dynamic> matches) {
    for (final raw in matches) {
      final m = raw as Map<String, dynamic>;
      if (m['stage'] != 'group') continue;

      final reason = m['prediction_lock_reason'] as String?;
      if (reason == 'Prazo da fase de grupos encerrado.') {
        return true;
      }

      final deadlineRaw = m['prediction_deadline_at'] as String?;
      if (deadlineRaw != null) {
        final deadline = DateTime.tryParse(deadlineRaw)?.toLocal();
        if (deadline != null && !DateTime.now().isBefore(deadline)) {
          return true;
        }
      }
    }
    return false;
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
  final MatchesRepository matches;
  final Future<void> Function(int homeScore, int awayScore) onSave;

  const MatchCard({
    super.key,
    required this.match,
    required this.matches,
    required this.onSave,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  static const double _flagSize = 48;
  static const double _scoreSize = 52;

  late final TextEditingController _home;
  late final TextEditingController _away;
  bool _saving = false;
  bool _expanded = false;

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
    final canEditPrediction = open && !awaitingTeams;

    final status = widget.match['status'] as String? ?? 'scheduled';
    final isFinished = status == 'finished';
    final result = widget.match['result'] as Map<String, dynamic>?;
    final liveScore = widget.match['live_score'] as Map<String, dynamic>?;
    final venue = widget.match['venue'] as String?;
    final group = widget.match['group_name'] as String?;
    final isLive = isMatchLive(widget.match);
    final showCommunityPredictions = isCommunityPredictionsAvailable(widget.match);
    final myPrediction = widget.match['my_prediction'] as Map<String, dynamic>?;
    final hasRegisteredPrediction = myPrediction != null;
    final showLockReason = lockReason != null &&
        !canEditPrediction &&
        !(hasRegisteredPrediction && lockReason.contains('registrado'));
    final myPoints = isFinished ? (myPrediction?['points'] as num?)?.toInt() : null;

    final officialScoreHeader = _buildOfficialScoreHeader(
      theme: theme,
      scheme: scheme,
      isFinished: isFinished,
      result: result,
      liveScore: liveScore,
      isLive: isLive,
      myPoints: myPoints,
    );

    final stage = widget.match['stage'] as String? ?? '';
    final isGroupFinished = isFinished && stage == 'group';
    if (isGroupFinished && !_expanded) {
      return _buildCollapsedFinishedCard(
        theme: theme,
        scheme: scheme,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        result: result,
        myPrediction: myPrediction,
        myPoints: myPoints,
      );
    }

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader(
            theme: theme,
            scheme: scheme,
            venue: venue,
            group: group,
            kickoff: kickoff,
            isLive: isLive,
            onCollapse: isGroupFinished ? () => setState(() => _expanded = false) : null,
          ),
          if (officialScoreHeader != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFinished
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
                    : scheme.primaryContainer.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.18)),
                ),
              ),
              child: Center(child: officialScoreHeader),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _teamColumn(homeTeam, alignRight: true)),
                    const SizedBox(width: 8),
                    _scoreInputs(
                      theme: theme,
                      scheme: scheme,
                      homeEnabled: canEditPrediction,
                      awayEnabled: canEditPrediction,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _teamColumn(awayTeam)),
                  ],
                ),
                if (deadline != null && open) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(deadline)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (awaitingTeams) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Aguardando definição dos times',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else if (showLockReason) ...[
                  const SizedBox(height: 8),
                  Text(
                    lockReason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (showCommunityPredictions || canEditPrediction || awaitingTeams) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (showCommunityPredictions)
                        OutlinedButton.icon(
                          onPressed: () => showMatchPredictionsSheet(
                            context,
                            matches: widget.matches,
                            matchId: widget.match['id'] as int,
                            homeTeamName: homeTeam['name'] as String? ?? '—',
                            awayTeamName: awayTeam['name'] as String? ?? '—',
                            isFinished: isFinished,
                          ),
                          icon: const Icon(Icons.groups_outlined, size: 18),
                          label: const Text('Ver palpites'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const Spacer(),
                      if (canEditPrediction)
                        FilledButton(
                          onPressed: awaitingTeams || _saving
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
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(awaitingTeams ? 'Times pendentes' : 'Salvar palpite'),
                        )
                      else if (awaitingTeams)
                        const FilledButton(
                          onPressed: null,
                          child: Text('Times pendentes'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required ThemeData theme,
    required ColorScheme scheme,
    required String? venue,
    required String? group,
    required DateTime kickoff,
    required bool isLive,
    VoidCallback? onCollapse,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            DateFormat('HH:mm', 'pt_BR').format(kickoff),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          if (venue != null && venue.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '·',
                style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            ),
            Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                venue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (isLive) ...[
            _StatusChip(
              label: 'Ao vivo',
              background: scheme.errorContainer.withValues(alpha: 0.35),
              foreground: scheme.error,
              border: scheme.error.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 6),
          ],
          if (group != null && group.isNotEmpty)
            _StatusChip(
              label: 'Grupo $group',
              background: scheme.primaryContainer.withValues(alpha: 0.22),
              foreground: scheme.onPrimaryContainer,
              border: scheme.primaryContainer.withValues(alpha: 0.30),
            ),
          if (onCollapse != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onCollapse,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.expand_less, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamColumn(Map<String, dynamic> team, {bool alignRight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _teamFlag(team),
        const SizedBox(height: 8),
        _teamName(team, alignRight: alignRight),
      ],
    );
  }

  Widget? _buildOfficialScoreHeader({
    required ThemeData theme,
    required ColorScheme scheme,
    required bool isFinished,
    required Map<String, dynamic>? result,
    required Map<String, dynamic>? liveScore,
    required bool isLive,
    int? myPoints,
  }) {
    if (isFinished && result != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Encerrado',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Placar oficial',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${result['home_score']} × ${result['away_score']}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 1,
            ),
          ),
          if (myPoints != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seu palpite',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                PredictionPointsBadge(points: myPoints),
              ],
            ),
          ],
        ],
      );
    }

    if (isLive && liveScore != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Placar ao vivo',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${liveScore['home_score']} × ${liveScore['away_score']}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

    return null;
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

  Widget _buildCollapsedFinishedCard({
    required ThemeData theme,
    required ColorScheme scheme,
    required Map<String, dynamic> homeTeam,
    required Map<String, dynamic> awayTeam,
    required Map<String, dynamic>? result,
    required Map<String, dynamic>? myPrediction,
    required int? myPoints,
  }) {
    final hScore = result?['home_score'];
    final aScore = result?['away_score'];
    final hasPrediction = myPrediction != null;
    final ph = myPrediction?['home_score'];
    final pa = myPrediction?['away_score'];

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => setState(() => _expanded = true),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  FlagImage(url: homeTeam['flag_url'] as String?, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _shortName(homeTeam),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$hScore × $aScore',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _shortName(awayTeam),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FlagImage(url: awayTeam['flag_url'] as String?, size: 26),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    hasPrediction ? 'Seu palpite: $ph × $pa' : 'Sem palpite',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (myPoints != null) PredictionPointsBadge(points: myPoints),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 18, color: scheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortName(Map<String, dynamic> team) {
    final isPlaceholder = team['is_placeholder'] as bool? ?? false;
    if (isPlaceholder) return 'A definir';
    return (team['name'] as String?) ?? '—';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
