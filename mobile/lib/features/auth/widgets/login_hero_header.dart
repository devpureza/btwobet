import 'package:flutter/material.dart';

/// Arte opcional da tela de login.
///
/// Substitua ou adicione o arquivo em [assetPath] (PNG recomendado, ~800×400,
/// fundo transparente). Ex.: ilustração festiva da Copa — evite personagens
/// licenciados sem autorização.
const String kLoginHeroAssetPath = 'assets/images/login_hero.png';

/// Hero acima do formulário de login. Altura máxima ~200px, [BoxFit.contain].
class LoginHeroHeader extends StatelessWidget {
  const LoginHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).width >= 600 ? 220.0 : 200.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            kLoginHeroAssetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => _LoginHeroFallback(
              scheme: scheme,
              theme: theme,
              maxHeight: maxHeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeroFallback extends StatelessWidget {
  final ColorScheme scheme;
  final ThemeData theme;
  final double maxHeight;

  const _LoginHeroFallback({
    required this.scheme,
    required this.theme,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight.clamp(180, 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.secondary.withValues(alpha: 0.35),
              scheme.primaryContainer.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(color: scheme.secondary.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 4),
              Text(
                'Troféu na mão, palpite no coração',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.88),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
