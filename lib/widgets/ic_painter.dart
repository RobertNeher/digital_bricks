import 'package:flutter/material.dart';
import '../models/integrated_circuit.dart';
import 'gate_painter.dart';

class ICPainter extends CustomPainter {
  final IntegratedCircuit ic;

  ICPainter(this.ic);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw surrounding box
    final borderPaint = Paint()
      ..color = ic.isUnpacked ? Colors.grey : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (ic.isUnpacked) {
      // Draw dashed rectangle
      const double dashWidth = 5.0;
      const double dashSpace = 5.0;
      double startX = 0;
      double startY = 0;

      // Top
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), borderPaint);
        startX += dashWidth + dashSpace;
      }
      // Right
      while (startY < size.height) {
        canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), borderPaint);
        startY += dashWidth + dashSpace;
      }
      // Bottom
      startX = size.width;
      while (startX > 0) {
        canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), borderPaint);
        startX -= (dashWidth + dashSpace);
      }
      // Left
      startY = size.height;
      while (startY > 0) {
        canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), borderPaint);
        startY -= (dashWidth + dashSpace);
      }
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    }

    if (ic.internalComponents.isEmpty) return;

    // 1. Calculate Bounding Box of internals
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var c in ic.internalComponents) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
      // Assume approx size 50x50 for bounds calculation
      if (c.position.dx + 50 > maxX) maxX = c.position.dx + 50;
      if (c.position.dy + 50 > maxY) maxY = c.position.dy + 50;
    }

    double contentWidth = maxX - minX;
    double contentHeight = maxY - minY;

    // Avoid division by zero
    if (contentWidth <= 0) contentWidth = 1;
    if (contentHeight <= 0) contentHeight = 1;

    // 2. Calculate Scale
    // We want to fit content into 'size', with some padding
    double padding = 4.0;
    double availW = size.width - padding * 2;
    double availH = size.height - padding * 2;

    double scaleX = availW / contentWidth;
    double scaleY = availH / contentHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    // Center it
    double drawW = contentWidth * scale;
    double drawH = contentHeight * scale;
    double offsetX = (size.width - drawW) / 2;
    double offsetY = (size.height - drawH) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.translate(-minX, -minY); // Normalize to 0,0

    for (var c in ic.internalComponents) {
      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);

      // Draw component
      // We assume standard size for all components for now (e.g. 40x40 or 50x50)
      // GatePainter expects a specific size.
      // Logic from ComponentWidget: width 60, height 60 usually.
      // But segment display is dynamic.
      // Let's use a standard 40x40 for visualization to keep it simple.
      Size compSize = const Size(40, 40);

      // Use different color for visuals?
      GatePainter(type: c.type, color: Colors.black54).paint(canvas, compSize);

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ICPainter oldDelegate) {
    // For Integrated Circuits, we often need to repaint to show internal states
    // (LEDs, gates etc.) changing during simulation.
    return true;
  }
}
