import 'package:flutter/material.dart';

import '../features/matches/hall_entry.dart';
import 'glass.dart';
import 'user_avatar.dart';

/// Card divertido do destaque capilar da semana.
class CarecaDaRodadaCard extends StatelessWidget {
  final CarecaDaRodada data;
  final bool compact;

  const CarecaDaRodadaCard({super.key, required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const accent = Color(0xFFE8C4A0);
    final padding = compact
        ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
        : const EdgeInsets.fromLTRB(14, 12, 14, 12);
    final avatarSize = compact ? 40.0 : 52.0;

    return Glass(
      blur: 12,
      borderRadius: BorderRadius.circular(20),
      padding: padding,
      border: BorderSide(color: accent.withValues(alpha: 0.45)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_rounded, size: compact ? 20 : 22, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (data.isoWeek > 0) _WeekChip(isoWeek: data.isoWeek, compact: compact),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              UserAvatar(
                url: data.avatarUrl,
                size: avatarSize,
                fallbackLetter: data.fallbackLetter,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compact ? 'Brilho próprio' : 'Brilho próprio, zero fio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.wb_sunny_rounded,
                color: accent.withValues(alpha: 0.95),
                size: compact ? 22 : 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekChip extends StatelessWidget {
  final int isoWeek;
  final bool compact;

  const _WeekChip({required this.isoWeek, this.compact = false});

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
        'Sem. $isoWeek',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontSize: compact ? 10 : null,
            ),
      ),
    );
  }
}
