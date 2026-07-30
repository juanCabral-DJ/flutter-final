import 'dart:async';
import 'dart:html' as html;

/// Implementación para plataforma Web (Navegadores, PWA iOS/Android)
/// Utiliza HTML5 FileUploadInputElement nativo sin depender de canales de plugins nativos.
Future<String?> pickImageCrossPlatform() async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as String?);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
