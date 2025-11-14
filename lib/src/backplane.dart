import 'dart:async';

import 'package:flutter/widgets.dart';

class Backplane extends InheritedWidget {
  late Timer clockTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {});
  bool clock = false; // Initial clock state: Low
  final double clockFrequency = 1; // Default clock frequency: 1 Hz
  final bool power = true; // Always powered on: 5 Volts (High)
  final bool ground = false; // Always grounded: 0 Volts (Low)

  Backplane({
    super.key,
    required super.child,
    required double clockFrequency,
    required VoidCallback listener,
  }) {
    clockTimer = Timer.periodic(
      Duration(milliseconds: (1000 / clockFrequency).round()),
      (Timer t) {
        clock = !clock;
        listener();
      },
    );
  }

  static Backplane? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Backplane>();
  }

  static Backplane? of(BuildContext context) {
    final Backplane? result = maybeOf(context);
    return result!;
  }

  void dispose() {
    clockTimer.cancel();
  }

  @override
  bool updateShouldNotify(Backplane oldWidget) {
    return true;
  }
}
