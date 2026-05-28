import 'package:flutter/material.dart';

import '../app/session_controller.dart';
import 'admin_helpers.dart';
import 'avatar_upload_flow.dart';

/// Pede foto no primeiro acesso se o usuário ainda não tiver avatar.
class AvatarPromptHost extends StatefulWidget {
  final SessionController session;
  final Widget child;

  const AvatarPromptHost({
    super.key,
    required this.session,
    required this.child,
  });

  @override
  State<AvatarPromptHost> createState() => _AvatarPromptHostState();
}

class _AvatarPromptHostState extends State<AvatarPromptHost> {
  var _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  bool _hasAvatar(Map<String, dynamic>? user) {
    final url = user?['avatar_url'] as String?;
    return url != null && url.trim().isNotEmpty;
  }

  Future<void> _maybePrompt() async {
    if (_checked || !mounted) return;
    _checked = true;

    if (!widget.session.isLoggedIn || _hasAvatar(widget.session.user)) return;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _hasAvatar(widget.session.user)) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto de perfil'),
        content: const Text(
          'Adicione uma foto para aparecer no ranking e facilitar '
          'quem te reconhece no bolão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _uploadAvatar();
            },
            child: const Text('Escolher foto'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAvatar() async {
    final picked = await pickCropAvatarBytes(context);
    if (picked == null || !mounted) return;

    try {
      await widget.session.auth.uploadAvatar(picked.bytes, picked.filename);
      await widget.session.refresh();
      if (mounted) showSnack(context, 'Foto adicionada.');
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
