import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminUsersScreen extends StatefulWidget {
  final SessionController session;

  const AdminUsersScreen({super.key, required this.session});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.session.admin.listUsers(
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
      );
      setState(() => _users = data);
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar participantes.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? user}) async {
    final isEdit = user != null;
    final name = TextEditingController(text: user?['name'] as String? ?? '');
    final email = TextEditingController(text: user?['email'] as String? ?? '');
    final password = TextEditingController();
    final avatar = TextEditingController(text: user?['avatar_url'] as String? ?? '');
    var isAdmin = (user?['is_admin'] as bool?) ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isEdit ? 'Editar participante' : 'Novo participante'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isEdit || widget.session.user?['id'] != user['id'],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Nova senha (opcional)' : 'Senha',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avatar,
                    decoration: const InputDecoration(
                      labelText: 'URL da foto (opcional)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Administrador'),
                    value: isAdmin,
                    onChanged: (v) => setLocal(() => isAdmin = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
                  showSnack(ctx, 'Nome e email são obrigatórios.', error: true);
                  return;
                }
                if (!isEdit && password.text.length < 8) {
                  showSnack(ctx, 'Senha deve ter pelo menos 8 caracteres.', error: true);
                  return;
                }
                try {
                  final payload = <String, dynamic>{
                    'name': name.text.trim(),
                    'email': email.text.trim(),
                    'is_admin': isAdmin,
                    'avatar_url': avatar.text.trim().isEmpty ? null : avatar.text.trim(),
                  };
                  if (password.text.isNotEmpty) payload['password'] = password.text;
                  if (isEdit) {
                    await widget.session.admin.updateUser(user['id'] as int, payload);
                  } else {
                    if (password.text.isEmpty) {
                      showSnack(ctx, 'Informe uma senha.', error: true);
                      return;
                    }
                    payload['password'] = password.text;
                    await widget.session.admin.createUser(payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, dioErrorMessage(e), error: true);
                }
              },
              child: Text(isEdit ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    email.dispose();
    password.dispose();
    avatar.dispose();

    if (saved == true) {
      if (mounted) showSnack(context, isEdit ? 'Participante atualizado.' : 'Participante criado.');
      await _load();
      await widget.session.refresh();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover participante'),
        content: Text('Remover ${user['name']} (${user['email']})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await widget.session.admin.deleteUser(user['id'] as int);
      if (mounted) showSnack(context, 'Participante removido.');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), error: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final myId = widget.session.user?['id'];

    return ShellPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Glass(
                  blur: 12,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nome ou email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(onPressed: _load, child: const Text('Buscar')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : Glass(
                              blur: 12,
                              borderRadius: BorderRadius.circular(20),
                              padding: EdgeInsets.zero,
                              child: ListView.separated(
                                itemCount: _users.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                                ),
                                itemBuilder: (context, index) {
                                  final u = (_users[index] as Map).cast<String, dynamic>();
                                  final isAdmin = (u['is_admin'] as bool?) ?? false;
                                  final avatarUrl = u['avatar_url'] as String?;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      backgroundColor: scheme.secondary.withValues(alpha: 0.35),
                                      child: avatarUrl == null || avatarUrl.isEmpty
                                          ? Text((u['name'] as String).substring(0, 1).toUpperCase())
                                          : null,
                                    ),
                                    title: Text(u['name'] as String),
                                    subtitle: Text(u['email'] as String),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAdmin)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: scheme.primaryContainer.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Admin',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: scheme.onPrimaryContainer,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _openForm(user: u),
                                        ),
                                        if (myId != u['id'])
                                          IconButton(
                                            tooltip: 'Remover',
                                            icon: Icon(Icons.delete_outline, color: scheme.error),
                                            onPressed: () => _confirmDelete(u),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
