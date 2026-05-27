import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/shell_header.dart';

class HistoryScreen extends StatefulWidget {
  final SessionController session;

  const HistoryScreen({super.key, required this.session});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  int _totalPoints = 0;
  List<dynamic> _items = [];

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
      final data = await widget.session.history.getMyHistory();
      setState(() {
        _totalPoints = (data['total_points'] as num).toInt();
        _items = data['data'] as List<dynamic>;
      });
    } catch (e) {
      setState(() => _error = 'Falha ao carregar histórico.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ShellPage(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events),
                              const SizedBox(width: 12),
                              Text('Total: $_totalPoints pontos', style: theme.textTheme.headlineMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index] as Map<String, dynamic>;
                          final kickoff = DateTime.parse(item['kickoff_at'] as String).toLocal();
                          final pred = item['prediction'] as Map<String, dynamic>;
                          final result = item['result'] as Map<String, dynamic>?;
                          return Card(
                            elevation: 0,
                            color: theme.colorScheme.surface,
                            child: ListTile(
                              title: Text('${item['home_team']} x ${item['away_team']}'),
                              subtitle: Text(
                                '${DateFormat('dd/MM HH:mm').format(kickoff)} • Palpite ${pred['home_score']}x${pred['away_score']}'
                                '${result != null ? ' • Resultado ${result['home_score']}x${result['away_score']}' : ''}',
                                style: theme.textTheme.labelSmall,
                              ),
                              trailing: Text('${item['points']} pts'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                ),
    );
  }
}
