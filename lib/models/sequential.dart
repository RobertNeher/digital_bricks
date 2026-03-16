import 'logic_component.dart';

class DFlipFlop extends LogicComponent {
  bool _value = false;
  bool _lastClock = false;

  DFlipFlop({super.id, required super.position})
      : super(name: 'D type', type: ComponentType.dFlipFlop) {
    addInputPin(); // 0: D
    inputs[0].label = 'D';
    addInputPin(); // 1: CLK
    inputs[1].label = '>'; 
    addOutputPin(); // 0: Q
    outputs[0].label = 'Q';
    addOutputPin(); // 1: /Q
    outputs[1].label = 'Q̅';

    // Initial state
    outputs[0].value = _value;
    outputs[1].value = !_value;
  }

  @override
  void evaluate() {
    bool d = inputs[0].value;
    bool clk = inputs[1].value;

    // Rising edge detection
    if (clk && !_lastClock) {
      _value = d;
    }
    _lastClock = clk;

    outputs[0].value = _value;
    outputs[1].value = !_value;
  }
}

class JKFlipFlop extends LogicComponent {
  bool _value = false;
  bool _lastClock = false;

  JKFlipFlop({super.id, required super.position})
      : super(name: 'JK type', type: ComponentType.jkFlipFlop) {
    addInputPin(); // 0: J
    inputs[0].label = 'J';
    addInputPin(); // 1: K
    inputs[1].label = 'K';
    addInputPin(); // 2: CLK
    inputs[2].label = '>';
    addOutputPin(); // 0: Q
    outputs[0].label = 'Q';
    addOutputPin(); // 1: /Q
    outputs[1].label = 'Q̅';

    // Initial state
    outputs[0].value = _value;
    outputs[1].value = !_value;
  }

  @override
  void evaluate() {
    bool j = inputs[0].value;
    bool k = inputs[1].value;
    bool clk = inputs[2].value;

    // Rising edge detection
    if (clk && !_lastClock) {
      if (j && k) {
        _value = !_value; // Toggle
      } else if (j) {
        _value = true; // Set
      } else if (k) {
        _value = false; // Reset
      }
    }
    _lastClock = clk;

    outputs[0].value = _value;
    outputs[1].value = !_value;
  }
}

class RSFlipFlop extends LogicComponent {
  bool _value = false;
  bool _lastClock = false;

  RSFlipFlop({super.id, required super.position})
      : super(name: 'RS type', type: ComponentType.rsFlipFlop) {
    addInputPin(); // 0: S
    inputs[0].label = 'S';
    addInputPin(); // 1: R
    inputs[1].label = 'R';
    addInputPin(); // 2: CLK
    inputs[2].label = '>';
    addOutputPin(); // 0: Q
    outputs[0].label = 'Q';
    addOutputPin(); // 1: /Q
    outputs[1].label = 'Q̅';

    // Initial state
    outputs[0].value = _value;
    outputs[1].value = !_value;
  }

  @override
  void evaluate() {
    bool s = inputs[0].value;
    bool r = inputs[1].value;
    bool clk = inputs[2].value;

    // Rising edge detection
    if (clk && !_lastClock) {
      if (s && r) {
        // Forbidden state
        _value = false; 
      } else if (s) {
        _value = true;
      } else if (r) {
        _value = false;
      }
    }
    _lastClock = clk;

    outputs[0].value = _value;
    outputs[1].value = !_value;
  }
}
