import 'dart:convert';
import 'dart:io';

void main() {
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('Assets directory not found');
    return;
  }

  assetsDir.listSync(recursive: false).forEach((file) {
    if (file is File && file.path.endsWith('.json')) {
      print('Processing ${file.path}...');
      fixFile(file);
    }
  });
}

void fixFile(File file) {
  try {
    final content = file.readAsStringSync();
    if (content.startsWith('<!DOCTYPE html>')) {
      return;
    }

    final json = jsonDecode(content) as Map<String, dynamic>;

    bool changed = false;
    if (json.containsKey('components')) {
      changed = fixComponents(json['components'] as List);
    }

    if (changed) {
      file.writeAsStringSync(jsonEncode(json));
      print('  Fixed ${file.path}');
    } else {
      print('  No changes needed for ${file.path}');
    }
  } catch (e) {
    print('  Error processing ${file.path}: $e');
  }
}

bool fixComponents(List components) {
  bool anyChanged = false;
  for (final comp in components) {
    if (comp is! Map<String, dynamic>) continue;

    final int oldType = comp['type'] ?? -1;
    final String name = (comp['name'] ?? "").toString().toLowerCase();
    final List inputs = comp['inputs'] ?? [];
    final List outputs = comp['outputs'] ?? [];

    int newType = oldType;

    // ONLY apply heuristics to components that might be misindexed (>=12)
    // Indices 0-11 are stable primitive gates/leds/etc.
    if (oldType >= 12 || oldType == -1) {
      // Highest priority: Structural features that never change
      if (comp.containsKey('text')) {
        newType = 15; // Markdown
      } else if (comp.containsKey('internalComponents')) {
        newType = 16; // IC
      }
      // Oscillator (7) - Higher priority than Input because of collision
      if (comp.containsKey('frequency')) {
        newType = 7;
      }
      // Inputs (12)
      else if (inputs.isEmpty &&
          outputs.length == 1 &&
          (oldType == 12 ||
              oldType == 14 ||
              name.contains('input') ||
              name.contains('fan'))) {
        newType = 12;
      }
      // Outputs (13)
      else if (inputs.length == 1 &&
          outputs.isEmpty &&
          (oldType == 13 ||
              oldType == 15 ||
              name.contains('output') ||
              name.contains('fan'))) {
        newType = 13;
      }
      // Sequential Components (17-19)
      else if (comp.containsKey('storedValue') ||
          name.contains('type') ||
          name.contains('flip flop')) {
        if (inputs.length <= 2) {
          newType = 17; // D type
        } else if (inputs.length >= 3) {
          bool hasJK = inputs.any(
            (p) => (p['label'] ?? "").toString().toUpperCase().contains('J'),
          );
          if (hasJK) {
            newType = 18;
          } else {
            newType = 19;
          }
        }
      }
      // Button (14)
      else if (name.contains('button') ||
          (oldType == 14 && inputs.isEmpty && outputs.isEmpty)) {
        newType = 14;
      }
    }

    if (newType != oldType) {
      comp['type'] = newType;
      anyChanged = true;
    }

    // Recurse
    // if (comp.containsKey('blueprint')) {
    //   final blueprint = comp['blueprint'] as Map<String, dynamic>;
    //   if (blueprint.containsKey('components')) {
    //     if (fixComponents(blueprint['components'] as List)) {
    //       anyChanged = true;
    //     }
    //   }
    // }

    if (comp.containsKey('internalComponents')) {
      if (fixComponents(comp['internalComponents'] as List)) {
        anyChanged = true;
      }
    }
  }
  return anyChanged;
}
