import 'dart:convert';
import 'dart:io';

void main() {
  final components = <Map<String, dynamic>>[];
  final connections = <Map<String, dynamic>>[];

  String generateUuid() {
    // simple uuid roughly
    return 'xxxx-xxxx-xxxx-xxxx'.replaceAllMapped(RegExp(r'x'), (match) {
          return (DateTime.now().microsecondsSinceEpoch % 16).toRadixString(16);
        }) +
        '-${DateTime.now().microsecondsSinceEpoch}';
  }

  Map<String, dynamic> genComp(
    String name,
    int type,
    double x,
    double y, {
    String? labels,
    int inputCount = 0,
    int outputCount = 0,
  }) {
    final cid =
        "comp-${components.length}-${DateTime.now().microsecondsSinceEpoch}";
    final comp = {
      "id": cid,
      "name": name,
      "type": type,
      "position_dx": x,
      "position_dy": y,
      "inputs": [],
      "outputs": [],
    };

    for (int i = 0; i < inputCount; i++) {
      (comp["inputs"] as List).add({
        "id": "$cid-in-$i",
        "componentId": cid,
        "type": 0,
        "value": false,
      });
    }

    for (int i = 0; i < outputCount; i++) {
      (comp["outputs"] as List).add({
        "id": "$cid-out-$i",
        "componentId": cid,
        "type": 1,
        "value": false,
      });
    }

    if (inputCount >= 2 && [0, 1, 2, 3, 4, 5].contains(type)) {
      comp["inputCount"] = inputCount;
    }

    if (labels != null) {
      comp["label"] = labels;
    }

    return comp;
  }

  void addConn(
    Map<String, dynamic> srcComp,
    int srcOutIdx,
    Map<String, dynamic> tgtComp,
    int tgtInIdx,
  ) {
    connections.add({
      "id":
          "conn-${connections.length}-${DateTime.now().microsecondsSinceEpoch}",
      "sourcePinId": (srcComp["outputs"] as List)[srcOutIdx]["id"],
      "targetPinId": (tgtComp["inputs"] as List)[tgtInIdx]["id"],
    });
  }

  // Inputs
  final weights = ["8", "4", "2", "1"];
  final inputs = <Map<String, dynamic>>[];
  final nots = <Map<String, dynamic>>[];

  for (int i = 0; i < 4; i++) {
    final l = weights[i];
    final inp = genComp(
      "IN_$l",
      12,
      100,
      200.0 + i * 200,
      labels: l,
      inputCount: 0,
      outputCount: 1,
    );
    final inv = genComp(
      "NOT_$l",
      6,
      250,
      200.0 + i * 200,
      inputCount: 1,
      outputCount: 1,
    );
    components.addAll([inp, inv]);
    inputs.add(inp);
    nots.add(inv);
    addConn(inp, 0, inv, 0);
  }

  // Minterms
  final minterms = <Map<String, dynamic>>[];
  for (int m = 0; m < 16; m++) {
    final mGate = genComp(
      "M_$m",
      0,
      450,
      50.0 + m * 75,
      inputCount: 4,
      outputCount: 1,
    );
    components.add(mGate);
    minterms.add(mGate);

    for (int bit = 0; bit < 4; bit++) {
      final val = (m >> (3 - bit)) & 1;
      final src = val == 1 ? inputs[bit] : nots[bit];
      addConn(src, 0, mGate, bit);
    }
  }

  // Segment ORs and Outputs
  final hexPatterns = [
    [1, 1, 1, 1, 1, 1, 0], // 0
    [0, 1, 1, 0, 0, 0, 0], // 1
    [1, 1, 0, 1, 1, 0, 1], // 2
    [1, 1, 1, 1, 0, 0, 1], // 3
    [0, 1, 1, 0, 0, 1, 1], // 4
    [1, 0, 1, 1, 0, 1, 1], // 5
    [1, 0, 1, 1, 1, 1, 1], // 6
    [1, 1, 1, 0, 0, 0, 0], // 7
    [1, 1, 1, 1, 1, 1, 1], // 8
    [1, 1, 1, 1, 0, 1, 1], // 9
    [1, 1, 1, 0, 1, 1, 1], // A
    [0, 0, 1, 1, 1, 1, 1], // b
    [1, 0, 0, 1, 1, 1, 0], // C
    [0, 1, 1, 1, 1, 0, 1], // d
    [1, 0, 0, 1, 1, 1, 1], // E
    [1, 0, 0, 0, 1, 1, 1], // F
  ];

  final segNames = ["A", "B", "C", "D", "E", "F", "G"];
  for (int s = 0; s < 7; s++) {
    final activeM = <int>[];
    for (int m = 0; m < 16; m++) {
      if (hexPatterns[m][s] == 1) activeM.add(m);
    }

    final cOr = genComp(
      "OR_${segNames[s]}",
      2,
      700,
      150.0 + s * 150,
      inputCount: activeM.length,
      outputCount: 1,
    );
    final cOut = genComp(
      "OUT_${segNames[s]}",
      13,
      850,
      150.0 + s * 150,
      labels: segNames[s],
      inputCount: 1,
      outputCount: 0,
    );
    components.addAll([cOr, cOut]);

    for (int i = 0; i < activeM.length; i++) {
      addConn(minterms[activeM[i]], 0, cOr, i);
    }

    addConn(cOr, 0, cOut, 0);
  }

  final outputData = {"components": components, "connections": connections};

  File(
    'assets/4 bit to 7 segment hex decoder.json',
  ).writeAsStringSync(jsonEncode(outputData));
  print("Generated assets/4 bit to 7 segment hex decoder.json successfully");
}
