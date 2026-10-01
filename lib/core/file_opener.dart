import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Picks one file from the phone (Downloads, WhatsApp documents, Drive),
/// behind an interface so widget tests can hand in a file.
abstract interface class FileOpener {
  /// Null when the person backs out.
  Future<({String name, Uint8List bytes})?> pick(List<String> extensions);
}

class SystemFileOpener implements FileOpener {
  const SystemFileOpener();

  @override
  Future<({String name, Uint8List bytes})?> pick(
    List<String> extensions,
  ) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    return (name: file.name, bytes: await file.readAsBytes());
  }
}
