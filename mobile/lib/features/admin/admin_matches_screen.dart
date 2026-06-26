import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/glass.dart';
import '../../ui/match_filters.dart';
import '../../ui/shell_header.dart';

class AdminMatchesScreen extends StatefulWidget {
  final SessionController session;

  const AdminMatchesScreen({super.key, required this.session});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _matches = [];
  String? _group;
  String? _stage;
  String? _status;

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
      final data = await widget.session.admin.listMatches(
        group: _group,
        stage: _stage,
        status: _status,
      );
      setState(() => _matches = data);
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar jogos.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editMetadata(Map<String, dynamic> m) async {
    final kickoff = DateTime.tryParse(m['kickoff_at'] as String? ?? '') ?? DateTime.now();
    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm');
    final dateCtrl = TextEditingController(text: dateFmt.format(kickoff.toLocal()));
    final timeCtrl = TextEditingController(text: timeFmt.format(kickoff.toLocal()));
    final venueCtrl = TextEditingController(text: m['venue'] as String? ?? '');
    var stage = m['stage'] as String? ?? 'group';
    var group = m['group_name'] as String?;
    var status = m['status'] as String? ?? 'scheduled';

    // Load teams for dropdowns.
    List<dynamic> teams = [];
    try {
      teams = await widget.session.admin.listTeams();
    } catch (_) {
      // Proceed without team selection if fetch fails.
    }

    // Initialise with current team ids when present.
    int? homeTeamId = (m['home_team'] as Map?)?.cast<String, dynamic>()['id'] as int?;
    int? awayTeamId = (m['away_team'] as Map?)?.cast<String, dynamic>()['id'] as int?;

    // Clamp team ids to null if not in the teams list (for knockout placeholders like "2A", "W73")
    if (teams.isNotEmpty) {
      final teamIds = teams.map((t) => (t as Map).cast<String, dynamic>()['id'] as int).toSet();
      homeTeamId = teamIds.contains(homeTeamId) ? homeTeamId : null;
      awayTeamId = teamIds.contains(awayTeamId) ? awayTeamId : null;
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar jogo'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(m['home_team'] as Map)['name']} × ${(m['away_team'] as Map)['name']}',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(labelText: 'Hora (HH:MM)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: venueCtrl,
                    decoration: const InputDecoration(labelText: 'Local'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: stage,
                    decoration: const InputDecoration(labelText: 'Fase'),
                    items: const [
                      DropdownMenuItem(value: 'group', child: Text('Fase de grupos')),
                      DropdownMenuItem(value: 'knockout', child: Text('Mata-mata')),
                    ],
                    onChanged: (v) => setLocal(() => stage = v ?? 'group'),
                  ),
                  if (stage == 'group') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: group,
                      decoration: const InputDecoration(labelText: 'Grupo'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...List.generate(12, (i) {
                          final g = String.fromCharCode(65 + i);
                          return DropdownMenuItem(value: g, child: Text('Grupo $g'));
                        }),
                      ],
                      onChanged: (v) => setLocal(() => group = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('Agendado')),
                      DropdownMenuItem(value: 'finished', child: Text('Finalizado')),
                    ],
                    onChanged: (v) => setLocal(() => status = v ?? 'scheduled'),
                  ),
                  if (teams.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: homeTeamId,
                      decoration: const InputDecoration(labelText: 'Mandante'),
                      items: teams.map((t) {
                        final team = (t as Map).cast<String, dynamic>();
                        return DropdownMenuItem<int>(
                          value: team['id'] as int,
                          child: Text(team['name'] as String? ?? '—'),
                        );
                      }).toList(),
                      onChanged: (v) => setLocal(() => homeTeamId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: awayTeamId,
                      decoration: const InputDecoration(labelText: 'Visitante'),
                      items: teams.map((t) {
                        final team = (t as Map).cast<String, dynamic>();
                        return DropdownMenuItem<int>(
                          value: team['id'] as int,
                          child: Text(team['name'] as String? ?? '—'),
                        );
                      }).toList(),
                      onChanged: (v) => setLocal(() => awayTeamId = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  final dateParts = dateCtrl.text.trim().split('-');
                  final timeParts = timeCtrl.text.trim().split(':');
                  if (dateParts.length != 3 || timeParts.length < 2) {
                    showSnack(ctx, 'Data ou hora inválida.', error: true);
                    return;
                  }
                  final dt = DateTime(
                    int.parse(dateParts[0]),
                    int.parse(dateParts[1]),
                    int.parse(dateParts[2]),
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                  await widget.session.admin.updateMatch(
                    m['id'] as int,
                    {
                      'kickoff_at': dt.toUtc().toIso8601String(),
                      'venue': venueCtrl.text.trim().isEmpty ? null : venueCtrl.text.trim(),
                      'stage': stage,
                      'group_name': stage == 'group' ? group : null,
                      'status': status,
                    },
                    homeTeamId: homeTeamId,
                    awayTeamId: awayTeamId,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, dioErrorMessage(e), error: true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    dateCtrl.dispose();
    timeCtrl.dispose();
    venueCtrl.dispose();
    if (saved == true) {
      if (mounted) showSnack(context, 'Jogo atualizado.');
      await _load();
    }
  }

  Future<void> _editResult(Map<String, dynamic> m) async {
    var status = m['status'] as String? ?? 'scheduled';
    final homeCtrl = TextEditingController(text: '${m['home_score'] ?? ''}');
    final awayCtrl = TextEditingController(text: '${m['away_score'] ?? ''}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Lançar resultado'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(m['home_team'] as Map)['name']} × ${(m['away_team'] as Map)['name']}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'scheduled', child: Text('Agendado (sem placar)')),
                    DropdownMenuItem(value: 'finished', child: Text('Finalizado')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? 'scheduled'),
                ),
                if (status == 'finished') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: homeCtrl,
                          decoration: const InputDecoration(labelText: 'Casa'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('×'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: awayCtrl,
                          decoration: const InputDecoration(labelText: 'Fora'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  if (status == 'finished') {
                    final h = int.tryParse(homeCtrl.text.trim());
                    final a = int.tryParse(awayCtrl.text.trim());
                    if (h == null || a == null) {
                      showSnack(ctx, 'Informe o placar completo.', error: true);
                      return;
                    }
                    await widget.session.admin.updateMatchResult(
                      m['id'] as int,
                      status: status,
                      homeScore: h,
                      awayScore: a,
                    );
                  } else {
                    await widget.session.admin.updateMatchResult(m['id'] as int, status: status);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, dioErrorMessage(e), error: true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    homeCtrl.dispose();
    awayCtrl.dispose();
    if (saved == true) {
      if (mounted) showSnack(context, 'Resultado atualizado. Pontos recalculados.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = DateFormat('dd/MM HH:mm');

    return ShellPage(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Glass(
                  blur: 12,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MatchFilters(
                        group: _group,
                        stage: _stage,
                        onlyOpen: false,
                        showOnlyOpen: false,
                        onGroupChanged: (v) => setState(() => _group = v),
                        onStageChanged: (v) => setState(() => _stage = v),
                        onOnlyOpenChanged: (_) {},
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'scheduled', child: Text('Agendados')),
                          DropdownMenuItem(value: 'finished', child: Text('Finalizados')),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(onPressed: _load, child: const Text('Aplicar filtros')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : Glass(
                              blur: 12,
                              borderRadius: BorderRadius.circular(20),
                              padding: EdgeInsets.zero,
                              child: ListView.separated(
                                itemCount: _matches.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                                ),
                                itemBuilder: (context, index) {
                                  final m = (_matches[index] as Map).cast<String, dynamic>();
                                  final home = (m['home_team'] as Map).cast<String, dynamic>();
                                  final away = (m['away_team'] as Map).cast<String, dynamic>();
                                  final kickoff = DateTime.tryParse(m['kickoff_at'] as String? ?? '');
                                  final finished = m['status'] == 'finished';
                                  final group = m['group_name'] as String?;
                                  return ListTile(
                                    title: Text('${home['name']} × ${away['name']}'),
                                    subtitle: Text(
                                      [
                                        if (kickoff != null) fmt.format(kickoff.toLocal()),
                                        if (m['venue'] != null) m['venue'] as String,
                                        if (group != null) 'Grupo $group',
                                        m['stage'] == 'knockout' ? 'Mata-mata' : null,
                                      ].whereType<String>().join(' • '),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (finished)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              '${m['home_score']} × ${m['away_score']}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: scheme.primary,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit_calendar_outlined),
                                          onPressed: () => _editMetadata(m),
                                        ),
                                        IconButton(
                                          tooltip: 'Resultado',
                                          icon: const Icon(Icons.scoreboard_outlined),
                                          onPressed: () => _editResult(m),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
