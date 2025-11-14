import 'package:digital_bricks/src/and_gate_simulator.dart';
import 'package:digital_bricks/src/backplane.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(DigitalBricksApp());
}

class DigitalBricksApp extends StatelessWidget {
  final String title = 'Flexible AND Gate Simulator';
  double counter = 0;
  DigitalBricksApp({super.key});

  VoidCallback get listener => () {
    print(counter++);
  };

  @override
  Widget build(BuildContext context) {
    counter = 0;
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      // Use the MyOrGateApp (which contains the simulator) as the home screen
      home: Backplane(
        clockFrequency: 1,
        listener: listener,
        child: MyOrGateApp(title: title),
      ), // No-op listener for Backplane
    );
  }
}

class MyOrGateApp extends StatefulWidget {
  final String title;
  const MyOrGateApp({super.key, required this.title});

  @override
  State<MyOrGateApp> createState() => _MyOrGateAppState();
}

class _MyOrGateAppState extends State<MyOrGateApp> {
  bool currentGateOutput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ANDGateSimulator(
            numberOfInputs: 3, // Change this number to vary the inputs
            onOutputChanged: (newOutput) {
              setState(() {
                currentGateOutput = newOutput;
              });
            },
          ),
        ),
      ),
    );
  }
}
