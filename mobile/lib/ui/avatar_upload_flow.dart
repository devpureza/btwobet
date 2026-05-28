import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

typedef AvatarUploadResult = ({List<int> bytes, String filename});

/// Escolhe imagem, recorta em quadrado e comprime para upload de avatar.
Future<AvatarUploadResult?> pickCropAvatarBytes(BuildContext context) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return null;

  final file = picked.files.single;
  final raw = file.bytes;
  if (raw == null || raw.isEmpty) return null;

  if (!context.mounted) return null;
  final cropped = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => _AvatarCropPage(imageBytes: raw)),
  );
  if (cropped == null || cropped.isEmpty) return null;

  final optimized = _optimizeAvatar(cropped);
  final name = file.name;
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
  final filename = 'avatar.${ext == 'png' ? 'png' : 'jpg'}';

  return (bytes: optimized, filename: filename);
}

Uint8List _optimizeAvatar(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final square = img.copyResizeCropSquare(decoded, size: 512);
  return Uint8List.fromList(img.encodeJpg(square, quality: 85));
}

class _AvatarCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const _AvatarCropPage({required this.imageBytes});

  @override
  State<_AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<_AvatarCropPage> {
  final _cropController = CropController();
  var _cropping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar foto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cropping ? null : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Crop(
                controller: _cropController,
                image: widget.imageBytes,
                aspectRatio: 1,
                withCircleUi: true,
                baseColor: theme.colorScheme.surface,
                maskColor: Colors.black.withValues(alpha: 0.55),
                onCropped: (result) {
                  if (!mounted) return;
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      Navigator.pop(context, croppedImage);
                    case CropFailure():
                      setState(() => _cropping = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não foi possível recortar a imagem.')),
                      );
                  }
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _cropping
                      ? null
                      : () {
                          setState(() => _cropping = true);
                          _cropController.cropCircle();
                        },
                  icon: _cropping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_cropping ? 'Processando…' : 'Usar esta foto'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
