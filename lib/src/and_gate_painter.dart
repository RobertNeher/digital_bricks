import 'package:flutter/material.dart';

class ANDGatePainter extends CustomPainter {
  final List<bool> inputs;
  final bool output;
  final List<Color> inputColors;
  final Color outputColor;

  ANDGatePainter({
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

    // --- 1. Draw the AND Gate Shape ---

    final gatePaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX + 10, centerY),
        width: 120,
        height: 90,
      ),
      gatePaint,
    );

    // --- 2. Draw Inputs and Output ---

    final double inputSpacing = height / (inputs.length + 1);

    // Draw Input Lines and Status
    print(inputs);
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

    // Optional: Draw 'AND' text
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 30,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: '&', style: textStyle);
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
  bool shouldRepaint(covariant ANDGatePainter oldDelegate) {
    // Repaint only if the number of inputs or the state of inputs/output changes
    return oldDelegate.inputs.length != inputs.length ||
        oldDelegate.inputs.toString() != inputs.toString() ||
        oldDelegate.output != output;
  }
}
