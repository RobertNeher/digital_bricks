import 'package:flutter/cupertino.dart';

class ORGate extends StatefulWidget {
  ValueListenableBuilder<bool>? builder;
  final int n_inputs;
  late bool result = false;
  late List<ValueNotifier<bool>> inputGates;

  ORGate({this.n_inputs = 2}) {
    result = false;

    inputGates = List.generate(n_inputs, (index) {
      return ValueNotifier<bool>(false);
    });

    inputGates.forEach((inputGate) {
      inputGate.addListener(() {
        for (ValueNotifier<bool> gate in inputGates) {
          if (gate.value == true) {
            result |= true;
          }
        }
        // result = false;
      });
    });
  }

  @override
  State<ORGate> createState() => _ORGateState();
}

class _ORGateState extends State<ORGate> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
