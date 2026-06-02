import 'dart:async';

import 'package:flutter/material.dart';

import 'achievement_tier_style.dart';
import 'glass.dart';

/// Feed global no canto superior direito para conquistas desbloqueadas.
class AchievementUnlockFeedController extends ChangeNotifier {
  AchievementUnlockFeedController._();

  static final AchievementUnlockFeedController instance = AchievementUnlockFeedController._();

  static const int maxVisible = 3;
  static const Duration autoDismiss = Duration(seconds: 8);

  final List<AchievementFeedEntry> _entries = [];
  final Map<String, Timer> _timers = {};

  List<AchievementFeedEntry> get visibleEntries {
    if (_entries.length <= maxVisible) return List.unmodifiable(_entries);
    return List.unmodifiable(_entries.sublist(_entries.length - maxVisible));
  }

  void showAll(Iterable<Map<String, dynamic>> achievements) {
    for (final achievement in achievements) {
      show(achievement);
    }
  }

  void show(Map<String, dynamic> achievement) {
    final name = achievement['name'] as String? ?? 'Conquista';
    final tier = achievement['tier'] as String? ?? 'bronze';
    final slug = achievement['slug'] as String? ?? name;
    final id = '${slug}_${DateTime.now().microsecondsSinceEpoch}';

    _entries.add(AchievementFeedEntry(id: id, name: name, tier: tier));
    if (_entries.length > maxVisible + 4) {
      final overflow = _entries.length - maxVisible - 4;
      for (var i = 0; i < overflow; i++) {
        _cancelTimer(_entries.first.id);
        _entries.removeAt(0);
      }
    }

    _timers[id] = Timer(autoDismiss, () => dismiss(id));
    notifyListeners();
  }

  void dismiss(String id) {
    _cancelTimer(id);
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.id == id);
    if (_entries.length != before) notifyListeners();
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.cancel();
  }
}

class AchievementFeedEntry {
  final String id;
  final String name;
  final String tier;

  const AchievementFeedEntry({
    required this.id,
    required this.name,
    required this.tier,
  });
}

/// Mantém um [OverlayEntry] para o feed de conquistas.
class AchievementUnlockFeedHost extends StatefulWidget {
  final Widget child;

  const AchievementUnlockFeedHost({super.key, required this.child});

  @override
  State<AchievementUnlockFeedHost> createState() => _AchievementUnlockFeedHostState();
}

class _AchievementUnlockFeedHostState extends State<AchievementUnlockFeedHost> {
  final _controller = AchievementUnlockFeedController.instance;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onFeedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOverlay());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureOverlay();
  }

  @override
  void dispose() {
    _controller.removeListener(_onFeedChanged);
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _onFeedChanged() {
    _ensureOverlay();
    _entry?.markNeedsBuild();
  }

  void _ensureOverlay() {
    if (!mounted || _entry != null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOverlay());
      return;
    }

    _entry = OverlayEntry(
      builder: (context) => _AchievementUnlockFeedOverlay(controller: _controller),
    );
    overlay.insert(_entry!);
    if (_controller.visibleEntries.isNotEmpty) {
      _entry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AchievementUnlockFeedOverlay extends StatelessWidget {
  final AchievementUnlockFeedController controller;

  const _AchievementUnlockFeedOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final entries = controller.visibleEntries;
        if (entries.isEmpty) return const SizedBox.shrink();

        final media = MediaQuery.of(context);
        final top = media.padding.top + 8;
        final right = media.padding.right + 12;
        final maxWidth = media.size.width < 400 ? media.size.width - right - 12 : 320.0;

        return Positioned(
          top: top,
          right: right,
          width: maxWidth,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementUnlockCard(
                      entry: entry,
                      onDismiss: () => controller.dismiss(entry.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementUnlockCard extends StatelessWidget {
  final AchievementFeedEntry entry;
  final VoidCallback onDismiss;

  const _AchievementUnlockCard({
    required this.entry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tierColor = achievementTierColor(entry.tier, scheme);

    return GestureDetector(
      onTap: onDismiss,
      child: Glass(
        blur: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: BorderRadius.circular(14),
        border: BorderSide(color: tierColor.withValues(alpha: 0.45)),
        child: Row(
          children: [
            Icon(
              achievementTierIcon(entry.tier, unlocked: true),
              color: tierColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Você conquistou: ${entry.name}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.close, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

void showAchievementUnlocks(List<Map<String, dynamic>> achievements) {
  if (achievements.isEmpty) return;
  AchievementUnlockFeedController.instance.showAll(achievements);
}
