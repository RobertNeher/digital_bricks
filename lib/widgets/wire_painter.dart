import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../models/logic_component.dart';
// import '../models/gates.dart';
import '../utils/component_layout.dart';

class WirePainter extends CustomPainter {
  final List<Connection> connections;
  final List<LogicComponent> components;

  WirePainter({required this.connections, required this.components});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var conn in connections) {
      Offset? p1 = _getPinPos(conn.sourcePinId);
      Offset? p2 = _getPinPos(conn.targetPinId);

      if (p1 != null && p2 != null) {
        // Find if source pin is active
        bool isActive = false;
        // Optimization: we could pass map, but list lookup is ok for small app
        for (var c in components) {
          for (var p in c.outputs) {
            if (p.id == conn.sourcePinId) {
              isActive = p.value;
              break;
            }
          }
        }

        Path path = Path();
        path.moveTo(p1.dx, p1.dy);

        // Bezier or Manhattan routing?
        // Simple cubic bezier looks nice for hanging wires
        double dist = (p2.dx - p1.dx).abs();
        path.cubicTo(
          p1.dx + dist / 2,
          p1.dy,
          p2.dx - dist / 2,
          p2.dy,
          p2.dx,
          p2.dy,
        );

        canvas.drawPath(path, isActive ? activePaint : paint);
      }
    }
  }

  Offset? _getPinPos(String pinId) {
    for (var c in components) {
      // Check Inputs
      for (int i = 0; i < c.inputs.length; i++) {
        if (c.inputs[i].id == pinId) {
          return ComponentLayout.getPinPosition(c, i, true);
        }
      }
      // Check Outputs
      for (int i = 0; i < c.outputs.length; i++) {
        if (c.outputs[i].id == pinId) {
          return ComponentLayout.getPinPosition(c, i, false);
        }
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant WirePainter oldDelegate) {
    // Ideally check if lists changed, but for animation we just repaint
    return true;
  }
}
