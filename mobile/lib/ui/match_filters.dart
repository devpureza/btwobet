import 'package:flutter/material.dart';

class MatchFilters extends StatelessWidget {
  final String? group;
  final String? stage;
  final bool onlyOpen;
  final bool showOnlyOpen;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String?> onStageChanged;
  final ValueChanged<bool> onOnlyOpenChanged;

  const MatchFilters({
    super.key,
    required this.group,
    required this.stage,
    required this.onlyOpen,
    this.showOnlyOpen = true,
    required this.onGroupChanged,
    required this.onStageChanged,
    required this.onOnlyOpenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        backgroundColor: scheme.surface.withValues(alpha: 0.65),
        selectedColor: scheme.primaryContainer.withValues(alpha: 0.18),
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: 'Todos',
            selected: group == null,
            onTap: () => onGroupChanged(null),
          ),
          const SizedBox(width: 8),
          for (final g in const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: chip(
                label: 'Grupo $g',
                selected: group == g,
                onTap: () => onGroupChanged(g),
              ),
            ),
          const SizedBox(width: 12),
          chip(
            label: 'Fase de grupos',
            selected: stage == 'group',
            onTap: () => onStageChanged(stage == 'group' ? null : 'group'),
          ),
          const SizedBox(width: 8),
          chip(
            label: 'Mata-mata',
            selected: stage == 'knockout',
            onTap: () => onStageChanged(stage == 'knockout' ? null : 'knockout'),
          ),
          const SizedBox(width: 12),
          if (showOnlyOpen)
            chip(
              label: 'Só abertos',
              selected: onlyOpen,
              onTap: () => onOnlyOpenChanged(!onlyOpen),
            ),
        ],
      ),
    );
  }
}

