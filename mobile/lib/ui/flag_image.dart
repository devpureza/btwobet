import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FlagImage extends StatelessWidget {
  final String? url;
  final double size;

  const FlagImage({super.key, required this.url, this.size = 56});

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

    if (resolved == null || resolved.isEmpty) {
      return _frame(
        scheme,
        Container(color: scheme.surfaceContainerHighest),
      );
    }

    if (kIsWeb) {
      return _frame(
        scheme,
        Image.network(
          resolved,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: scheme.surfaceContainerHighest);
          },
        ),
      );
    }

    return _frame(
      scheme,
      Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: scheme.surfaceContainerHighest);
        },
      ),
    );
  }

  Widget _frame(ColorScheme scheme, Widget child) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surfaceContainerHigh, width: 4),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
