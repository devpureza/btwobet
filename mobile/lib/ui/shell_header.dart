import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/session_controller.dart';
import 'avatar_image.dart';
import 'glass.dart';

class ShellHeader extends StatelessWidget {
  final String location;
  final SessionController session;

  const ShellHeader({
    super.key,
    required this.location,
    required this.session,
  });

  bool get _showBack => location.startsWith('/admin/') && location != '/admin';

  String? get _subtitle {
    if (location.startsWith('/admin/users')) return 'Participantes';
    if (location.startsWith('/admin/matches')) return 'Jogos e Resultados';
    if (location.startsWith('/admin/teams')) return 'Times e Bandeiras';
    if (location.startsWith('/admin/prediction-rules')) return 'Regras de Palpite';
    if (location.startsWith('/admin/predictions')) return 'Histórico de palpites';
    if (location == '/admin') return 'CMS Administrativo';
    if (location == '/ranking') return 'Ranking';
    if (location == '/history') return 'Histórico';
    if (location == '/profile') return 'Minha Conta';
    if (location == '/achievements') return 'Conquistas';
    if (location == '/') return 'Palpites';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final user = session.user;
    final name = user?['name'] as String? ?? '';
    final avatarUrl = user?['avatar_url'] as String?;
    final avatarInitial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);

    return Glass(
      blur: 18,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.30)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (_showBack)
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.arrow_back),
                ),
              Text(
                'MUNDIAL 2026',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (_subtitle != null) ...[
                const SizedBox(width: 16),
                Text(
                  _subtitle!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (isDesktop && name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Minha conta',
                onPressed: () => context.go('/profile'),
                icon: AvatarImage(
                  url: avatarUrl,
                  size: 36,
                  fallbackLetter: avatarInitial,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold sem AppBar — o header fica no shell.
class ShellPage extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const ShellPage({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      resizeToAvoidBottomInset: true,
      floatingActionButton: floatingActionButton,
    );
  }
}
