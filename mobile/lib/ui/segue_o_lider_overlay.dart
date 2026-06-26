import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../features/ranking/ranking_repository.dart';
import 'avatar_image.dart';

/// "Segue o líder" — gracinha: a cada 40s sobe a foto/nome do líder do ranking,
/// com fade subindo do canto inferior direito. Decorativo (não bloqueia toque).
class SegueOLiderOverlay extends StatefulWidget {
  final RankingRepository ranking;

  const SegueOLiderOverlay({super.key, required this.ranking});

  @override
  State<SegueOLiderOverlay> createState() => _SegueOLiderOverlayState();
}

class _SegueOLiderOverlayState extends State<SegueOLiderOverlay>
    with SingleTickerProviderStateMixin {
  static const _interval = Duration(seconds: 40);

  late final AnimationController _ctrl;
  Timer? _timer;
  Map<String, dynamic>? _leader;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _loadLeader();
    _timer = Timer.periodic(_interval, (_) => _play());
  }

  Future<void> _loadLeader() async {
    try {
      final rows = await widget.ranking.getRanking();
      if (!mounted || rows.isEmpty) return;
      setState(() => _leader = (rows.first as Map).cast<String, dynamic>());
    } catch (_) {
      // gracinha: falha silenciosa, tenta de novo no próximo ciclo
    }
  }

  Future<void> _play() async {
    await _loadLeader();
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
    if (t < 0.18) return t / 0.18;
    if (t > 0.82) return (1 - t) / 0.18;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final leader = _leader;
    if (leader == null) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            if (t == 0) return const SizedBox.shrink();
            final rise = Curves.easeOutCubic.transform(t);
            final bottom = lerpDouble(-80, size.height * 0.46, rise)!;
            final right = lerpDouble(4, size.width * 0.5 - 110, rise)!;
            final scale =
                0.45 + 0.7 * Curves.easeOutBack.transform(math.min(1.0, t * 1.25));
            return Stack(
              children: [
                Positioned(
                  right: right,
                  bottom: bottom,
                  child: Opacity(
                    opacity: _fade(t).clamp(0.0, 1.0),
                    child: Transform.scale(scale: scale, child: _content(leader)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(Map<String, dynamic> leader) {
    final theme = Theme.of(context);
    final name = (leader['name'] as String?)?.trim();
    final url = leader['avatar_url'] as String?;
    final hasPhoto = url != null && url.isNotEmpty;
    final initial =
        (name == null || name.isEmpty) ? '?' : name.substring(0, 1).toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCD400),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Text(
            'SEGUE O LÍDER',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00341C),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (hasPhoto)
          DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: AvatarImage(url: url, size: 140, fallbackLetter: initial),
          )
        else
          const Text('🎈', style: TextStyle(fontSize: 120)),
        const SizedBox(height: 8),
        if (name != null && name.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
