import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/flag_image.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminTeamsScreen extends StatefulWidget {
  final SessionController session;

  const AdminTeamsScreen({super.key, required this.session});

  @override
  State<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends State<AdminTeamsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _teams = [];
  final _q = TextEditingController();
  String? _group;

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
      final data = await widget.session.admin.listTeams(
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        group: _group,
      );
      setState(() => _teams = data);
    } catch (e) {
      setState(() => _error = dioErrorMessage(e, fallback: 'Falha ao carregar times.'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editTeam(Map<String, dynamic> team) async {
    final code = TextEditingController(text: team['code'] as String? ?? '');
    final name = TextEditingController(text: team['name'] as String? ?? '');
    final flagUrl = TextEditingController(text: team['flag_url'] as String? ?? '');
    var group = team['group_name'] as String?;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar time'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Código (3 letras)'),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  DropdownButtonFormField<String?>(
                    value: group,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ...List.generate(12, (i) {
                        final g = String.fromCharCode(65 + i);
                        return DropdownMenuItem(value: g, child: Text('Grupo $g'));
                      }),
                    ],
                    onChanged: (v) => setLocal(() => group = v),
                  ),
                  TextField(
                    controller: flagUrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da bandeira (opcional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.session.admin.updateTeam(team['id'] as int, {
                    'code': code.text.trim().toUpperCase(),
                    'name': name.text.trim(),
                    'group_name': group,
                    'flag_url': flagUrl.text.trim().isEmpty ? null : flagUrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, dioErrorMessage(e), error: true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    code.dispose();
    name.dispose();
    flagUrl.dispose();
    if (saved == true) {
      if (mounted) showSnack(context, 'Time atualizado.');
      await _load();
    }
  }

  Future<void> _uploadFlag(Map<String, dynamic> team) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) showSnack(context, 'Não foi possível ler o arquivo.', error: true);
      return;
    }

    try {
      await widget.session.admin.uploadTeamFlag(
        team['id'] as int,
        bytes,
        file.name,
      );
      if (mounted) showSnack(context, 'Bandeira enviada.');
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

    return ShellPage(
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _q,
                              decoration: const InputDecoration(
                                labelText: 'Buscar time ou código',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _load(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(onPressed: _load, child: const Text('Buscar')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _group,
                        decoration: const InputDecoration(labelText: 'Grupo'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ...List.generate(12, (i) {
                            final g = String.fromCharCode(65 + i);
                            return DropdownMenuItem(value: g, child: Text('Grupo $g'));
                          }),
                        ],
                        onChanged: (v) => setState(() => _group = v),
                      ),
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
                                itemCount: _teams.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                                ),
                                itemBuilder: (context, index) {
                                  final t = (_teams[index] as Map).cast<String, dynamic>();
                                  final flag = t['flag_url'] as String?;
                                  return ListTile(
                                    leading: flag != null && flag.isNotEmpty
                                        ? FlagImage(url: flag, size: 36)
                                        : _placeholder(scheme, t),
                                    title: Text(t['name'] as String),
                                    subtitle: Text(
                                      [
                                        t['code'] as String?,
                                        if (t['group_name'] != null) 'Grupo ${t['group_name']}',
                                      ].whereType<String>().join(' • '),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Upload bandeira',
                                          icon: const Icon(Icons.upload_file),
                                          onPressed: () => _uploadFlag(t),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _editTeam(t),
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

  Widget _placeholder(ColorScheme scheme, Map<String, dynamic> t) {
    return Container(
      width: 40,
      height: 28,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        (t['code'] as String? ?? '?').substring(0, 1),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
