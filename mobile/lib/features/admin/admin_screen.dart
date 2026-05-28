import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/session_controller.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminScreen extends StatelessWidget {
  final SessionController session;

  const AdminScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ShellPage(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Glass(
              blur: 12,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CMS Administrativo',
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie participantes, jogos/resultados e times/bandeiras. Tudo fica salvo no banco.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.groups),
                    title: const Text('Participantes'),
                    subtitle: const Text('Adicionar/editar nome, email, senha e foto'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/users'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sports_soccer),
                    title: const Text('Jogos e Resultados'),
                    subtitle: const Text('Horários, locais, grupos e placar final'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/matches'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('Times e Bandeiras'),
                    subtitle: const Text('Grupo do time e upload de bandeira'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/teams'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.rule),
                    title: const Text('Regras de Palpite'),
                    subtitle: const Text('Prazo fase de grupos, mata-mata e bloqueio geral'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/prediction-rules'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Histórico de palpites'),
                    subtitle: const Text('Log de todos os palpites registrados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/predictions'),
                  ),
                  ListTile(
                    leading: Icon(Icons.restart_alt, color: scheme.error),
                    title: const Text('Reset do bolão'),
                    subtitle: const Text('Limpar palpites, placares ou apagar jogos/times'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/reset'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

