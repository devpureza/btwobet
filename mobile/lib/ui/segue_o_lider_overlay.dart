import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/ranking/ranking_repository.dart';
import 'glass.dart';
import 'user_avatar.dart';

/// "Segue o líder" — gracinha discreta no canto inferior direito: a cada 30s
/// mostra a foto redondinha do líder (👑) e do último (🔻 lanterna).
/// Não bloqueia toque, pra não atrapalhar quem está mexendo.
class SegueOLiderOverlay extends StatefulWidget {
  final RankingRepository ranking;

  const SegueOLiderOverlay({super.key, required this.ranking});

  @override
  State<SegueOLiderOverlay> createState() => _SegueOLiderOverlayState();
}

class _SegueOLiderOverlayState extends State<SegueOLiderOverlay>
    with SingleTickerProviderStateMixin {
  static const _interval = Duration(seconds: 30);

  late final AnimationController _ctrl;
  Timer? _timer;
  Map<String, dynamic>? _leader;
  Map<String, dynamic>? _last;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _loadRanking();
    _timer = Timer.periodic(_interval, (_) => _play());
  }

  Future<void> _loadRanking() async {
    try {
      final rows = await widget.ranking.getRanking();
      if (!mounted || rows.isEmpty) return;
      setState(() {
        _leader = (rows.first as Map).cast<String, dynamic>();
        _last = rows.length > 1 ? (rows.last as Map).cast<String, dynamic>() : null;
      });
    } catch (_) {
      // gracinha: falha silenciosa, tenta de novo no próximo ciclo
    }
  }

  Future<void> _play() async {
    await _loadRanking();
    if (!mounted || _leader == null) return;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  double _fade(double t) {
    if (t < 0.12) return t / 0.12;
    if (t > 0.85) return ((1 - t) / 0.15).clamp(0.0, 1.0);
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_leader == null && _last == null) return const SizedBox.shrink();
    return Positioned(
      right: 12,
      bottom: 12,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            if (t == 0) return const SizedBox.shrink();
            // Entra deslizando suave da direita.
            final slide =
                (1 - Curves.easeOutCubic.transform(math.min(1.0, t * 4))) * 40;
            return Opacity(
              opacity: _fade(t).clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(slide, 0), child: _card()),
            );
          },
        ),
      ),
    );
  }

  Widget _card() {
    final scheme = Theme.of(context).colorScheme;
    return Glass(
      blur: 14,
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_leader != null)
            _person(_leader!, '👑', 'Líder', const Color(0xFFFCD400)),
          if (_leader != null && _last != null) const SizedBox(width: 16),
          if (_last != null) _person(_last!, '🔻', 'Lanterna', scheme.error),
        ],
      ),
    );
  }

  Widget _person(
    Map<String, dynamic> p,
    String emoji,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final name = (p['name'] as String?)?.trim() ?? '';
    final url = p['avatar_url'] as String?;
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final first = name.isEmpty ? '—' : name.split(' ').first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$emoji $label',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: UserAvatar(url: url, size: 52, fallbackLetter: initial),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
