import 'dart:io';
import 'dart:convert';

void migrateComponent(Map<String, dynamic> comp) {
  if (comp.containsKey('blueprint')) {
    var bp = comp['blueprint'] as Map<String, dynamic>;
    comp['internalComponents'] = bp['components'] ?? [];
    comp['internalConnections'] = bp['connections'] ?? [];
    comp['name'] = bp['name'] ?? comp['name'] ?? 'IC';
    comp.remove('blueprint');
    
    // Recursively migrate nested components
    var internals = comp['internalComponents'] as List;
    for (var child in internals) {
      if (child is Map<String, dynamic>) {
        migrateComponent(child);
      }
    }
  }
}

Future<void> migrateFile(File file) async {
  print('Migrating ${file.path}...');
  try {
    String content = await file.readAsString();
    var data = jsonDecode(content);
    
    if (data is Map<String, dynamic> && data.containsKey('components')) {
      var comps = data['components'] as List;
      for (var comp in comps) {
        if (comp is Map<String, dynamic>) {
          migrateComponent(comp);
        }
      }
    }
    
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
  } catch (e) {
    print('Error migrating ${file.path}: $e');
  }
}

void main() async {
  var assetsDir = Directory(r'c:\Users\Robert\Documents\digital_bricks\assets');
  if (!await assetsDir.exists()) {
    print('Assets directory not found!');
    return;
  }
  
  await for (var entity in assetsDir.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      await migrateFile(entity);
    }
  }
  print('Migration complete.');
}
