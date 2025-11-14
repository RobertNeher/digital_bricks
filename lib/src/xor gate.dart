import 'package:flutter/material.dart';

class XORGate extends StatefulWidget {
  ValueListenableBuilder<bool>? builder;
  final int n_inputs;
  late bool result = false;
  late List<ValueNotifier<bool>> inputGates;

  XORGate({this.n_inputs = 2}) {
    result = false;

    inputGates = List.generate(n_inputs, (index) {
      return ValueNotifier<bool>(false);
    });

    inputGates.forEach((inputGate) {
      inputGate.addListener(() {
        int count = 0;
        for (ValueNotifier<bool> gate in inputGates) {
          if (gate.value) {
            count++;
          }
        }
        print('Count: $count');
        result = (count % 2 != 0);
      });
    });
  }

  @override
  State<XORGate> createState() => _ORGateState();
}

class _ORGateState extends State<XORGate> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
