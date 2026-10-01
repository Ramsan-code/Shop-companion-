import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// A file to hand to the Android share sheet.
class SharedFile {
  const SharedFile(this.bytes, {required this.name, required this.mimeType});

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// The Android share sheet (WhatsApp, Drive, email…), behind an interface so
/// widget tests can see what would be shared.
abstract interface class FileSharer {
  Future<void> share(List<SharedFile> files, {String? text});
}

class SystemFileSharer implements FileSharer {
  const SystemFileSharer();

  @override
  Future<void> share(List<SharedFile> files, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [
          for (final f in files)
            XFile.fromData(f.bytes, name: f.name, mimeType: f.mimeType),
        ],
        fileNameOverrides: [for (final f in files) f.name],
      ),
    );
  }
}
