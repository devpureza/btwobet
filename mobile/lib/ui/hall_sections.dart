import 'dart:async';

import 'package:flutter/material.dart';

import '../features/matches/hall_mock_data.dart';
import 'avatar_image.dart';
import 'glass.dart';

/// Hall da Fama e Hall da Vergonha na home (dados mock até a API existir).
class HallSections extends StatefulWidget {
  const HallSections({super.key});

  @override
  State<HallSections> createState() => _HallSectionsState();
}

class _HallSectionsState extends State<HallSections> {
  static const _rotateInterval = Duration(seconds: 4);

  Timer? _timer;
  int _fameIndex = 0;
  int _shameIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!mounted) return;
      setState(() {
        _fameIndex = (_fameIndex + 1) % HallMockData.hallOfFame.length;
        _shameIndex = (_shameIndex + 1) % HallMockData.hallOfShame.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _HallCard(
              kind: _HallKind.fame,
              entries: HallMockData.hallOfFame,
              highlightedIndex: _fameIndex,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HallCard(
              kind: _HallKind.shame,
              entries: HallMockData.hallOfShame,
              highlightedIndex: _shameIndex,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _HallCard(
          kind: _HallKind.fame,
          entries: HallMockData.hallOfFame,
          highlightedIndex: _fameIndex,
        ),
        const SizedBox(height: 12),
        _HallCard(
          kind: _HallKind.shame,
          entries: HallMockData.hallOfShame,
          highlightedIndex: _shameIndex,
        ),
      ],
    );
  }
}

enum _HallKind { fame, shame }

class _HallCard extends StatelessWidget {
  final _HallKind kind;
  final List<MockHallEntry> entries;
  final int highlightedIndex;

  const _HallCard({
    required this.kind,
    required this.entries,
    required this.highlightedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFame = kind == _HallKind.fame;
    final entry = entries[highlightedIndex.clamp(0, entries.length - 1)];

    final accent = isFame ? const Color(0xFFFCD400) : scheme.error.withValues(alpha: 0.85);
    final icon = isFame ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded;
    final title = isFame ? 'Hall da Fama' : 'Hall da Vergonha';

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      border: BorderSide(
        color: (isFame ? accent : scheme.error).withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _PreviewChip(label: HallMockData.previewLabel),
            ],
          ),
          if (!isFame) ...[
            const SizedBox(height: 6),
            Text(
              'Em breve dados reais — entrada opcional',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _HighlightedEntry(
              key: ValueKey('${kind.name}_${entry.id}'),
              entry: entry,
              accent: accent,
              isFame: isFame,
            ),
          ),
          const SizedBox(height: 10),
          _EntryDots(
            count: entries.length,
            activeIndex: highlightedIndex,
            activeColor: accent,
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CompactEntryRow(
                entry: e,
                isActive: e.id == entry.id,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;

  const _PreviewChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _HighlightedEntry extends StatelessWidget {
  final MockHallEntry entry;
  final Color accent;
  final bool isFame;

  const _HighlightedEntry({
    super.key,
    required this.entry,
    required this.accent,
    required this.isFame,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _MockAvatar(entry: entry, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                entry.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isFame ? Icons.star_rounded : Icons.whatshot_rounded,
          color: accent.withValues(alpha: 0.9),
          size: 28,
        ),
      ],
    );
  }
}

class _CompactEntryRow extends StatelessWidget {
  final MockHallEntry entry;
  final bool isActive;
  final Color accent;

  const _CompactEntryRow({
    required this.entry,
    required this.isActive,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      opacity: isActive ? 1 : 0.55,
      child: Row(
        children: [
          _MockAvatar(entry: entry, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            )
          else
            Icon(Icons.circle_outlined, size: 14, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}

class _EntryDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;

  const _EntryDots({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? activeColor
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MockAvatar extends StatelessWidget {
  final MockHallEntry entry;
  final double size;

  const _MockAvatar({required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    if (entry.avatarColor != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: entry.avatarColor!.withValues(alpha: 0.55),
        child: Text(
          entry.fallbackLetter.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38,
              ),
        ),
      );
    }

    return AvatarImage(
      url: null,
      size: size,
      fallbackLetter: entry.fallbackLetter,
    );
  }
}
