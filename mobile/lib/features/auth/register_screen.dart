import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/session_controller.dart';
import '../../ui/glass.dart';

class RegisterScreen extends StatefulWidget {
  final SessionController session;

  const RegisterScreen({super.key, required this.session});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }

      final message = await widget.session.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _passwordConfirmation.text,
      );

      if (!mounted) return;
      setState(() => _success = message);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['message']?.toString();
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          }
        }
      }
      setState(() {
        if (status == 422) {
          _error = msg ?? 'Verifique os dados informados.';
        } else if (status != null) {
          _error = msg ?? 'Erro do servidor ($status).';
        } else {
          _error = 'Sem conexão com o servidor. Verifique sua internet.';
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: StadiumGradient(child: SizedBox())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CRIAR CONTA',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preencha seus dados. Um administrador precisa aprovar seu cadastro antes do primeiro acesso.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.92),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Glass(
                          blur: 20,
                          borderRadius: BorderRadius.circular(24),
                          padding: const EdgeInsets.all(20),
                          child: _success != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Icon(Icons.hourglass_top, size: 48, color: scheme.primary),
                                    const SizedBox(height: 16),
                                    Text(
                                      _success!,
                                      style: theme.textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Quando for aprovado, volte aqui e faça login.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton(
                                      onPressed: () => context.go('/login'),
                                      child: const Text('Ir para o login'),
                                    ),
                                  ],
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_error != null) ...[
                                        Text(_error!, style: TextStyle(color: scheme.error)),
                                        const SizedBox(height: 12),
                                      ],
                                      TextFormField(
                                        controller: _name,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: const InputDecoration(labelText: 'Nome'),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _email,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(labelText: 'Email'),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Informe o email';
                                          }
                                          if (!v.contains('@')) return 'Email inválido';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _password,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Senha'),
                                        validator: (v) {
                                          if (v == null || v.length < 8) {
                                            return 'Mínimo de 8 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordConfirmation,
                                        obscureText: true,
                                        decoration: const InputDecoration(labelText: 'Confirmar senha'),
                                        validator: (v) {
                                          if (v != _password.text) {
                                            return 'As senhas não coincidem';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed: _loading ? null : _submit,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Enviar cadastro'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _loading ? null : () => context.go('/login'),
                                        child: const Text('Já tenho conta'),
                                      ),
                                    ],
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
        ],
      ),
    );
  }
}
