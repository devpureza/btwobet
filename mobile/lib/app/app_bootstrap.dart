import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../api/token_store.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'session_controller.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SessionController? _session;
  ThemeData? _theme;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await initializeDateFormatting('pt_BR');
      Intl.defaultLocale = 'pt_BR';

      final theme = await AppTheme.load();
      if (!mounted) return;
      setState(() => _theme = theme);

      const storage = FlutterSecureStorage();
      final tokenStore = TokenStore(storage);
      final session = await SessionController.create(tokenStore);

      if (!mounted) return;
      setState(() {
        _session = session;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('Falha ao iniciar app: $e\n$st');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível iniciar o app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF404942)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _session = null;
                          _theme = null;
                        });
                        _init();
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final session = _session;
    final theme = _theme;
    if (session == null || theme == null) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          backgroundColor: theme?.scaffoldBackgroundColor ?? const Color(0xFF00341C),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme?.colorScheme.secondary ?? const Color(0xFFFCD400),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando Bolão Copa 2026…',
                  style: TextStyle(
                    color: theme?.colorScheme.onPrimary ?? Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final router = AppRouter.create(session);

    return MaterialApp.router(
      title: 'Bolão Copa 2026',
      theme: theme,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
