import 'package:flutter/material.dart';
import '../models/logic_component.dart';

class GatePainter extends CustomPainter {
  final ComponentType type;
  final Color color;
  final bool isActive;

  GatePainter({
    required this.type,
    this.color = Colors.black,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path path = Path();

    // Standard size assumed ~ width: , height:
    // Drawing logic normalized to size

    switch (type) {
      case ComponentType.and:
      case ComponentType.nand:
        _drawAnd(path, size);
        if (type == ComponentType.nand) _drawBubble(path, size);
        break;
      case ComponentType.or:
      case ComponentType.nor:
        _drawOr(path, size);
        if (type == ComponentType.nor) _drawBubble(path, size);
        break;
      case ComponentType.xor:
      case ComponentType.nxor:
        _drawXor(path, size);
        if (type == ComponentType.nxor) _drawBubble(path, size);
        break;
      case ComponentType.inverter:
        _drawInverter(path, size);
        _drawBubble(path, size);
        break;
      case ComponentType.oscillator:
        _drawBox(path, size);
        _drawOscSymbol(canvas, size, paint); // Special case
        break;
      case ComponentType.led:
        // LED is usually drawn as filled circle in the widget, but we can outline here
        _drawCircle(path, size);
        break;
      case ComponentType.segment7:
      case ComponentType.segment16:
        _drawBox(path, size);
        break;
      case ComponentType.constantSource:
        _drawBox(path, size);
        break;
      case ComponentType.circuitInput:
        _drawTerminal(canvas, size, Colors.green[200]!);
        break;
      case ComponentType.circuitOutput:
        _drawTerminal(canvas, size, Colors.red[200]!);
        break;
      case ComponentType.button:
        _drawBox(path, size);
        _drawButtonSymbol(canvas, size, isActive);
        break;
      case ComponentType.markdownText:
        _drawBox(path, size);
        break;
      case ComponentType.integratedCircuit:
        _drawBox(path, size);
        break;
      case ComponentType.dFlipFlop:
      case ComponentType.jkFlipFlop:
      case ComponentType.rsFlipFlop:
        _drawBox(path, size);
        _drawFlipFlopSymbol(canvas, size, paint, type);
        break;
    }

    canvas.drawPath(path, paint);
  }

  void _drawTerminal(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, border);
  }

  void _drawAnd(Path path, Size size) {
    // D shape
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.5, 0);

    // Draw elliptical arc
    // Rect defines the full ellipse. We use the right half.
    path.arcTo(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.5708, // -PI/2 (Top)
      3.14159, // PI (Sweep to Bottom)
      false, // forceMoveTo: false (connects line)
    );

    path.lineTo(0, size.height);
    path.close();
  }

  void _drawOr(Path path, Size size) {
    // Shield shape
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.25, size.height / 2, 0, size.height);
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height / 2,
    );
    path.quadraticBezierTo(size.width * 0.75, 0, 0, 0);
    path.close();
  }

  void _drawXor(Path path, Size size) {
    // Double curved back OR
    // First curve (back input guard)
    path.moveTo(-5, 0);
    path.quadraticBezierTo(
      size.width * 0.25 - 5,
      size.height / 2,
      -5,
      size.height,
    );

    // Main body
    path.moveTo(5, 0);
    path.quadraticBezierTo(
      size.width * 0.25 + 5,
      size.height / 2,
      5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height / 2,
    );
    path.quadraticBezierTo(size.width * 0.75, 0, 5, 0);
  }

  void _drawInverter(Path path, Size size) {
    // Triangle
    path.moveTo(0, 0);
    path.lineTo(size.width - 10, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
  }

  void _drawBubble(Path path, Size size) {
    // Small circle at tip
    // Need to find tip. For standard gates, tip is at (width, height/2) roughly
    // Adjusted by bubble size
    path.addOval(
      Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 5),
    );
  }

  void _drawBox(Path path, Size size) {
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  void _drawCircle(Path path, Size size) {
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  void _drawOscSymbol(Canvas canvas, Size size, Paint paint) {
    // Draw square wave inside
    Path p = Path();
    double h = size.height;
    double w = size.width;
    p.moveTo(w * 0.2, h * 0.7);
    p.lineTo(w * 0.2, h * 0.3);
    p.lineTo(w * 0.5, h * 0.3);
    p.lineTo(w * 0.5, h * 0.7);
    p.lineTo(w * 0.8, h * 0.7);
    p.lineTo(w * 0.8, h * 0.3);
    canvas.drawPath(p, paint);
  }

  void _drawFlipFlopSymbol(Canvas canvas, Size size, Paint paint, ComponentType type) {
    // Draw "D", "JK", or "RS" text
    String text = "";
    if (type == ComponentType.dFlipFlop) text = "D type";
    if (type == ComponentType.jkFlipFlop) text = "JK type";
    if (type == ComponentType.rsFlipFlop) text = "RS type";
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Draw clock triangle at index 0 for D (it's the 2nd pin, index 1)
    // Wait, D-FF has inputs: [CLK, D]. CLK is index 0.
    // JK-FF has inputs: [CLK, J, K]. CLK is index 0.
    
    // Position of clock triangle: left side, middle of the first pin area.
    // We assume the caller knows where the pins are or we just draw it centrally.
    final clockPath = Path();
    double cpY = 15; // Rough estimate for the first pin center
    clockPath.moveTo(0, cpY - 5);
    clockPath.lineTo(5, cpY);
    clockPath.lineTo(0, cpY + 5);
    canvas.drawPath(clockPath, paint);
  }

  void _drawButtonSymbol(Canvas canvas, Size size, bool active) {
    final paint = Paint()
      ..color = active ? Colors.green : Colors.black
      ..style = PaintingStyle.fill;

    // Draw a circle in the center
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 10, paint);
  }

  @override
  bool shouldRepaint(covariant GatePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.isActive != isActive;
  }
}
