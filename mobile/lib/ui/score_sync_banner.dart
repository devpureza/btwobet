import 'dart:async';

import 'package:flutter/material.dart';

import '../features/matches/score_sync_repository.dart';

class ScoreSyncBanner extends StatefulWidget {
  final ScoreSyncRepository repository;

  const ScoreSyncBanner({super.key, required this.repository});

  @override
  State<ScoreSyncBanner> createState() => _ScoreSyncBannerState();
}

class _ScoreSyncBannerState extends State<ScoreSyncBanner> {
  Map<String, dynamic>? _status;
  Timer? _tick;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _refresh = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getStatus();
      if (mounted) setState(() => _status = data);
    } catch (_) {
      // Mantém último status ou oculta detalhes.
    }
  }

  String _formatMinutes(Duration d) {
    final total = d.inSeconds;
    if (total < 60) return '${total}s';
    final m = (total / 60).ceil();
    return m == 1 ? '1 min' : '$m min';
  }

  String _buildMessage() {
    final status = _status;
    if (status == null) {
      return 'Placares atualizados automaticamente pelo ge.globo';
    }

    final source = (status['source'] as String?) ?? 'ge.globo';
    final now = DateTime.now();

    final lastRaw = status['last_sync_at'] as String?;
    final nextRaw = status['next_sync_at'] as String?;
    final lastUpdated = status['last_updated_matches'] as int?;

    final parts = <String>['Placares via $source'];

    if (lastRaw != null) {
      final last = DateTime.parse(lastRaw).toLocal();
      final ago = now.difference(last);
      if (!ago.isNegative) {
        parts.add('atualizado há ${_formatMinutes(ago)}');
      }
    }

    if (nextRaw != null) {
      final next = DateTime.parse(nextRaw).toLocal();
      final until = next.difference(now);
      if (until.inSeconds > 0) {
        parts.add('próxima em ${_formatMinutes(until)}');
      } else {
        parts.add('próxima atualização em breve');
      }
    }

    if (lastUpdated != null && lastUpdated > 0) {
      parts.add('$lastUpdated jogo(s) na última rodada');
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sync, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _buildMessage(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
