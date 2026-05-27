import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/session_controller.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminResetScreen extends StatefulWidget {
  final SessionController session;

  const AdminResetScreen({super.key, required this.session});

  @override
  State<AdminResetScreen> createState() => _AdminResetScreenState();
}

class _AdminResetScreenState extends State<AdminResetScreen> {
  bool _busy = false;

  Future<void> _runReset(String scope, String title, String body) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(body),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Digite RESET para confirmar',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().toUpperCase() != 'RESET') return;
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final data = await widget.session.admin.resetBolao(scope: scope);
      final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concluído: ${stats.entries.map((e) => '${e.key}=${e.value}').join(', ')}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: _busy ? null : () => context.go('/admin'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          'Reset do bolão',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Operações irreversíveis. Use para recomeçar palpites, placares ou a tabela de jogos.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  if (_busy) const LinearProgressIndicator(),
                  ListTile(
                    leading: Icon(Icons.restart_alt, color: scheme.error),
                    title: const Text('Limpar palpites e placares'),
                    subtitle: const Text('Remove todos os palpites e volta os jogos para “agendado”, sem placar'),
                    enabled: !_busy,
                    onTap: () => _runReset(
                      'game',
                      'Limpar palpites e placares?',
                      'Todos os palpites serão apagados e os placares oficiais zerados. O ranking volta a zero.',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: scheme.error),
                    title: const Text('Apagar jogos, times e palpites'),
                    subtitle: const Text('Remove a tabela inteira; usuários e regras permanecem'),
                    enabled: !_busy,
                    onTap: () => _runReset(
                      'bolao',
                      'Apagar dados do bolão?',
                      'Palpites, jogos e times serão removidos. Depois rode o import de jogos novamente.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para recriar o banco inteiro (migrate:fresh), use no servidor: php artisan bolao:reset database --force',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
