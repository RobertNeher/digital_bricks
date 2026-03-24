import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<PlatformFile?> pickFile() async {
    String? initialDir = await getAssetsDirectory();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: initialDir,
    );
    return result?.files.single;
  }

  static Future<String?> saveFile(String content, String fileName) async {
    String? initialDir = await getAssetsDirectory();
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Circuit As',
        fileName: fileName,
        initialDirectory: initialDir,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        // Ensure extension is present
        if (!outputFile.toLowerCase().endsWith('.json')) {
          outputFile += '.json';
        }
        await File(outputFile).writeAsString(content);
        return outputFile;
      }
    } catch (e) {
      // Suppress print
      // Fallback: try without initialDirectory
      try {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Circuit As',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (outputFile != null) {
          if (!outputFile.toLowerCase().endsWith('.json')) {
            outputFile += '.json';
          }
          await File(outputFile).writeAsString(content);
          return outputFile;
        }
      } catch (e2) {
        // Suppress print
      }
    }
    return null;
  }

  static Future<void> saveFileToPath(String path, String content) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsString(content, flush: true);
    } catch (e) {
      // Suppress print
    }
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.path != null) {
      return await File(file.path!).readAsString();
    }
    return "";
  }

  static Future<String> readFileFromPath(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return "";
  }

  static Future<List<String>> listFiles(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      try {
        final entities = await dir.list().toList();
        return entities.map((e) => e.path).toList();
      } catch (e) {
        // Suppress print
      }
    }
    return [];
  }

  static Future<String?> getAssetsDirectory() async {
    final path = "${Directory.current.path}${Platform.pathSeparator}assets";
    final dir = Directory(path);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        return null; // Can't validly return a path if we can't create it
      }
    }
    return path;
  }

  static String get pathSeparator => Platform.pathSeparator;
}
