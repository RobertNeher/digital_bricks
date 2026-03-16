import 'package:file_picker/file_picker.dart';

import 'file_ops_io.dart' if (dart.library.html) 'file_ops_web.dart';

abstract class FileOps {
  static Future<String?> saveFile(String content, String fileName) =>
      FileOpsImpl.saveFile(content, fileName);
  static Future<void> saveFileToPath(String path, String content) =>
      FileOpsImpl.saveFileToPath(path, content);
  static Future<String> readFile(PlatformFile file) =>
      FileOpsImpl.readFile(file);
  static Future<String> readFileFromPath(String path) =>
      FileOpsImpl.readFileFromPath(path);
  static Future<PlatformFile?> pickFile() => FileOpsImpl.pickFile();
  static Future<List<String>> listFiles(String path) =>
      FileOpsImpl.listFiles(path);
  static Future<String?> getAssetsDirectory() =>
      FileOpsImpl.getAssetsDirectory();
  static String get pathSeparator => FileOpsImpl.pathSeparator;
}
