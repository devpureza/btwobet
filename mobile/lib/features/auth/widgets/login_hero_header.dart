import 'package:flutter/material.dart';

/// Arte da tela de login (Ronaldo + troféu, retrato).
const String kLoginHeroAssetPath = 'assets/images/login_hero.png';

/// Fundo full-screen: imagem em tela cheia + gradientes para legibilidade do texto e do formulário.
class LoginHeroBackground extends StatelessWidget {
  const LoginHeroBackground({super.key});

  /// Alinhamento da imagem em [BoxFit.cover] — rosto e troféu ficam visíveis (evita corte no topo da cabeça).
  static const Alignment imageAlignment = Alignment(0, 0.28);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kLoginHeroAssetPath,
            fit: BoxFit.cover,
            alignment: imageAlignment,
            errorBuilder: (context, error, stackTrace) => _LoginHeroFallback(
              scheme: scheme,
              theme: Theme.of(context),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.72, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  scheme.primary.withValues(alpha: 0.55),
                  scheme.primary.withValues(alpha: 0.78),
                  scheme.primary.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.42),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeroFallback extends StatelessWidget {
  final ColorScheme scheme;
  final ThemeData theme;

  const _LoginHeroFallback({
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.secondary.withValues(alpha: 0.35),
            scheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 40, color: scheme.onPrimary),
                const SizedBox(width: 12),
                Icon(Icons.emoji_events, size: 44, color: scheme.secondary),
                const SizedBox(width: 12),
                Icon(Icons.sports_soccer, size: 40, color: scheme.onPrimary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Copa 2026',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
