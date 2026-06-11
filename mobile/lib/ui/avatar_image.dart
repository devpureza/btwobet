import 'package:flutter/material.dart';

import 'user_avatar.dart';

/// Mantido por compatibilidade — prefira [UserAvatar].
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

  @override
  Widget build(BuildContext context) {
    return UserAvatar(url: url, size: size, fallbackLetter: fallbackLetter);
  }
}
