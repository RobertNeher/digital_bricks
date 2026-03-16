import 'logic_component.dart';
import 'connection.dart';
import 'circuit_io.dart';
import 'pin.dart';
import 'io_devices.dart';

class IntegratedCircuit extends LogicComponent {
  final List<LogicComponent> internalComponents;
  final List<Connection> internalConnections;
  bool isUnpacked = false;

  IntegratedCircuit({
    super.id,
    required super.name,
    required super.position,
    required this.internalComponents,
    required this.internalConnections,
  }) : super(type: ComponentType.integratedCircuit) {
    _initializePins();
  }

  void removeInternalComponent(String id) {
    internalComponents.removeWhere((c) => c.id == id);
    // Also cleanup connections involving this component? 
    // Usually repacking handles it, but good to be clean.
    internalConnections.removeWhere((conn) => 
      conn.sourcePinId.split('-').first == id || 
      conn.targetPinId.split('-').first == id
    );
  }

  void _initializePins() {
    // Collect internal IO components
    final inputsIn = internalComponents.whereType<CircuitInput>().toList();
    final outputsIn = internalComponents.whereType<CircuitOutput>().toList();

    // Map internal CircuitInput (which has 1 output pin internally) 
    // to an EXTERNAL input pin.
    for (var i = 0; i < inputsIn.length; i++) {
      addInputPin();
      inputs.last.label = inputsIn[i].label;
    }

    // Map internal CircuitOutput (which has 1 input pin internally)
    // to an EXTERNAL output pin.
    for (var i = 0; i < outputsIn.length; i++) {
      addOutputPin();
      outputs.last.label = outputsIn[i].label;
    }
  }

  @override
  void evaluate() {
    if (isUnpacked) return;
    // 1. Map external inputs to internal CircuitInput components
    final inputsIn = internalComponents.whereType<CircuitInput>().toList();
    for (int i = 0; i < inputsIn.length && i < inputs.length; i++) {
      // The internal CircuitInput has an output[0] that feeds the rest of the sub-circuit
      inputsIn[i].outputs[0].value = inputs[i].value;
    }

    // 2. Propagate signals internally
    // We run a few iterations to reach steady state for simple combinational logic.
    for (int i = 0; i < 10; i++) {
      _propagateInternal();
    }

    // 3. Map internal CircuitOutput components to external outputs
    final outputsIn = internalComponents.whereType<CircuitOutput>().toList();
    for (int i = 0; i < outputsIn.length && i < outputs.length; i++) {
      // The internal CircuitOutput has an input[0] that receives from sub-circuit
      outputs[i].value = outputsIn[i].inputs[0].value;
    }
  }

  void _propagateInternal() {
    // A. Transfer values via connections
    for (var conn in internalConnections) {
      final sourcePin = _findInternalPin(conn.sourcePinId);
      final targetPin = _findInternalPin(conn.targetPinId);
      if (sourcePin != null && targetPin != null) {
        targetPin.value = sourcePin.value;
      }
    }

    // B. Evaluate components
    for (var comp in internalComponents) {
      if (comp is! Oscillator && comp is! ConstantSource) {
        comp.evaluate();
      }
    }
  }

  Pin? _findInternalPin(String pinId) {
    for (var comp in internalComponents) {
      for (var p in comp.inputs) {
        if (p.id == pinId) return p;
      }
      for (var p in comp.outputs) {
        if (p.id == pinId) return p;
      }
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['name'] = name;
    json['internalComponents'] = internalComponents.map((e) => e.toJson()).toList();
    json['internalConnections'] = internalConnections.map((e) => e.toJson()).toList();
    json['isUnpacked'] = isUnpacked;
    return json;
  }
}
