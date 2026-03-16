import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;
  final Color backgroundColor;
  final ValueListenable<Matrix4> listenable;

  GridPainter({
    required this.gridSize,
    required this.listenable,
    this.gridColor = const Color(0xFFE0E0E0),
    this.backgroundColor = const Color(0xFFFAFAFA),
  }) : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw solid background first
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final Matrix4 transform = listenable.value;
    final double scale = transform.entry(0, 0); // uniform scale
    // Translation is negative of the viewport position
    final double tx = transform.entry(0, 3);
    final double ty = transform.entry(1, 3);

    // Calculate the visible world area
    // Screen (0,0) -> World (-tx/scale, -ty/scale)
    // Screen (w,h) -> World ((w-tx)/scale, (h-ty)/scale)

    final double left = -tx / scale;
    final double top = -ty / scale;
    final double right = (size.width - tx) / scale;
    final double bottom = (size.height - ty) / scale;

    final Paint paint = Paint()
      ..color = gridColor
      ..strokeWidth =
          1.0 /
          scale // Keep line width constant on screen or let it zoom?
      // Usually grid lines should stay thin or scale. Let's keep them 1.0 logic size likely.
      // If we want 1 pixel on screen, we use 1.0. If we use scale, they get thick.
      // Let's stick to 1.0 world width for now, or maybe adjust.
      // Actually standard behavior is lines get thicker as you zoom in.
      // So strokeWidth = 1.0 is correct in world space.
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Adjust grid starting points to align with the grid
    final double firstVerticalLine = (left / gridSize).floor() * gridSize;
    final double firstHorizontalLine = (top / gridSize).floor() * gridSize;

    // We need to apply the transform to the canvas to draw in world coordinates
    // BUT we want to draw an infinite grid.
    // Easier approach: Draw "world" lines projected to screen, OR transform canvas.

    // If we transform canvas, we simply draw lines from 'left' to 'right'.
    canvas.save();
    canvas.transform(transform.storage);

    // Draw Vertical lines
    // We iterate from just before the visible left to visible right
    for (double x = firstVerticalLine; x <= right; x += gridSize) {
      canvas.drawLine(
        Offset(x, top - gridSize),
        Offset(x, bottom + gridSize),
        paint,
      );
    }

    // Draw Horizontal lines
    for (double y = firstHorizontalLine; y <= bottom; y += gridSize) {
      canvas.drawLine(
        Offset(left - gridSize, y),
        Offset(right + gridSize, y),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.listenable != listenable ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
  }
}
