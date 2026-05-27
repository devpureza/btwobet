import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/session_controller.dart';
import '../../ui/admin_helpers.dart';
import '../../ui/glass.dart';
import '../../ui/shell_header.dart';

class AdminPredictionRulesScreen extends StatefulWidget {
  final SessionController session;

  const AdminPredictionRulesScreen({super.key, required this.session});

  @override
  State<AdminPredictionRulesScreen> createState() => _AdminPredictionRulesScreenState();
}

class _AdminPredictionRulesScreenState extends State<AdminPredictionRulesScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '24');
  bool _lockAll = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.session.admin.getPredictionRules();
      final deadline = DateTime.parse(data['group_deadline'] as String).toLocal();
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(deadline);
      _timeCtrl.text = DateFormat('HH:mm').format(deadline);
      _hoursCtrl.text = '${data['knockout_hours_before']}';
      _lockAll = (data['lock_all'] as bool?) ?? false;
    } catch (e) {
      _error = dioErrorMessage(e, fallback: 'Falha ao carregar regras.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dateParts = _dateCtrl.text.trim().split('-');
      final timeParts = _timeCtrl.text.trim().split(':');
      if (dateParts.length != 3 || timeParts.length < 2) {
        showSnack(context, 'Data ou hora inválida.', error: true);
        return;
      }
      final dt = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 24;

      await widget.session.admin.updatePredictionRules({
        'group_deadline': dt.toUtc().toIso8601String(),
        'knockout_hours_before': hours,
        'lock_all': _lockAll,
      });

      if (mounted) showSnack(context, 'Regras salvas.');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Glass(
                        blur: 12,
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Regras de Palpite',
                              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fase de grupos: prazo único configurável. Mata-mata: fecha X horas antes de cada jogo. Palpite salvo não pode ser alterado.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 20),
                            Text('Fase de grupos — prazo final', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _dateCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Data (AAAA-MM-DD)',
                                      hintText: '2026-06-11',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _timeCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Hora (HH:MM)',
                                      hintText: '23:59',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _hoursCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mata-mata — horas antes do jogo',
                                helperText: 'Ex.: 24 = palpite até 24h antes do apito inicial',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Bloquear todos os palpites'),
                              subtitle: const Text('Trava emergencial — ignora prazos acima'),
                              value: _lockAll,
                              onChanged: (v) => setState(() => _lockAll = v),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Salvar regras'),
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
}
