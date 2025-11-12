import 'package:digital_bricks/src/or_gate_painter.dart';
import 'package:flutter/material.dart';

// The main widget for the OR Gate simulator
class OrGateSimulator extends StatefulWidget {
  // A callback function to notify the parent widget when the output changes.
  final ValueChanged<bool> onOutputChanged;

  // The number of boolean inputs the gate should have.
  final int numberOfInputs;

  const OrGateSimulator({
    Key? key,
    required this.numberOfInputs,
    required this.onOutputChanged,
  }) : super(key: key);

  @override
  _OrGateSimulatorState createState() => _OrGateSimulatorState();
}

class _OrGateSimulatorState extends State<OrGateSimulator> {
  // List of booleans representing the gate's inputs.
  late List<bool> inputs;
  // The output of the OR gate (true if any input is true).
  bool output = false;

  @override
  void initState() {
    super.initState();
    // Initialize all inputs to false.
    inputs = List<bool>.filled(widget.numberOfInputs, false);
    _calculateOutput(); // Calculate initial output.
  }

  // Logic to calculate the OR gate's output: true if at least one input is true.
  void _calculateOutput() {
    bool newOutput = inputs.contains(true);
    if (newOutput != output) {
      setState(() {
        output = newOutput;
      });
      widget.onOutputChanged(output); // Notify parent of the change.
    }
  }

  // Toggles the value of a specific input.
  void _toggleInput(int index) {
    setState(() {
      inputs[index] = !inputs[index];
    });
    _calculateOutput();
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors for the visualization
    Color outputColor = output ? Colors.green : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Input Toggles (flexible number)
        Wrap(
          spacing: 8.0,
          children: List.generate(widget.numberOfInputs, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Input ${index + 1}:'),
                Switch(
                  value: inputs[index],
                  onChanged: (_) => _toggleInput(index),
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 20),

        // 2. OR Gate Visual (CustomPainter)
        SizedBox(
          width: 200,
          height: 150,
          child: CustomPaint(
            painter: OrGatePainter(
              inputs: inputs,
              output: output,
              inputColors: inputs
                  .map((b) => b ? Colors.green : Colors.red)
                  .toList(),
              outputColor: outputColor,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. Output Display
        Text(
          'Output (A or B or...): $output',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: outputColor,
          ),
        ),
      ],
    );
  }
}
