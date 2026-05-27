import 'dart:ui';

import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? color;
  final BorderSide? border;
  final List<BoxShadow>? boxShadow;

  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(16),
    this.blur = 12,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outlineVariant = scheme.outlineVariant.withValues(alpha: 0.30);
    final surface = scheme.surface;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? surface.withValues(alpha: 0.70),
            borderRadius: borderRadius,
            border: Border.fromBorderSide(border ?? BorderSide(color: outlineVariant)),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class StadiumGradient extends StatelessWidget {
  final Widget child;
  final String? imageUrl;
  final String? assetPath;

  const StadiumGradient({
    super.key,
    required this.child,
    this.imageUrl,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = scheme.primary.withValues(alpha: 0.85);
    final bottom = scheme.primary.withValues(alpha: 0.20);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (assetPath != null && assetPath!.isNotEmpty)
          Image.asset(
            assetPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          )
        else if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class ScoreBox extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const ScoreBox({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 64,
      height: 64,
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: scheme.secondary.withValues(alpha: 0.30),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

