import 'logic_component.dart';

// Base class for gates with variable number of inputs
abstract class MultiInputGate extends LogicComponent {
  int inputCount;

  MultiInputGate({
    super.id,
    required super.name,
    required super.position,
    required super.type,
    this.inputCount = 2,
  }) {
    // Initialize inputs based on count if not provided (e.g. from JSON later)
    // Note: If deserializing, we clear and re-add or handle in factory
    // For now, let's assume if it's new, we generate pins.
    for (int i = 0; i < inputCount; i++) {
      addInputPin();
    }
    // All basic gates have 1 output
    addOutputPin();
  }

  // Re-creates input pins if count changes
  void updateInputCount(int count) {
    if (count < 2) count = 2; // Minimum 2 inputs for most gates
    inputCount = count;
    inputs.clear();
    for (int i = 0; i < inputCount; i++) {
      addInputPin();
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['inputCount'] = inputCount;
    return json;
  }
}

class AndGate extends MultiInputGate {
  AndGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'AND', type: ComponentType.and);

  @override
  void evaluate() {
    bool result = true;
    for (var pin in inputs) {
      if (!pin.value) {
        result = false;
        break;
      }
    }
    outputs[0].value = result;
  }
}

class NandGate extends MultiInputGate {
  NandGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'NAND', type: ComponentType.nand);

  @override
  void evaluate() {
    bool result = true;
    for (var pin in inputs) {
      if (!pin.value) {
        result = false;
        break;
      }
    }
    outputs[0].value = !result;
  }
}

class OrGate extends MultiInputGate {
  OrGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'OR', type: ComponentType.or);

  @override
  void evaluate() {
    bool result = false;
    for (var pin in inputs) {
      if (pin.value) {
        result = true;
        break;
      }
    }
    outputs[0].value = result;
  }
}

class NorGate extends MultiInputGate {
  NorGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'NOR', type: ComponentType.nor);

  @override
  void evaluate() {
    bool result = false;
    for (var pin in inputs) {
      if (pin.value) {
        result = true;
        break;
      }
    }
    outputs[0].value = !result;
  }
}

class XorGate extends MultiInputGate {
  XorGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'XOR', type: ComponentType.xor);

  @override
  void evaluate() {
    // XOR for >2 inputs is usually defined as odd parity or strictly one-hot depending on diff definitions.
    // Standard multi-input XOR usually means "odd number of trues".
    int trueCount = inputs.where((p) => p.value).length;
    outputs[0].value = (trueCount % 2) != 0;
  }
}

class NxorGate extends MultiInputGate {
  NxorGate({super.id, required super.position, super.inputCount = 2})
    : super(name: 'NXOR', type: ComponentType.nxor);

  @override
  void evaluate() {
    int trueCount = inputs.where((p) => p.value).length;
    outputs[0].value = (trueCount % 2) == 0;
  }
}

class Inverter extends LogicComponent {
  Inverter({super.id, required super.position})
    : super(name: 'NOT', type: ComponentType.inverter) {
    addInputPin();
    addOutputPin();
  }

  @override
  void evaluate() {
    if (inputs.isNotEmpty && outputs.isNotEmpty) {
      outputs[0].value = !inputs[0].value;
    }
  }
}
