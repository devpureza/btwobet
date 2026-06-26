import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../features/ranking/ranking_repository.dart';

/// "Segue o líder" — gracinha em modo SUSTO: a cada 40s a foto do líder toma
/// a tela INTEIRA por alguns segundos, com "SEGUE O LÍDER" e o nome.
/// Decorativo (não bloqueia toque).
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
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

  /// Aparece quase instantâneo (o susto), segura, e some.
  double _opacity(double t) {
    if (t < 0.04) return t / 0.04;
    if (t > 0.70) return ((1 - t) / 0.30).clamp(0.0, 1.0);
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final leader = _leader;
    if (leader == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            if (t == 0) return const SizedBox.shrink();
            // "pop" de escala pra reforçar o susto.
            final pop =
                1.0 + 0.18 * (1 - Curves.easeOut.transform(math.min(1.0, t * 5)));
            return Opacity(
              opacity: _opacity(t).clamp(0.0, 1.0),
              child: Transform.scale(scale: pop, child: _fullScreen(leader)),
            );
          },
        ),
      ),
    );
  }

  Widget _fullScreen(Map<String, dynamic> leader) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = (leader['name'] as String?)?.trim();
    final url = leader['avatar_url'] as String?;
    final hasPhoto = url != null && url.isNotEmpty;
    final initial =
        (name == null || name.isEmpty) ? '?' : name.substring(0, 1).toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fundo escuro cobrindo tudo (tampa a tela).
        ColoredBox(color: Colors.black.withValues(alpha: 0.82)),
        // Foto do líder centralizada, com ~20% de margem (60% da tela).
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.6,
            heightFactor: 0.6,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF06130D),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x99000000), blurRadius: 40, spreadRadius: 2),
                ],
              ),
              child: hasPhoto
                  ? Image.network(
                      ApiClient.resolveMediaUrl(url) ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, _) => _fallbackBg(scheme, initial),
                    )
                  : _balloonBg(),
            ),
          ),
        ),
        // "SEGUE O LÍDER" no topo, nome embaixo.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SEGUE O LÍDER',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFCD400),
                    letterSpacing: 1,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 18, offset: Offset(0, 4)),
                    ],
                  ),
                ),
                if (name != null && name.isNotEmpty)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 14, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackBg(ColorScheme scheme, String initial) {
    return ColoredBox(
      color: scheme.secondary,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 240,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _balloonBg() {
    return const ColoredBox(
      color: Color(0xFF00341C),
      child: Center(child: Text('🎈', style: TextStyle(fontSize: 240))),
    );
  }
}
