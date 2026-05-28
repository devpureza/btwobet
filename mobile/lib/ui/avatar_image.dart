import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AvatarImage extends StatelessWidget {
  final String? url;
  final double size;
  final String fallbackLetter;

  const AvatarImage({
    super.key,
    required this.url,
    this.size = 64,
    this.fallbackLetter = '?',
  });

  String? _resolveUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('/')) {
      return kIsWeb ? '${Uri.base.origin}$raw' : raw;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = url == null || url!.isEmpty ? null : _resolveUrl(url!);
    final letter = fallbackLetter.trim().isEmpty
        ? '?'
        : fallbackLetter.trim().substring(0, 1).toUpperCase();

    if (resolved == null || resolved.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.secondary.withValues(alpha: 0.45),
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolved,
          key: ValueKey(resolved),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: scheme.secondary.withValues(alpha: 0.45),
              child: Text(
                letter,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
      ),
    );
  }
}
