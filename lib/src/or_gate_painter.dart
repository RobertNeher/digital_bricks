import 'package:flutter/material.dart';

class OrGatePainter extends CustomPainter {
  final List<bool> inputs;
  final bool output;
  final List<Color> inputColors;
  final Color outputColor;

  OrGatePainter({
    required this.inputs,
    required this.output,
    required this.inputColors,
    required this.outputColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;

    // --- 1. Draw the OR Gate Shape ---

    final gatePaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Path path = Path();

    // Starting point (back-left corner)
    path.moveTo(centerX - 50, centerY - 40);

    // Front arc (curved part)
    // Bezier curve to simulate the OR gate's front-facing shape
    path.cubicTo(
      centerX - 30,
      centerY - 60, // Control point 1 (pull up)
      centerX + 70,
      centerY - 20, // Control point 2 (pull right-up)
      centerX + 70,
      centerY, // End point (center-right)
    );
    path.cubicTo(
      centerX + 70,
      centerY + 20, // Control point 1 (pull right-down)
      centerX - 30,
      centerY + 60, // Control point 2 (pull down)
      centerX - 50,
      centerY + 40, // End point (back-left corner)
    );

    // Back curve (the rounded rear of the gate)
    path.arcToPoint(
      Offset(centerX - 50, centerY - 40), // Target point (start of the gate)
      radius: const Radius.circular(50.0), // The radius of the arc
      clockwise: false,
      largeArc: true,
    );

    // Draw the gate's body
    canvas.drawPath(path, gatePaint);

    // --- 2. Draw Inputs and Output ---

    final double inputSpacing = height / (inputs.length + 1);

    // Draw Input Lines and Status
    for (int i = 0; i < inputs.length; i++) {
      final double inputY = (i + 1) * inputSpacing;
      final inputColor = inputColors[i];
      final inputPaint = Paint()
        ..color = inputColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Draw input line
      canvas.drawLine(
        Offset(centerX - 90, inputY),
        Offset(centerX - 50, inputY),
        inputPaint,
      );

      // Draw a small circle/dot for the input
      canvas.drawCircle(Offset(centerX - 90, inputY), 4, inputPaint);
    }

    // Draw Output Line and Status
    final outputPaint = Paint()
      ..color = outputColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Output line (from the center-right of the gate)
    canvas.drawLine(
      Offset(centerX + 70, centerY),
      Offset(centerX + 110, centerY),
      outputPaint,
    );

    // Draw a small circle/dot for the output
    canvas.drawCircle(Offset(centerX + 110, centerY), 4, outputPaint);

    // Optional: Draw 'OR' text
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: 'OR', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2 + 10,
        centerY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant OrGatePainter oldDelegate) {
    // Repaint only if the number of inputs or the state of inputs/output changes
    return oldDelegate.inputs.length != inputs.length ||
        oldDelegate.inputs.toString() != inputs.toString() ||
        oldDelegate.output != output;
  }
}
