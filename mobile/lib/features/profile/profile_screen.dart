import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/avatar_image.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class ProfileScreen extends StatefulWidget {
  final SessionController session;

  const ProfileScreen({super.key, required this.session});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _me;
  bool _loading = true;
  String? _error;
  int _totalPoints = 0;
  int _predictions = 0;
  int _exactHits = 0;
  int? _rankPosition;

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
      final me = await widget.session.auth.me();
      final history = await widget.session.history.getMyHistory();
      final ranking = await widget.session.ranking.getRanking();

      final userId = (me['user'] as Map)['id'];
      var position = 0;
      for (var i = 0; i < ranking.length; i++) {
        if ((ranking[i] as Map)['user_id'] == userId) {
          position = i + 1;
          break;
        }
      }

      final items = history['data'] as List<dynamic>? ?? [];
      var exact = 0;
      for (final item in items) {
        final m = (item as Map).cast<String, dynamic>();
        final pts = m['points'] as int? ?? 0;
        if (pts >= 2) exact++;
      }

      setState(() {
        _me = (me['user'] as Map).cast<String, dynamic>();
        _totalPoints = history['total_points'] as int? ?? 0;
        _predictions = items.length;
        _exactHits = exact;
        _rankPosition = position > 0 ? position : null;
      });
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar perfil.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) showSnack(context, 'Não foi possível ler a imagem.', error: true);
      return;
    }

    try {
      final user = await widget.session.auth.uploadAvatar(bytes, file.name);
      setState(() => _me = user);
      await widget.session.refresh();
      if (mounted) showSnack(context, 'Foto atualizada.');
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), error: true);
    }
  }

  Future<void> _editProfile() async {
    if (_me == null) return;
    final name = TextEditingController(text: _me!['name'] as String? ?? '');
    final password = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                decoration: const InputDecoration(labelText: 'Nova senha (opcional)'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              try {
                final data = <String, dynamic>{'name': name.text.trim()};
                if (password.text.isNotEmpty) data['password'] = password.text;
                await widget.session.auth.updateProfile(data);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) showSnack(ctx, dioErrorMessage(e), error: true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    name.dispose();
    password.dispose();

    if (saved == true) {
      await widget.session.refresh();
      if (mounted) showSnack(context, 'Perfil atualizado.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatarUrl = _me?['avatar_url'] as String?;
    final displayName = (_me?['name'] as String?) ?? '—';
    final initial = displayName.trim().isEmpty ? '?' : displayName.trim().substring(0, 1);

    return ShellPage(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar perfil',
                                    onPressed: _editProfile,
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Sair',
                                    onPressed: () async => widget.session.logout(),
                                    icon: const Icon(Icons.logout),
                                  ),
                                ],
                              ),
                            ),
                            Glass(
                              blur: 12,
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AvatarImage(
                                            url: avatarUrl,
                                            size: 64,
                                            fallbackLetter: initial,
                                          ),
                                          Positioned(
                                            right: -4,
                                            bottom: -4,
                                            child: Material(
                                              color: scheme.primary,
                                              shape: const CircleBorder(),
                                              child: InkWell(
                                                customBorder: const CircleBorder(),
                                                onTap: _uploadAvatar,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              (_me?['email'] as String?) ?? '—',
                                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: _uploadAvatar,
                                              icon: const Icon(Icons.upload_file, size: 18),
                                              label: const Text('Trocar foto'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if ((_me?['is_admin'] as bool?) ?? false)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: scheme.primaryContainer.withValues(alpha: 0.20),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Glass(
                              blur: 12,
                              borderRadius: BorderRadius.circular(24),
                              child: Row(
                                children: [
                                  Expanded(child: _statTile(theme, 'Pontos', '$_totalPoints', Icons.star)),
                                  Expanded(child: _statTile(theme, 'Palpites', '$_predictions', Icons.sports_soccer)),
                                  Expanded(child: _statTile(theme, 'Placares exatos', '$_exactHits', Icons.check_circle)),
                                  Expanded(
                                    child: _statTile(
                                      theme,
                                      'Posição',
                                      _rankPosition != null ? '#$_rankPosition' : '—',
                                      Icons.leaderboard,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _statTile(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
