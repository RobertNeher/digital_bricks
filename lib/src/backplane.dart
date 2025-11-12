import 'dart:async';

import 'package:flutter/widgets.dart';

class Backplane extends InheritedWidget {
  Timer timer = Timer.periodic(
    Duration(seconds: 1),
    () {} as void Function(Timer timer),
  );
  bool clock = false; // Initial clock state: LOW
  int clockFrequency = 10; // Default clock frequency: 10 Hz
  final bool power = true; // Always powered on: 5 Volts (High)
  final bool ground = false; // Always grounded: 0 Volts (Low)

  Backplane({Key? key, required Widget child}) : super(key: key, child: child) {
    timer = Timer.periodic(
      Duration(milliseconds: (1000 / clockFrequency).round()),
      (Timer t) {
        clock = !clock;
      },
    );
  }

  static Backplane? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Backplane>();
  }

  @override
  bool updateShouldNotify(Backplane oldWidget) {
    return true;
  }
}
