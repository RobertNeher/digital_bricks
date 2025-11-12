import 'package:digital_bricks/src/and_gate_simulator.dart';
import 'package:flutter/material.dart';
// Assuming your OrGateSimulator and MyOrGateApp are in the same project structure.
// If OrGateSimulator is in a separate file, you'd import it here.

void main() {
  // 1. This is the main entry point of the Dart application.
  // 2. It calls runApp() to start the Flutter framework.
  runApp(const MyApp());
}

// A simple root widget to wrap the entire application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AND Gate Simulator',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Use the MyOrGateApp (which contains the simulator) as the home screen
      home: const MyOrGateApp(),
    );
  }
}

class MyOrGateApp extends StatefulWidget {
  const MyOrGateApp({super.key});

  @override
  State<MyOrGateApp> createState() => _MyOrGateAppState();
}

class _MyOrGateAppState extends State<MyOrGateApp> {
  bool currentGateOutput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flexible AND Gate Simulation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AndGateSimulator(
            numberOfInputs: 3, // Change this number to vary the inputs
            onOutputChanged: (newOutput) {
              setState(() {
                currentGateOutput = newOutput;
              });
              // You can perform other actions here when the gate's output changes
            },
          ),
        ),
      ),
    );
  }
}
