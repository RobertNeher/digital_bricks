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
      print("Error in FileOpsImpl.saveFile: $e");
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
        print("Fallback Save As failed: $e2");
      }
    }
    return null;
  }

  static Future<void> saveFileToPath(String path, String content) async {
    print("Attempting to save to $path");
    try {
      final file = File(path);
      if (!await file.exists()) {
        await file.create(recursive: true);
        print("Created file at $path");
      }
      await file.writeAsString(content, flush: true);
      print("Successfully wrote ${content.length} bytes to $path");
    } catch (e) {
      print("Failed to write to $path: $e");
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
        print("Error listing files at $path: $e");
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
        // print("Created assets directory at $path");
      } catch (e) {
        // print("Failed to create assets directory: $e");
        return null; // Can't validly return a path if we can't create it
      }
    }
    return path;
  }

  static String get pathSeparator => Platform.pathSeparator;
}
