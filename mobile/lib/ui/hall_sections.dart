import 'package:flutter/material.dart';

import '../features/matches/hall_entry.dart';
import 'glass.dart';
import 'user_avatar.dart';

enum HallCardKind { fame, shame }

/// Card do Hall da Fama ou Hall da Vergonha.
class HallCard extends StatelessWidget {
  final HallCardKind kind;
  final List<HallEntry> entries;
  final int highlightedIndex;
  final String periodLabel;
  final bool compact;

  const HallCard({
    super.key,
    required this.kind,
    required this.entries,
    required this.highlightedIndex,
    required this.periodLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFame = kind == HallCardKind.fame;
    final isEmpty = entries.isEmpty;

    final accent = isFame ? const Color(0xFFFCD400) : scheme.error.withValues(alpha: 0.85);
    final icon = isFame ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded;
    final title = isFame ? 'Hall da Fama' : 'Hall da Vergonha';
    final padding = compact
        ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
        : const EdgeInsets.fromLTRB(14, 12, 14, 12);

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: padding,
      border: BorderSide(
        color: (isFame ? accent : scheme.error).withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 20 : 22, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (!isEmpty) _PeriodChip(label: periodLabel, compact: compact),
            ],
          ),
          if (!isFame && !compact) ...[
            const SizedBox(height: 6),
            Text(
              'Métrica divertida — opt-out em breve',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          if (isEmpty)
            _EmptyHallState(isFame: isFame, compact: compact)
          else ...[
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
                key: ValueKey('${kind.name}_${entries[highlightedIndex.clamp(0, entries.length - 1)].key}'),
                entry: entries[highlightedIndex.clamp(0, entries.length - 1)],
                accent: accent,
                isFame: isFame,
                compact: compact,
              ),
            ),
            if (entries.length > 1) ...[
              SizedBox(height: compact ? 8 : 10),
              _EntryDots(
                count: entries.length,
                activeIndex: highlightedIndex,
                activeColor: accent,
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                ...entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _CompactEntryRow(
                      entry: e,
                      isActive: e.key == entries[highlightedIndex.clamp(0, entries.length - 1)].key,
                      accent: accent,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyHallState extends StatelessWidget {
  final bool isFame;
  final bool compact;

  const _EmptyHallState({required this.isFame, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = isFame
        ? 'Ninguém ainda — palpite nos jogos!'
        : 'Ninguém se destacou (ainda) — sorte!';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      child: Text(
        message,
        maxLines: compact ? 2 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool compact;

  const _PeriodChip({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
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
              fontSize: compact ? 10 : null,
            ),
      ),
    );
  }
}

class _HighlightedEntry extends StatelessWidget {
  final HallEntry entry;
  final Color accent;
  final bool isFame;
  final bool compact;

  const _HighlightedEntry({
    super.key,
    required this.entry,
    required this.accent,
    required this.isFame,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = compact ? 40.0 : 52.0;

    return Row(
      children: [
        UserAvatar(
          url: entry.avatarUrl,
          size: avatarSize,
          fallbackLetter: entry.fallbackLetter,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.subtitle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
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
          size: compact ? 22 : 28,
        ),
      ],
    );
  }
}

class _CompactEntryRow extends StatelessWidget {
  final HallEntry entry;
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
          UserAvatar(
            url: entry.avatarUrl,
            size: 32,
            fallbackLetter: entry.fallbackLetter,
          ),
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
