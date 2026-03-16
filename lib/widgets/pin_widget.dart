import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pin.dart';
import '../models/connection.dart';
import '../circuit_provider.dart';

class PinWidget extends StatelessWidget {
  final Pin pin;

  const PinWidget({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    // Pin color based on value
    // We can assume red = true, gray/black = false
    Color color = pin.value ? Colors.red : Colors.grey;

    final provider = Provider.of<CircuitProvider>(context);
    Connection? inputConnection;

    if (pin.type == PinType.input) {
      try {
        inputConnection = provider.connections.firstWhere(
          (c) => c.targetPinId == pin.id,
        );
      } catch (_) {}
    }

    String dragData = pin.id;
    if (inputConnection != null) {
      dragData = inputConnection.sourcePinId;
    }

    return DragTarget<String>(
      onWillAccept: (data) =>
          data != null && data != pin.id, // Can't connect to self
      onAccept: (sourcePinId) {
        Provider.of<CircuitProvider>(
          context,
          listen: false,
        ).addConnection(sourcePinId, pin.id);
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<String>(
          data: dragData,
          onDragStarted: () {
            if (inputConnection != null) {
              Provider.of<CircuitProvider>(
                context,
                listen: false,
              ).removeConnection(inputConnection.id);
            }
          },
          feedback: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: color.withAlpha(128),
              shape: BoxShape.circle,
            ),
          ),
          child: Container(
            width: 24, // Increased hit target
            height: 24,
            alignment: Alignment.center,
            color: Colors.transparent, // Capture taps
            child: Container(
              width: 12, // Visible Size
              height: 12, // Visible Size
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty ? Colors.blue : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
            ),
          ),
        );
      },
    );
  }
}
