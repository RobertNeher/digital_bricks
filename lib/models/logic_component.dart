import 'package:uuid/uuid.dart';
import 'pin.dart';

class Vec2 {
  final double dx;
  final double dy;

  const Vec2(this.dx, this.dy);

  static const Vec2 zero = Vec2(0, 0);

  Vec2 operator +(Vec2 other) => Vec2(dx + other.dx, dy + other.dy);
  Vec2 operator -(Vec2 other) => Vec2(dx - other.dx, dy - other.dy);
  Vec2 operator *(double scalar) => Vec2(dx * scalar, dy * scalar);

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};

  factory Vec2.fromJson(Map<String, dynamic> json) {
    return Vec2(
      (json['dx'] ?? json['position_dx'] ?? 0.0).toDouble(),
      (json['dy'] ?? json['position_dy'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => 'Vec2($dx, $dy)';
}

enum ComponentType {
  and,
  nand,
  or,
  nor,
  xor,
  nxor,
  inverter,
  oscillator,
  led,
  segment7,
  segment16,
  constantSource,
  circuitInput,
  circuitOutput,
  button,
  markdownText,
  integratedCircuit,
  dFlipFlop,
  jkFlipFlop,
  rsFlipFlop,
}

abstract class LogicComponent {
  String id;
  String name;
  Vec2 position;
  ComponentType type;
  List<Pin> inputs = [];
  List<Pin> outputs = [];

  // Base constructor
  LogicComponent({
    String? id,
    required this.name,
    required this.position,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  // Abstract method to update component physics/logic
  void evaluate();

  // Helper to init pins
  void addInputPin() {
    inputs.add(
      Pin(id: '$id-in-${inputs.length}', componentId: id, type: PinType.input),
    );
  }

  void addOutputPin() {
    outputs.add(
      Pin(
        id: '$id-out-${outputs.length}',
        componentId: id,
        type: PinType.output,
      ),
    );
  }

  // Serialization methods must be implemented or handled by a factory
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'position_dx': position.dx,
      'position_dy': position.dy,
      'inputs': inputs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
      // Subclasses should add their specific params
    };
  }

  // For deserialization, we will likely need a factory or static method
  // that switches on ComponentType
}
