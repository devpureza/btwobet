import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class AppTheme {
  AppTheme._();

  static Future<ThemeData> load() async {
    try {
      final raw = await rootBundle.loadString('assets/design/DESIGN.md');
      final yamlString = _extractFrontmatter(raw);
      final doc = loadYaml(yamlString) as YamlMap;
      final colors = (doc['colors'] as YamlMap?) ?? YamlMap();

      final primary = _hexColor(colors['primary'] as String? ?? '#00341c');
      final primaryContainer = _hexColor(colors['primary-container'] as String? ?? '#004d2c');
      final onPrimary = _hexColor(colors['on-primary'] as String? ?? '#ffffff');
      final onPrimaryContainer =
          _hexColor(colors['on-primary-container'] as String? ?? '#7bbd93');

      final secondary = _hexColor(colors['secondary-container'] as String? ?? '#fcd400');
      final onSecondary = _hexColor(colors['on-secondary-container'] as String? ?? '#6e5c00');

      final background = _hexColor(colors['background'] as String? ?? '#f8f9fa');
      final surface = _hexColor(colors['surface'] as String? ?? '#f8f9fa');
      final surfaceHighest =
          _hexColor(colors['surface-container-highest'] as String? ?? '#e1e3e4');
      final outline = _hexColor(colors['outline'] as String? ?? '#707971');
      final outlineVariant = _hexColor(colors['outline-variant'] as String? ?? '#bfc9bf');
      final onSurface = _hexColor(colors['on-surface'] as String? ?? '#191c1d');
      final onSurfaceVariant =
          _hexColor(colors['on-surface-variant'] as String? ?? '#404942');

      final scheme = ColorScheme(
        brightness: Brightness.light,
        primary: primaryContainer,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondary,
        onSecondaryContainer: onSecondary,
        tertiary: _hexColor(colors['tertiary-container'] as String? ?? '#00408a'),
        onTertiary: onPrimary,
        error: _hexColor(colors['error'] as String? ?? '#ba1a1a'),
        onError: onPrimary,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceContainerHighest: surfaceHighest,
        surfaceContainerHigh: _hexColor(colors['surface-container-high'] as String? ?? '#e7e8e9'),
      );

      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        fontFamily: 'Hanken Grotesk',
        appBarTheme: AppBarTheme(
          backgroundColor: surface.withValues(alpha: 0.70),
          foregroundColor: onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        dividerColor: outlineVariant.withValues(alpha: 0.6),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.70),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: outlineVariant.withValues(alpha: 0.30)),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
              inherit: false,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return primaryContainer.withValues(alpha: 0.35);
              }
              return secondary;
            }),
            foregroundColor: WidgetStateProperty.all(onSecondary),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: secondary.withValues(alpha: 0.95), width: 2),
          ),
          labelStyle: TextStyle(color: onSurfaceVariant),
          hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.7)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface.withValues(alpha: 0.70),
          elevation: 0,
          indicatorColor: primaryContainer.withValues(alpha: 0.18),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: onSurfaceVariant, fontFamily: 'Hanken Grotesk'),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800, fontSize: 48),
          headlineLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 32),
          headlineMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 20),
          bodyLarge: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.w400, fontSize: 18),
          bodyMedium: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.w400, fontSize: 16),
          labelSmall: TextStyle(fontFamily: 'Space Mono', fontWeight: FontWeight.w500, fontSize: 12),
        ),
      );
    } catch (_) {
      return _fallbackTheme();
    }
  }

  static ThemeData _fallbackTheme() {
    const primary = Color(0xFF00341C);
    const primaryContainer = Color(0xFF004D2C);
    const secondary = Color(0xFFFCD400);
    const onSecondary = Color(0xFF6E5C00);
    const background = Color(0xFFF8F9FA);
    const surface = Color(0xFFF8F9FA);
    const onSurface = Color(0xFF191C1D);
    const outline = Color(0xFF707971);
    const outlineVariant = Color(0xFFBFC9BF);
    const onPrimary = Color(0xFFFFFFFF);
    const onPrimaryContainer = Color(0xFF7BBD93);
    const onSurfaceVariant = Color(0xFF404942);
    const surfaceHighest = Color(0xFFE1E3E4);

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryContainer,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondary,
      onSecondaryContainer: onSecondary,
      tertiary: Color(0xFF00408A),
      onTertiary: onPrimary,
      error: Color(0xFFBA1A1A),
      onError: onPrimary,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceContainerHighest: surfaceHighest,
      surfaceContainerHigh: Color(0xFFE7E8E9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xB3F8F9FA),
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: onSecondary,
        ),
      ),
    );
  }

  static String _extractFrontmatter(String raw) {
    final lines = raw.split('\n');
    final first = lines.indexWhere((l) => l.trim() == '---');
    if (first == -1) return raw;
    final second = lines.indexWhere((l) => l.trim() == '---', first + 1);
    if (second == -1) return raw;
    return lines.sublist(first + 1, second).join('\n');
  }

  static Color _hexColor(String hex) {
    var clean = hex.trim();
    if (clean.startsWith('#')) clean = clean.substring(1);
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }
}
