import 'package:flutter/material.dart';

import '../api/api_client.dart';

/// Avatar de usuário — mesma implementação usada no ranking e no hall.
class UserAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final String fallbackLetter;

  const UserAvatar({
    super.key,
    required this.url,
    this.size = 64,
    this.fallbackLetter = '?',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = ApiClient.resolveMediaUrl(url);
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
