import 'logic_component.dart';

/// A component representing an input port for an Integrated Circuit.
/// When used inside a blueprint, it acts as a signal source (output pin) that
/// gets its value from the external world.
class CircuitInput extends LogicComponent {
  String label;

  CircuitInput({super.id, required super.position, this.label = "IN"})
    : super(name: 'IN', type: ComponentType.circuitInput) {
    // Acts as a source for the internal circuit, so it has an OUTPUT pin.
    addOutputPin();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['label'] = label;
    return json;
  }

  @override
  void evaluate() {
    // In a blueprint simulation, we might allow the user to toggle it manually
    // to test the circuit.
    // In an unpacked IC, its functionality is handled by the sync logic.
  }
}

/// A component representing an output port for an Integrated Circuit.
/// When used inside a blueprint, it acts as a signal sink (input pin) that
/// sends its value to the external world.
class CircuitOutput extends LogicComponent {
  String label;

  CircuitOutput({super.id, required super.position, this.label = "OUT"})
    : super(name: 'OUT', type: ComponentType.circuitOutput) {
    // Acts as a sink for the internal circuit, so it has an INPUT pin.
    addInputPin();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['label'] = label;
    return json;
  }

  @override
  void evaluate() {
    // Passive.
  }
}
