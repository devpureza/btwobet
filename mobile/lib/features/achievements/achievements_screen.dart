import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AchievementsScreen extends StatefulWidget {
  final SessionController session;

  const AchievementsScreen({super.key, required this.session});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _catalog = [];

  int get _unlockedCount => _catalog.where((item) {
        return ((item as Map)['unlocked'] as bool?) ?? false;
      }).length;

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
      final data = await widget.session.achievements.getMyAchievements();
      final catalog = data['catalog'] as List<dynamic>? ?? [];
      setState(() => _catalog = catalog);
      await widget.session.refreshAchievementStats(catalog: catalog);
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar conquistas.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _tierColor(String tier, ColorScheme scheme) {
    return switch (tier) {
      'bronze' => const Color(0xFFCD7F32),
      'silver' => const Color(0xFF9E9E9E),
      'gold' => const Color(0xFFD4AF37),
      'platinum' => scheme.primary,
      _ => scheme.outline,
    };
  }

  String _tierLabel(String tier) {
    return switch (tier) {
      'bronze' => 'Bronze',
      'silver' => 'Prata',
      'gold' => 'Ouro',
      'platinum' => 'Platina',
      _ => tier,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _catalog.length;
    final unlocked = _unlockedCount;

    return ShellPage(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 960),
                              child: Glass(
                                blur: 12,
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  children: [
                                    Icon(Icons.emoji_events, color: scheme.primary, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Suas conquistas',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            total == 0
                                                ? 'Nenhuma conquista disponível ainda.'
                                                : '$unlocked de $total desbloqueadas',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (total > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '$unlocked/$total',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            color: scheme.onPrimaryContainer,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (total == 0)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('Catálogo vazio no momento.')),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 176,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = (_catalog[index] as Map).cast<String, dynamic>();
                                final unlockedItem = item['unlocked'] as bool? ?? false;
                                final tier = item['tier'] as String? ?? 'bronze';
                                final progress = item['progress'] as Map<String, dynamic>?;
                                final current = (progress?['current'] as num?)?.toInt();
                                final target = (progress?['target'] as num?)?.toInt();

                                return Glass(
                                  blur: 10,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Opacity(
                                    opacity: unlockedItem ? 1 : 0.55,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                unlockedItem ? Icons.emoji_events : Icons.lock_outline,
                                                color: _tierColor(tier, scheme),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _tierColor(tier, scheme).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _tierLabel(tier),
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: _tierColor(tier, scheme),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item['name'] as String? ?? '',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              item['description'] as String? ?? '',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (progress != null && current != null && target != null && target > 0) ...[
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                              value: (current / target).clamp(0.0, 1.0),
                                              minHeight: 4,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$current / $target',
                                              style: theme.textTheme.labelSmall,
                                            ),
                                          ] else if (!unlockedItem) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Bloqueada',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: scheme.outline,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _catalog.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
