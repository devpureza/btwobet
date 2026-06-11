import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/session_controller.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';
import '../../utils/download_file/download_file.dart';

class AdminScreen extends StatefulWidget {
  final SessionController session;

  const AdminScreen({super.key, required this.session});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _syncingScores = false;

  Future<void> _syncScores() async {
    if (_syncingScores) return;

    setState(() => _syncingScores = true);
    try {
      final payload = await widget.session.admin.syncWorldCupScores();
      final stats = (payload['data'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Placares sincronizados: ${stats['matched'] ?? 0} casados, '
            '${stats['updated'] ?? 0} atualizados, ${stats['finished'] ?? 0} finalizados.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao sincronizar placares (GE): $e')),
      );
    } finally {
      if (mounted) setState(() => _syncingScores = false);
    }
  }

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
                    leading: const Icon(Icons.download),
                    title: const Text('Exportar palpites'),
                    subtitle: const Text('Baixar CSV para planilha'),
                    onTap: () async {
                      try {
                        final payload = await widget.session.admin.exportPredictions(format: 'csv');
                        final filename = payload.filename ?? 'palpites.csv';
                        downloadFile(bytes: payload.bytes, filename: filename, mimeType: payload.mimeType);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Download iniciado: $filename')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Falha ao exportar palpites: $e')),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: _syncingScores
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                          )
                        : const Icon(Icons.sync),
                    title: const Text('Sincronizar placares (GE)'),
                    subtitle: const Text('Buscar placares atuais no ge.globo'),
                    enabled: !_syncingScores,
                    onTap: _syncingScores ? null : _syncScores,
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
