import 'dart:io';
import 'dart:typed_data';

Future<String?> savePlatformBytes(
  String filename,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  String directoryPath;
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloadsDir = Directory('$userProfile\\Downloads');
      if (downloadsDir.existsSync()) {
        directoryPath = downloadsDir.path;
      } else {
        directoryPath = Directory.current.path;
      }
    } else {
      directoryPath = Directory.current.path;
    }
    final fullPath = '$directoryPath\\$filename';
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    return fullPath;
  } else if (Platform.isAndroid || Platform.isIOS) {
    final tempDir = Directory.systemTemp;
    final fullPath = '${tempDir.path}/$filename';
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    return fullPath;
  } else {
    directoryPath = Directory.current.path;
    final fullPath = '$directoryPath/$filename';
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    return fullPath;
  }
}

bool checkFileExists(String filePath) {
  try {
    return File(filePath).existsSync();
  } catch (_) {
    return false;
  }
}
