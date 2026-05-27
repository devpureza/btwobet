import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/session_controller.dart';
import '../../ui/glass.dart';

class LoginScreen extends StatefulWidget {
  final SessionController session;

  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
      await widget.session.login(_email.text.trim(), _password.text);
      if (!widget.session.isLoggedIn) {
        throw StateError('Sessão não foi salva. Tente novamente ou use outro navegador.');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      setState(() {
        if (status == 401) {
          _error = msg ?? 'Email ou senha incorretos.';
        } else if (status == 403) {
          _error = msg ?? 'Acesso não liberado.';
        } else if (status == 419) {
          _error = 'Sessão expirada no servidor. Atualize a página (Ctrl+Shift+R) e tente de novo.';
        } else if (status != null) {
          _error = msg ?? 'Erro do servidor ($status).';
        } else {
          _error = 'Sem conexão com o servidor. Verifique sua internet.';
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('StateError: ', '');
      });
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
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'A CONTAGEM REGRESSIVA COMEÇOU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BOLÃO MUNDIAL 2026',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: scheme.onPrimary,
                          shadows: [
                            Shadow(
                              blurRadius: 18,
                              color: Colors.black.withValues(alpha: 0.35),
                            )
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sinta a adrenalina de cada gol. Desafie seus amigos e suba no ranking.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.92)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Glass(
                        blur: 20,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null) ...[
                                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (v) => (v == null || v.isEmpty) ? 'Informe o email' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Senha'),
                                validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
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
                                    : const Text('Participar Agora'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use seu email e senha para entrar.',
                                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _loading ? null : () => context.go('/register'),
                                child: const Text('Ainda não tenho conta'),
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
