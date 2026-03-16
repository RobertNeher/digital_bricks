import 'dart:convert';
import 'dart:io';

void main() {
  final components = [];
  final connections = [];

  Map<String, dynamic> genComp(String name, int type, double x, double y,
      {String? labels, int inputCount = 0, int outputCount = 0}) {
    var id = "comp-${components.length}-${DateTime.now().microsecondsSinceEpoch}";
    var inputs = [];
    for (int i = 0; i < inputCount; i++) {
      inputs.add({
        "id": "$id-in-$i",
        "componentId": id,
        "type": 0, // PinType.input
        "value": false
      });
    }
    var outputs = [];
    for (int i = 0; i < outputCount; i++) {
      outputs.add({
        "id": "$id-out-$i",
        "componentId": id,
        "type": 1, // PinType.output
        "value": false
      });
    }
    return {
      "id": id,
      "name": name,
      "type": type,
      "position_dx": x,
      "position_dy": y,
      "inputs": inputs,
      "outputs": outputs,
      "label": labels,
      "inputCount": inputCount,
      "frequency": type == 7 ? 1.0 : null,
      "state": type == 11 ? true : null,
    };
  }

  void addConn(Map<String, dynamic> srcComp, int srcPinIdx,
      Map<String, dynamic> destComp, int destPinIdx) {
    connections.add({
      "id": "c${connections.length}-${DateTime.now().microsecondsSinceEpoch}",
      "sourcePinId": srcComp['outputs'][srcPinIdx]['id'],
      "targetPinId": destComp['inputs'][destPinIdx]['id']
    });
  }

  Map<String, dynamic> makeDFlipFlop(double startX, double startY) {
    var ff = genComp("D type", 17, startX, startY, inputCount: 2, outputCount: 2);
    components.add(ff);
    return ff;
  }

  var mainClock = genComp("Input Fan", 12, 50, 200, labels: "CLK", outputCount: 1);
  components.add(mainClock);

  List<Map<String, dynamic>> ffs = [];
  for (int i = 0; i < 4; i++) {
    var ff = makeDFlipFlop(300 + i * 250.0, 100);
    ffs.add(ff);
    
    // Connect /Q (output 1) back to D (input 0) to make it a T-FF
    addConn(ff, 1, ff, 0);

    if (i == 0) {
      addConn(mainClock, 0, ff, 1);
    } else {
      // Ripple carry: previous /Q (output 1) to current CLK (input 1)
      addConn(ffs[i-1], 1, ff, 1);
    }
  }

  for (int i = 0; i < 4; i++) {
    var out = genComp("Output Fan", 13, 300 + i * 350.0 + 150, 400, labels: "Q${i}", inputCount: 1, outputCount: 0);
    components.add(out);
    addConn(ffs[i], 0, out, 0);
  }

  var overflowAnd = genComp("AND_OVER", 0, 1800, 300, inputCount: 4, outputCount: 1);
  components.add(overflowAnd);
  for (int i = 0; i < 4; i++) {
    addConn(ffs[i], 0, overflowAnd, i);
  }
  
  var overflowOut = genComp("OVERFLOW", 13, 1950, 300, labels: "OVF", inputCount: 1, outputCount: 0);
  components.add(overflowOut);
  addConn(overflowAnd, 0, overflowOut, 0);

  final path = 'assets/4_bit_counter_generated.json';
  File(path).writeAsStringSync(jsonEncode({
    "components": components,
    "connections": connections
  }));
  print("Generated \${path} successfully");
}
