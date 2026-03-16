// ignore_for_file: uri_does_not_exist
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:file_picker/file_picker.dart';

class FileOpsImpl {
  static Future<PlatformFile?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    return result?.files.single;
  }

  static Future<String?> saveFile(String content, String fileName) async {
    // 1. Try File System Access API (Modern browsers, Secure Context)
    try {
      if (js_util.hasProperty(html.window, 'showSaveFilePicker')) {
        final options = js_util.jsify({
          'suggestedName': fileName,
          'types': [
            {
              'description': 'JSON Circuit File',
              'accept': {
                'application/json': ['.json']
              }
            }
          ]
        });

        final handle = await js_util.promiseToFuture(
          js_util.callMethod(html.window, 'showSaveFilePicker', [options]),
        );

        final writable = await js_util.promiseToFuture(
          js_util.callMethod(handle, 'createWritable', []),
        );

        await js_util.promiseToFuture(
          js_util.callMethod(writable, 'write', [content]),
        );

        await js_util.promiseToFuture(
          js_util.callMethod(writable, 'close', []),
        );

        return js_util.hasProperty(handle, 'name')
            ? js_util.getProperty(handle, 'name')
            : fileName;
      }
    } catch (e) {
      print("File System Access API failed or cancelled: $e");
      if (e.toString().contains('AbortError') || e.toString().contains('User cancelled')) {
        return null; // User explicitly cancelled
      }
    }

    // 2. Fallback to direct download
    return _doDownload(content, fileName);
  }

  static Future<String?> _doDownload(String content, String fileName) async {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  static Future<void> saveFileToPath(String path, String content) async {
    // For web "save to path", we just download the file with the filename part of the path.
    // We cannot write to a specific directory on the user's machine.
    final fileName = path.split(pathSeparator).last;
    await _doDownload(content, fileName);
  }

  static Future<String> readFile(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    return "";
  }

  static Future<String> readFileFromPath(String path) async {
    // Cannot read from arbitrary path on web without user interaction (picker).
    // If this is for initial load (blueprints.json), we might return empty
    // or rely on previous LocalStorage if that was a requirement, but
    // the instruction says "move back entire persistence layer... to download folder".
    // This implies we don't have automatic persistence reading from that folder.
    return "";
  }

  static Future<List<String>> listFiles(String path) async {
    // Web cannot list files from user system
    return [];
  }

  static Future<String?> getAssetsDirectory() async {
    // No assets directory access on web in this mode.
    return null;
  }

  static String get pathSeparator => '/';
}
