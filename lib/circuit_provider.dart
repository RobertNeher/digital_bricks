import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'models/logic_component.dart';
import 'models/markdown_component.dart';
import 'models/gates.dart';
import 'models/io_devices.dart';
import 'models/connection.dart';
import 'models/pin.dart';
import 'models/circuit_io.dart';
import 'models/integrated_circuit.dart';
import 'models/sequential.dart';
import 'utils/file_ops.dart';

extension OffsetToVec2 on Offset {
  Vec2 toVec2() => Vec2(dx, dy);
}

extension Vec2ToOffset on Vec2 {
  Offset toOffset() => Offset(dx, dy);
}

/// Helper class to manage the undo/redo stack using JSON snapshots.
class CircuitHistory {
  final List<String> undoStack = [];
  final List<String> redoStack = [];
  final int maxSteps = 50;

  void push(String snapshot) {
    if (undoStack.isNotEmpty && undoStack.last == snapshot) return;
    undoStack.add(snapshot);
    if (undoStack.length > maxSteps) {
      undoStack.removeAt(0);
    }
    redoStack.clear();
  }

  String? undo(String currentSnapshot) {
    if (undoStack.isEmpty) return null;
    redoStack.add(currentSnapshot);
    return undoStack.removeLast();
  }

  String? redo(String currentSnapshot) {
    if (redoStack.isEmpty) return null;
    undoStack.add(currentSnapshot);
    return redoStack.removeLast();
  }

  void clear() {
    undoStack.clear();
    redoStack.clear();
  }
}

class CircuitProvider extends ChangeNotifier {
  List<LogicComponent> components = [];
  List<Connection> connections = [];
  // ignore: unused_field
  Timer? _simulationTimer;
  String circuitSessionId = const Uuid().v4();
  String? currentFilePath;
  String get pathSeparator => FileOps.pathSeparator;

  final CircuitHistory _history = CircuitHistory();
  bool _isApplyingHistory = false;

  bool get canUndo => _history.undoStack.isNotEmpty;
  bool get canRedo => _history.redoStack.isNotEmpty;

  String? _clipboard;
  bool get canPaste => _clipboard != null;

  bool get hasUnpackedComponents =>
      components.any((c) => c is IntegratedCircuit && c.isUnpacked);

  // Callback to get current viewport center from UI
  Offset Function()? getViewportCenter;

  // Simulation constants
  // Simulation constants
  static const int _tickRateMs = 50; // 20Hz update rate for UI/Sim
  static const double gridSize = 20.0;

  CircuitProvider() {
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(Duration(milliseconds: _tickRateMs), (
      timer,
    ) {
      _tick();
    });
  }

  void _tick() {
    // 1. Update Oscillators
    final now = DateTime.now().millisecondsSinceEpoch;
    bool needsUpdate = false;

    for (var comp in components) {
      if (comp is Oscillator) {
        int periodMs = (1000 / comp.frequency).round();
        if (periodMs == 0) periodMs = 1;
        bool newState = (now % periodMs) < (periodMs / 2);

        bool oldVal = comp.outputs[0].value;
        comp.outputs[0].value = newState;
        if (oldVal != newState) needsUpdate = true;
      }
    }

    // 2. Propagate
    for (int i = 0; i < 5; i++) {
      bool changed = _propagateValues();
      if (changed) needsUpdate = true;
    }

    if (needsUpdate) {
      notifyListeners();
    }
  }

  bool _propagateValues() {
    bool anyChange = false;

    // Transfer values from Outputs to Inputs via Connections
    for (var conn in connections) {
      var sourcePin = _findPin(conn.sourcePinId);
      var targetPin = _findPin(conn.targetPinId);

      if (sourcePin != null && targetPin != null) {
        if (targetPin.value != sourcePin.value) {
          targetPin.value = sourcePin.value;
          anyChange = true;
        }
      }
    }

    // Evaluate Components
    for (var comp in components) {
      if (comp is! Oscillator && comp is! ConstantSource) {
        List<bool> oldOutputs = comp.outputs.map((p) => p.value).toList();
        comp.evaluate();
        for (int k = 0; k < comp.outputs.length; k++) {
          if (comp.outputs[k].value != oldOutputs[k]) anyChange = true;
        }
      } else if (comp is ConstantSource) {
        // Ensure constant source maintains its state
        if (comp.outputs.isNotEmpty && comp.outputs[0].value != comp.state) {
          comp.outputs[0].value = comp.state;
          anyChange = true;
        }
      }
    }

    return anyChange;
  }

  Pin? _findPin(String pinId) {
    for (var c in components) {
      for (var p in c.inputs) {
        if (p.id == pinId) return p;
      }
      for (var p in c.outputs) {
        if (p.id == pinId) return p;
      }
    }
    return null;
  }

  // --- History Management ---

  void saveCheckpoint() {
    if (_isApplyingHistory) return;
    final snapshot = _createSnapshot();
    _history.push(snapshot);
  }

  String _createSnapshot() {
    final map = {
      'components': components.map((c) => c.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
    return jsonEncode(map);
  }

  void undo() {
    if (!canUndo) return;
    final current = _createSnapshot();
    final previous = _history.undo(current);
    if (previous != null) {
      _applySnapshot(previous);
    }
  }

  void redo() {
    if (!canRedo) return;
    final current = _createSnapshot();
    final next = _history.redo(current);
    if (next != null) {
      _applySnapshot(next);
    }
  }

  void _applySnapshot(String snapshot) {
    _isApplyingHistory = true;
    try {
      final map = jsonDecode(snapshot) as Map<String, dynamic>;
      applyCircuitData(map, clearCanvas: true);
    } finally {
      _isApplyingHistory = false;
      notifyListeners();
    }
  }

  // -- Actions ---

  void addComponent(LogicComponent component) {
    saveCheckpoint();
    components.add(component);
    notifyListeners();
  }

  void removeComponent(String id) {
    saveCheckpoint();
    // If it's part of an unpacked IC, remove it from that IC too
    final parent = findParentIC(id);
    if (parent != null) {
      parent.removeInternalComponent(id);
    }

    _removeComponentInternal(id);
    notifyListeners();
  }

  void _removeComponentInternal(String id) {
    components.removeWhere((c) => c.id == id);
    selectedComponentIds.remove(id);

    // Find connections attached to this component
    List<Connection> connectionsToRemove = connections
        .where(
          (conn) =>
              LogicComponent.extractComponentId(conn.sourcePinId) == id ||
              LogicComponent.extractComponentId(conn.targetPinId) == id,
        )
        .toList();

    // Remove them one by one to trigger pin reset logic
    for (var conn in connectionsToRemove) {
      _removeConnectionInternal(conn.id);
    }
  }

  void addConnection(String sourcePinId, String targetPinId) {
    saveCheckpoint();
    connections.removeWhere((c) => c.targetPinId == targetPinId);

    connections.add(
      Connection(
        id: const Uuid().v4(),
        sourcePinId: sourcePinId,
        targetPinId: targetPinId,
      ),
    );
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    saveCheckpoint();
    _removeConnectionInternal(connectionId);
    notifyListeners();
  }

  void _removeConnectionInternal(String connectionId) {
    int index = connections.indexWhere((c) => c.id == connectionId);
    if (index != -1) {
      var conn = connections[index];
      var targetPin = _findPin(conn.targetPinId);
      if (targetPin != null) {
        targetPin.value = false;
      }
      connections.removeAt(index);
      notifyListeners();
    }
  }

  // --- Selection ---
  final Set<String> selectedComponentIds = {};

  void selectComponent(String id, {bool additive = false}) {
    if (!additive) {
      selectedComponentIds.clear();
    }
    selectedComponentIds.add(id);
    notifyListeners();
  }

  void deselectComponent(String id) {
    selectedComponentIds.remove(id);
    notifyListeners();
  }

  void toggleComponentSelection(String id) {
    if (selectedComponentIds.contains(id)) {
      selectedComponentIds.remove(id);
    } else {
      selectedComponentIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (selectedComponentIds.isNotEmpty) {
      selectedComponentIds.clear();
      notifyListeners();
    }
  }

  bool isSelected(String id) => selectedComponentIds.contains(id);

  void selectAll() {
    selectedComponentIds.clear();
    for (var c in components) {
      selectedComponentIds.add(c.id);
    }
    notifyListeners();
  }

  void moveSelectedComponents(Offset delta) {
    if (selectedComponentIds.isEmpty) return;
    // We don't save checkpoint here because this is called 60 times a second during drag.
    // The UI (CircuitBoard) should call saveCheckpoint() BEFORE starting a drag.
    for (var c in components) {
      if (selectedComponentIds.contains(c.id)) {
        c.position += delta.toVec2();
      }
    }
    notifyListeners();
  }

  void updateComponentPosition(String id, Offset delta) {
    // Note: Called during drag. Checkpoints should be handled by the drag start/end events if possible.
    try {
      var comp = components.firstWhere((c) => c.id == id);
      comp.position += delta.toVec2();
      notifyListeners();
    } catch (_) {}
  }

  // --- Bulk Actions ---

  void deleteSelectedComponents() {
    if (selectedComponentIds.isEmpty) return;
    saveCheckpoint();

    // Create a copy to iterate safely
    final idsToRemove = Set<String>.from(selectedComponentIds);

    for (var id in idsToRemove) {
      removeComponent(id);
    }
    selectedComponentIds.clear();
    notifyListeners();
  }

  void repackSelectedComponents() {
    saveCheckpoint();
    // 0. Check if any selected component is a child of an unpacked IC
    for (var id in selectedComponentIds) {
      final parent = findParentIC(id);
      if (parent != null) {
        repackExistingIC(parent.id);
        return; // Repacked the existing IC, we're done.
      }
    }

    final selectedComps = components
        .where((c) => selectedComponentIds.contains(c.id))
        .toList();

    // 1. Identify internal connections
    final internalConns = connections.where((conn) {
      bool sourceInside = selectedComps.any(
        (c) => LogicComponent.extractComponentId(conn.sourcePinId) == c.id,
      );
      bool targetInside = selectedComps.any(
        (c) => LogicComponent.extractComponentId(conn.targetPinId) == c.id,
      );
      return sourceInside && targetInside;
    }).toList();

    // 2. Calculate top-left for the new IC
    double minX = double.infinity;
    double minY = double.infinity;
    for (var c in selectedComps) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
    }

    if (minX == double.infinity) return;
    final icPos = Vec2(minX, minY);

    // 3. Create and normalize components for the IC
    for (var comp in selectedComps) {
      comp.position -= icPos;
    }

    final ic = IntegratedCircuit(
      name: "Repacked Circuit",
      position: icPos,
      internalComponents: List.from(selectedComps),
      internalConnections: List.from(internalConns),
    );

    // 4. Remove internal components and their connections from main board
    for (var comp in selectedComps) {
      _removeComponentInternal(comp.id);
    }

    // Also remove internal connections from board
    final connIdsToRemove = internalConns.map((c) => c.id).toSet();
    connections.removeWhere((conn) => connIdsToRemove.contains(conn.id));

    // 5. Add the new IC
    addComponent(ic);

    // 6. Clear selection
    clearSelection();
  }

  void clearCircuit() {
    saveCheckpoint();
    components.clear();
    connections.clear();
    selectedComponentIds.clear();
    currentFilePath = null;
    circuitSessionId = const Uuid().v4();
    _history.clear(); // Clearing the board usually resets history too? 
    // Actually, maybe not, maybe we should be able to UNDO a clear!
    // But since it's a "New File" operation, let's clear it for now.
    notifyListeners();
  }

  void alignSelectedComponents(String axis) {
    if (selectedComponentIds.length < 2) return;
    saveCheckpoint();

    List<LogicComponent> selected = components
        .where((c) => selectedComponentIds.contains(c.id))
        .toList();

    if (selected.isEmpty) return;

    if (axis == 'left') {
      double minX = selected
          .map((c) => c.position.dx)
          .reduce((a, b) => a < b ? a : b);
      for (var c in selected) {
        c.position = Vec2(minX, c.position.dy);
      }
    } else if (axis == 'right') {
      double maxX = selected
          .map((c) => c.position.dx)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) {
        c.position = Vec2(maxX, c.position.dy);
      }
    } else if (axis == 'top') {
      double minY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a < b ? a : b);
      for (var c in selected) {
        c.position = Vec2(c.position.dx, minY);
      }
    } else if (axis == 'bottom') {
      double maxY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) {
        c.position = Vec2(c.position.dx, maxY);
      }
    }

    notifyListeners();
  }

  // --- Copy / Paste ---

  void copySelectedComponents() {
    if (selectedComponentIds.isEmpty) return;

    final selectedComps = components
        .where((c) => selectedComponentIds.contains(c.id))
        .toList();

    // Identify internal connections
    final internalConns = connections.where((conn) {
      String srcCompId = LogicComponent.extractComponentId(conn.sourcePinId);
      String destCompId = LogicComponent.extractComponentId(conn.targetPinId);
      return selectedComponentIds.contains(srcCompId) &&
          selectedComponentIds.contains(destCompId);
    }).toList();

    final data = {
      'components': selectedComps.map((c) => c.toJson()).toList(),
      'connections': internalConns.map((c) => c.toJson()).toList(),
    };

    _clipboard = jsonEncode(data);
    notifyListeners();
  }

  void pasteComponents() {
    if (_clipboard == null) return;
    saveCheckpoint();

    try {
      final data = jsonDecode(_clipboard!) as Map<String, dynamic>;
      final List<dynamic> compsJson = data['components'];
      final List<dynamic> connsJson = data['connections'];

      final Map<String, String> idMap = {}; // oldId -> newId
      final List<LogicComponent> newComps = [];

      // 1. Create new components with new IDs
      for (var j in compsJson) {
        String oldId = j['id'];
        String newId = const Uuid().v4();
        idMap[oldId] = newId;

        // Temporarily modify JSON for deserialization
        final clone = Map<String, dynamic>.from(j);
        clone['id'] = newId;
        // Offset position
        clone['position_dx'] = (j['position_dx'] as num).toDouble() + 40.0;
        clone['position_dy'] = (j['position_dy'] as num).toDouble() + 40.0;

        var comp = _deserializeComponent(clone);
        if (comp != null) {
          newComps.add(comp);
        }
      }

      // 2. Add components and select them
      selectedComponentIds.clear();
      for (var comp in newComps) {
        components.add(comp);
        selectedComponentIds.add(comp.id);
      }

      // 3. Remap and add connections
      for (var j in connsJson) {
        String oldSrcPin = j['sourcePinId'];
        String oldTgtPin = j['targetPinId'];

        String oldSrcCompId = LogicComponent.extractComponentId(oldSrcPin);
        String oldTgtCompId = LogicComponent.extractComponentId(oldTgtPin);

        String? newSrcCompId = idMap[oldSrcCompId];
        String? newTgtCompId = idMap[oldTgtCompId];

        if (newSrcCompId != null && newTgtCompId != null) {
          // Reconstruct pin IDs (e.g., compId-out-0)
          String newSrcPin =
              oldSrcPin.replaceFirst(oldSrcCompId, newSrcCompId);
          String newTgtPin =
              oldTgtPin.replaceFirst(oldTgtCompId, newTgtCompId);

          connections.add(
            Connection(
              id: const Uuid().v4(),
              sourcePinId: newSrcPin,
              targetPinId: newTgtPin,
            ),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error pasting components: $e");
    }
  }

  // --- Save / Load ---

  // Generic save: requires currentFilePath or prompts user
  Future<void> saveCurrentCircuit() async {
    if (currentFilePath != null) {
      await saveCircuitToPath(currentFilePath!);
    } else {
      await saveCircuitAs();
    }
  }

  Future<void> saveCircuitAs() async {
    // Web: FilePicker.saveFile is not useful for path selection. Just trigger download.
    // Web: Use FileOps.saveFile which now supports FS Access API (Save As Picker)
    if (kIsWeb) {
      debugPrint("saveCircuitAs: Web detected, invoking FileOps.saveFile...");
      // We pass a default name, but saveFile will trigger the picker.
      String? savedName = await FileOps.saveFile(
        jsonEncode({
          'components': components.map((c) => c.toJson()).toList(),
          'connections': connections.map((c) => c.toJson()).toList(),
        }),
        "circuit.json",
      );

      if (savedName != null) {
        currentFilePath = savedName;
        debugPrint("saveCircuitAs: Saved to $savedName");
      }
      return;
    }

    // Desktop/Mobile: Use FilePicker
    debugPrint("saveCircuitAs: requesting save file dialog...");
    try {
      String? initialDir = await FileOps.getAssetsDirectory();
      debugPrint("saveCircuitAs: using initialDir: $initialDir");

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Circuit As',
        fileName: 'circuit.json',
        initialDirectory: initialDir,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      debugPrint("saveCircuitAs: dialog returned: $outputFile");

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.json')) {
          outputFile += '.json';
        }
        currentFilePath = outputFile;
        await saveCircuitToPath(outputFile);
      } else {
        debugPrint("saveCircuitAs: cancelled by user");
      }
    } catch (e) {
      debugPrint("saveCircuitAs: ERROR: $e");
      // Fallback: try without initialDirectory
      try {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Circuit As',
          fileName: 'circuit.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (outputFile != null) {
          if (!outputFile.toLowerCase().endsWith('.json')) {
            outputFile += '.json';
          }
          currentFilePath = outputFile;
          await saveCircuitToPath(outputFile);
        }
      } catch (e2) {
        debugPrint("saveCircuitAs: Fallback failed: $e2");
      }
    }
  }

  Future<void> saveCircuitToPath(String path) async {
    debugPrint("saveCircuitToPath: saving to $path");
    final jsonMap = {
      'components': components.map((c) => c.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
    String content = jsonEncode(jsonMap);
    debugPrint(
      "saveCircuitToPath: encoding complete, writing using FileOps...",
    );
    await FileOps.saveFileToPath(path, content);
    debugPrint("saveCircuitToPath: write complete");
  }

  Future<({Map<String, dynamic> data, String name})?>
  pickAndReadCircuit() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return null;

    PlatformFile pFile = result.files.single;
    if (pFile.path != null) {
      currentFilePath = pFile.path;
    }

    String content = await FileOps.readFile(pFile);
    if (content.isEmpty) return null;

    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      String name = pFile.name;
      if (name.toLowerCase().endsWith(".json")) {
        name = name.substring(0, name.length - 5);
      }
      return (data: data, name: name);
    } catch (e) {
      debugPrint("Error decoding circuit: $e");
      return null;
    }
  }

  void applyCircuitData(
    Map<String, dynamic> jsonMap, {
    bool clearCanvas = true,
    String? name,
    Offset? position,
  }) {
    if (clearCanvas) {
      components.clear();
      connections.clear();
      selectedComponentIds.clear();
      circuitSessionId = const Uuid().v4();
    }

    final List<dynamic> compsJson = jsonMap['components'];
    final List<dynamic> connsJson = jsonMap['connections'];

    // Map to track old ID -> new component mapping if we were doing deep copy,
    // but here we just deserialize.
    for (var j in compsJson) {
      var comp = _deserializeComponent(j);
      if (comp != null) {
        if (position != null) {
          // If appending, might want to offset?
          // For now just add.
        }
        addComponent(comp);
      }
    }

    for (var j in connsJson) {
      connections.add(Connection.fromJson(j));
    }

    notifyListeners();
  }

  Future<void> loadCircuit({Offset? position}) async {
    final result = await pickAndReadCircuit();
    if (result != null) {
      // By default, we pack loaded circuits into an IntegratedCircuit component.
      packCircuit(result.data, result.name, position: position);
    }
  }

  void packCircuit(Map<String, dynamic> data, String name, {Offset? position}) {
    final pos = (position ?? (getViewportCenter?.call() ?? Offset.zero)).toVec2();
    final List<dynamic> internalCompsJson = data['components'] ?? [];
    final List<dynamic> internalConnsJson = data['connections'] ?? [];

    final internalComps = internalCompsJson
        .map((e) => _deserializeComponent(e as Map<String, dynamic>))
        .whereType<LogicComponent>()
        .toList();
    final internalConns = internalConnsJson
        .map((e) => Connection.fromJson(e as Map<String, dynamic>))
        .toList();

    final ic = IntegratedCircuit(
      name: name,
      position: pos,
      internalComponents: internalComps,
      internalConnections: internalConns,
    );

    addComponent(ic);
  }

  void unpackIntegratedCircuit(String id) {
    saveCheckpoint();
    final index = components.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final comp = components[index];
    if (comp is! IntegratedCircuit) return;

    final ic = comp;

    // 1. Mark the IC as unpacked
    ic.isUnpacked = true;
    if (!ic.name.contains("(unpacked)")) {
      ic.name += " (unpacked)";
    }

    // Clear selection so the IC isn't selected while unpacking
    clearSelection();

    // 2. Add internal components back to the main board
    // Calculate the top-left of the internal components to offset them to the IC's position
    double minX = double.infinity;
    double minY = double.infinity;
    for (var c in ic.internalComponents) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
    }

    // Fallback if no components
    if (minX == double.infinity) {
      minX = 0;
      minY = 0;
    }

    final Vec2 offset = ic.position - Vec2(minX, minY);

    for (var internalComp in ic.internalComponents) {
      internalComp.position += offset;
      components.add(
        internalComp,
      ); // Use direct add to avoid redundant notifications
    }

    for (var internalConn in ic.internalConnections) {
      connections.add(internalConn);
    }

    notifyListeners();
  }

  void repackExistingIC(String id) {
    saveCheckpoint();
    final index = components.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final comp = components[index];
    if (comp is! IntegratedCircuit || !comp.isUnpacked) return;

    final ic = comp;

    // 0. Sync internal components with what's actually on the board 
    // (in case some were deleted while unpacked)
    ic.internalComponents.removeWhere((child) => !components.any((c) => c.id == child.id));

    // 1. Capture current positions and calculate new IC top-left
    if (ic.internalComponents.isEmpty) {
      ic.isUnpacked = false;
      ic.name = ic.name.replaceAll(" (unpacked)", "");
      notifyListeners();
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    for (var child in ic.internalComponents) {
      if (child.position.dx < minX) minX = child.position.dx;
      if (child.position.dy < minY) minY = child.position.dy;
    }

    final newPos = Vec2(minX, minY);
    
    // 2. Identify all connections between internal components currently on board
    final internalIds = ic.internalComponents.map((c) => c.id).toSet();
    final currentInternalConns = connections.where((conn) {
      String srcCompId = LogicComponent.extractComponentId(conn.sourcePinId);
      String destCompId = LogicComponent.extractComponentId(conn.targetPinId);
      return internalIds.contains(srcCompId) && internalIds.contains(destCompId);
    }).toList();

    // 3. Update IC state
    ic.position = newPos;
    ic.internalConnections.clear();
    ic.internalConnections.addAll(currentInternalConns);
    
    // Remove from board BEFORE normalizing, because _removeComponentInternal might use world coords if we ever add that
    // Actually, we must remove from board first.
    for (var childId in internalIds) {
      _removeComponentInternal(childId);
    }

    for (var child in ic.internalComponents) {
      child.position -= newPos; // Normalize back to local coordinates
    }

    // Also remove the connections we captured (they are now solely internal to IC)
    final connIdsToRemove = currentInternalConns.map((c) => c.id).toSet();
    connections.removeWhere((conn) => connIdsToRemove.contains(conn.id));

    ic.isUnpacked = false;
    ic.name = ic.name.replaceAll(" (unpacked)", "");

    notifyListeners();
  }

  IntegratedCircuit? findParentIC(String componentId) {
    for (var c in components) {
      if (c is IntegratedCircuit && c.isUnpacked) {
        if (c.internalComponents.any((child) => child.id == componentId)) {
          return c;
        }
      }
    }
    return null;
  }

  LogicComponent? _deserializeComponent(Map<String, dynamic> json) {
    ComponentType type = ComponentType.values[json['type']];
    Vec2 pos = Vec2.fromJson(json);
    String id = json['id'];

    LogicComponent? comp;

    switch (type) {
      case ComponentType.and:
        comp = AndGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.nand:
        comp = NandGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.or:
        comp = OrGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.nor:
        comp = NorGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.xor:
        comp = XorGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.nxor:
        comp = NxorGate(id: id, position: pos, inputCount: json['inputCount'] ?? 2);
        break;
      case ComponentType.inverter:
        comp = Inverter(id: id, position: pos);
        break;
      case ComponentType.oscillator:
        comp = Oscillator(id: id, position: pos, frequency: json['frequency'] ?? 1.0);
        break;
      case ComponentType.led:
        comp = Led(
          id: id,
          position: pos,
          colorHigh: json['colorHigh'] ?? 0xFFFF0000,
          colorLow: json['colorLow'] ?? 0xFF550000,
          label: json['label'] ?? "",
        );
        break;
      case ComponentType.segment7:
        comp = SegmentDisplay(
          id: id,
          position: pos,
          segments: 7,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 80.0,
        );
        break;
      case ComponentType.segment16:
        comp = SegmentDisplay(
          id: id,
          position: pos,
          segments: 16,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 24.0,
        );
        break;
      case ComponentType.constantSource:
        bool state = json['state'] ?? true;
        comp = ConstantSource(id: id, position: pos, state: state);
        break;
      case ComponentType.circuitInput:
        comp = CircuitInput(id: id, position: pos);
        if (json.containsKey('label')) {
          (comp as CircuitInput).label = json['label'];
        }
        break;
      case ComponentType.circuitOutput:
        comp = CircuitOutput(id: id, position: pos);
        if (json.containsKey('label')) {
          (comp as CircuitOutput).label = json['label'];
        }
        break;
      case ComponentType.button:
        comp = ButtonComponent(id: id, position: pos);
        if (json.containsKey('isPressed')) {
          (comp as ButtonComponent).isPressed = json['isPressed'];
        }
        if (json.containsKey('label')) {
          (comp as ButtonComponent).label = json['label'];
        }
        break;
      case ComponentType.integratedCircuit:
        final internalCompsJson = json['internalComponents'] as List? ?? [];
        final internalConnsJson = json['internalConnections'] as List? ?? [];
        final internalComps = internalCompsJson
            .map((e) {
              try {
                return _deserializeComponent(e as Map<String, dynamic>);
              } catch (e) {
                return null;
              }
            })
            .whereType<LogicComponent>()
            .toList();
        final internalConns = internalConnsJson
            .map((e) {
              try {
                return Connection.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                return null;
              }
            })
            .whereType<Connection>()
            .toList();

        comp = IntegratedCircuit(
          id: id,
          name: json['name'] ?? "IC",
          position: pos,
          internalComponents: internalComps,
          internalConnections: internalConns,
        );
        (comp as IntegratedCircuit).isUnpacked = json['isUnpacked'] ?? false;
        break;
      case ComponentType.markdownText:
        comp = MarkdownComponent(
          id: id,
          position: pos,
          text: json['text'] ?? "",
        );
        break;
      case ComponentType.dFlipFlop:
        comp = DFlipFlop(id: id, position: pos);
        break;
      case ComponentType.jkFlipFlop:
        comp = JKFlipFlop(id: id, position: pos);
        break;
      case ComponentType.rsFlipFlop:
        comp = RSFlipFlop(id: id, position: pos);
        break;
    }
    return comp;
  }

  void addComponentByType(ComponentType type, Offset posOffset) {
    LogicComponent? comp;
    String id = const Uuid().v4();
    Vec2 pos = posOffset.toVec2();

    switch (type) {
      case ComponentType.and:
        comp = AndGate(id: id, position: pos);
        break;
      case ComponentType.nand:
        comp = NandGate(id: id, position: pos);
        break;
      case ComponentType.or:
        comp = OrGate(id: id, position: pos);
        break;
      case ComponentType.nor:
        comp = NorGate(id: id, position: pos);
        break;
      case ComponentType.xor:
        comp = XorGate(id: id, position: pos);
        break;
      case ComponentType.nxor:
        comp = NxorGate(id: id, position: pos);
        break;
      case ComponentType.inverter:
        comp = Inverter(id: id, position: pos);
        break;
      case ComponentType.oscillator:
        comp = Oscillator(id: id, position: pos);
        break;
      case ComponentType.led:
        comp = Led(id: id, position: pos);
        break;
      case ComponentType.segment7:
        comp = SegmentDisplay(id: id, position: pos, segments: 7);
        break;
      case ComponentType.segment16:
        comp = SegmentDisplay(id: id, position: pos, segments: 16);
        break;
      case ComponentType.constantSource:
        comp = ConstantSource(id: id, position: pos);
        break;
      case ComponentType.circuitInput:
        comp = CircuitInput(id: id, position: pos);
        break;
      case ComponentType.circuitOutput:
        comp = CircuitOutput(id: id, position: pos);
        break;
      case ComponentType.button:
        comp = ButtonComponent(id: id, position: pos);
        break;
      case ComponentType.markdownText:
        comp = MarkdownComponent(id: id, position: pos);
        break;
      case ComponentType.dFlipFlop:
        comp = DFlipFlop(id: id, position: pos);
        break;
      case ComponentType.jkFlipFlop:
        comp = JKFlipFlop(id: id, position: pos);
        break;
      case ComponentType.rsFlipFlop:
        comp = RSFlipFlop(id: id, position: pos);
        break;
      case ComponentType.integratedCircuit:
        // ICs are usually added via 'packing' or 'loading',
        // but we need the case for switch exhaustiveness.
        break;
    }
    if (comp != null) {
      addComponent(comp);
    }
  }

  void refresh() {
    notifyListeners();
  }
}
