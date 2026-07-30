import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Implementación para plataformas nativas (Android, iOS nativo, Windows, macOS, Linux)
Future<String?> pickImageCrossPlatform() async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
  } catch (e) {
    debugPrint('Error al seleccionar imagen nativa: $e');
  }
  return null;
}
