import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminPalpitesHistoryScreen extends StatefulWidget {
  final SessionController session;

  const AdminPalpitesHistoryScreen({super.key, required this.session});

  @override
  State<AdminPalpitesHistoryScreen> createState() => _AdminPalpitesHistoryScreenState();
}

class _AdminPalpitesHistoryScreenState extends State<AdminPalpitesHistoryScreen> {
  static const _perPage = 25;

  final _q = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || _currentPage >= _lastPage) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 1;
        _lastPage = 1;
        _items.clear();
      });
    }

    try {
      final data = await widget.session.admin.listPredictionsHistory(
        page: 1,
        perPage: _perPage,
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
      );
      final meta = (data['meta'] as Map).cast<String, dynamic>();
      final rows = (data['data'] as List<dynamic>)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      setState(() {
        _items
          ..clear()
          ..addAll(rows);
        _currentPage = (meta['current_page'] as num).toInt();
        _lastPage = (meta['last_page'] as num).toInt();
        _total = (meta['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar histórico de palpites.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final data = await widget.session.admin.listPredictionsHistory(
        page: nextPage,
        perPage: _perPage,
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
      );
      final meta = (data['meta'] as Map).cast<String, dynamic>();
      final rows = (data['data'] as List<dynamic>)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      setState(() {
        _items.addAll(rows);
        _currentPage = (meta['current_page'] as num).toInt();
        _lastPage = (meta['last_page'] as num).toInt();
        _total = (meta['total'] as num).toInt();
      });
    } catch (e) {
      if (mounted) {
        showSnack(context, dioErrorMessage(e, fallback: 'Falha ao carregar mais palpites.'), error: true);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _formatScore(Map<String, dynamic>? scores) {
    if (scores == null) return '—';
    return '${scores['home_score']}x${scores['away_score']}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

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
                      Text(
                        'Histórico de palpites',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log de todos os palpites registrados no bolão.',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _q,
                              decoration: const InputDecoration(
                                labelText: 'Buscar por participante ou jogo',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _load(reset: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _loading ? null : () => _load(reset: true),
                            child: const Text('Buscar'),
                          ),
                        ],
                      ),
                      if (!_loading && _error == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$_total palpite(s) no total',
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : RefreshIndicator(
                              onRefresh: () => _load(reset: true),
                              child: _items.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: const [
                                        SizedBox(height: 120),
                                        Center(child: Text('Nenhum palpite encontrado.')),
                                      ],
                                    )
                                  : Glass(
                                      blur: 12,
                                      borderRadius: BorderRadius.circular(20),
                                      padding: EdgeInsets.zero,
                                      child: ListView.separated(
                                        controller: _scroll,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                                        separatorBuilder: (_, _) => Divider(
                                          height: 1,
                                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                                        ),
                                        itemBuilder: (context, index) {
                                          if (index >= _items.length) {
                                            return const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Center(child: CircularProgressIndicator()),
                                            );
                                          }

                                          final item = _items[index];
                                          final user = (item['user'] as Map).cast<String, dynamic>();
                                          final match = (item['match'] as Map).cast<String, dynamic>();
                                          final pred = (item['prediction'] as Map).cast<String, dynamic>();
                                          final result = item['result'] as Map<String, dynamic>?;
                                          final createdAt = DateTime.parse(item['created_at'] as String).toLocal();
                                          final kickoff = DateTime.parse(match['kickoff_at'] as String).toLocal();
                                          final avatarUrl = user['avatar_url'] as String?;
                                          final points = (item['points'] as num?)?.toInt() ?? 0;

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                                  ? NetworkImage(avatarUrl)
                                                  : null,
                                              backgroundColor: scheme.secondary.withValues(alpha: 0.35),
                                              child: avatarUrl == null || avatarUrl.isEmpty
                                                  ? Text(
                                                      ((user['name'] as String?) ?? '?').substring(0, 1).toUpperCase(),
                                                    )
                                                  : null,
                                            ),
                                            title: Text(user['name'] as String? ?? '—'),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${match['home_team']} x ${match['away_team']}',
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                                Text(
                                                  'Jogo: ${DateFormat("dd/MM HH:mm").format(kickoff)} • '
                                                  'Palpite: ${_formatScore(pred)} • '
                                                  'Placar real: ${_formatScore(result)} • '
                                                  '$points pts • '
                                                  '${dateFmt.format(createdAt)}',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: scheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                Text(
                                                  user['email'] as String? ?? '',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            isThreeLine: true,
                                          );
                                        },
                                      ),
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
