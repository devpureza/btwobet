import 'package:flutter/material.dart';

/// Arte opcional da tela de login (ex.: ilustração festiva da Copa).
const String kLoginHeroAssetPath = 'assets/images/login_hero.png';

/// Faixa hero no topo da tela — imagem ampla com opacidade e gradiente para legibilidade.
class LoginHeroBackground extends StatelessWidget {
  const LoginHeroBackground({super.key});

  static double heroHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fraction = size.width >= 600 ? 0.42 : 0.48;
    return (size.height * fraction).clamp(220.0, 420.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = heroHeight(context);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.42,
            child: Image.asset(
              kLoginHeroAssetPath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => _LoginHeroFallback(
                scheme: scheme,
                theme: theme,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  scheme.primary.withValues(alpha: 0.35),
                  scheme.primary.withValues(alpha: 0.92),
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
