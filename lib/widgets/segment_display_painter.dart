import 'package:flutter/material.dart';

class SegmentDisplayPainter extends CustomPainter {
  final int mask; // 16-bit mask (or 8-bit for 7-seg)
  final Color color;
  final Color backgroundColor;
  final Color bodyColor;
  final double strokeWidth;
  final bool is7Segment;

  SegmentDisplayPainter({
    required this.mask,
    required this.color,
    required this.backgroundColor,
    required this.bodyColor,
    this.strokeWidth = 3.0,
    this.is7Segment = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background body
    final paintBody = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paintBody);

    if (is7Segment) {
      _paint7Seg(canvas, size);
    } else {
      _paint16Seg(canvas, size);
    }
  }

  void _paint7Seg(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Add Padding to create a bezel/border effect for the body color
    final double paddingX = w * 0.1;
    final double paddingY = h * 0.05;

    final double effW = w - 2 * paddingX;
    final double effH = h - 2 * paddingY;

    // Config for 7-segment look based on effective size
    final double thickness =
        effW * 0.18; // Slightly thicker relative to smaller width
    final double gap = 1.0;

    final paintOn = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintOff = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    void draw(int bit, Path path) {
      bool isOn = (mask & (1 << bit)) != 0;
      canvas.drawPath(path, isOn ? paintOn : paintOff);
    }

    // Use effW and effH for calculations, and offset by paddingX, paddingY

    // Helper to create a horizontal hexagon
    Path horizHex(double x, double y, double width, double thickness) {
      // Shift by padding
      double px = x + paddingX;
      double py = y + paddingY;

      double t = thickness;
      double ht = t / 2;

      Path p = Path();
      p.moveTo(px + ht, py);
      p.lineTo(px + width - ht, py);
      p.lineTo(px + width, py + ht);
      p.lineTo(px + width - ht, py + t);
      p.lineTo(px + ht, py + t);
      p.lineTo(px, py + ht);
      p.close();
      return p;
    }

    // Helper to create a vertical hexagon
    Path vertHex(double x, double y, double height, double thickness) {
      double px = x + paddingX;
      double py = y + paddingY;

      double t = thickness;
      double ht = t / 2;

      Path p = Path();
      p.moveTo(px + ht, py);
      p.lineTo(px + t, py + ht);
      p.lineTo(px + t, py + height - ht);
      p.lineTo(px + ht, py + height);
      p.lineTo(px, py + height - ht);
      p.lineTo(px, py + ht);
      p.close();
      return p;
    }

    // Logic uses effW, effH now
    // A (Top)
    draw(
      0,
      horizHex(thickness / 2 + gap, 0, effW - thickness - 2 * gap, thickness),
    );

    // B (Top Right)
    draw(
      1,
      vertHex(
        effW - thickness,
        thickness / 2 + gap,
        effH / 2 - thickness - 2 * gap,
        thickness,
      ),
    );

    // C (Bot Right)
    draw(
      2,
      vertHex(
        effW - thickness,
        effH / 2 + thickness / 2 + gap,
        effH / 2 - thickness - 2 * gap,
        thickness,
      ),
    );

    // D (Bot)
    draw(
      3,
      horizHex(
        thickness / 2 + gap,
        effH - thickness,
        effW - thickness - 2 * gap,
        thickness,
      ),
    );

    // E (Bot Left)
    draw(
      4,
      vertHex(
        0,
        effH / 2 + thickness / 2 + gap,
        effH / 2 - thickness - 2 * gap,
        thickness,
      ),
    );

    // F (Top Left)
    draw(
      5,
      vertHex(
        0,
        thickness / 2 + gap,
        effH / 2 - thickness - 2 * gap,
        thickness,
      ),
    );

    // G (Middle)
    draw(
      6,
      horizHex(
        thickness / 2 + gap,
        effH / 2 - thickness / 2,
        effW - thickness - 2 * gap,
        thickness,
      ),
    );

    // DP (Decimal Point)
    bool isDpOn = (mask & (1 << 7)) != 0;
    canvas.drawCircle(
      Offset(w - paddingX / 2, h - paddingY * 1.5),
      thickness / 2.5,
      isDpOn ? paintOn : paintOff,
    );
  }

  void _paint16Seg(Canvas canvas, Size size) {
    // Add Padding
    final double paddingX = size.width * 0.1;
    final double paddingY = size.height * 0.05;

    final double w = size.width - 2 * paddingX;
    final double h = size.height - 2 * paddingY;

    // Shift canvas to inside padding
    canvas.save();
    canvas.translate(paddingX, paddingY);

    // Dynamic stroke width for 16-segment scaling
    // User requested increased thickness.
    // Try 8% of width.
    double localStroke = w * 0.12;
    if (localStroke < 3.0) localStroke = 3.0;

    final double gap = localStroke / 2;

    final paintOn = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = localStroke;

    final paintOff = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = localStroke;

    void drawSeg(int bit, Path path) {
      bool isOn = (mask & (1 << bit)) != 0;
      canvas.drawPath(path, isOn ? paintOn : paintOff);
    }

    // Paths definition

    // Top Horizontal (A1, A2)
    Path pA1 = Path()
      ..moveTo(gap, 0)
      ..lineTo(w / 2 - gap, 0);
    Path pA2 = Path()
      ..moveTo(w / 2 + gap, 0)
      ..lineTo(w - gap, 0);

    // Right Vertical (B, C)
    Path pB = Path()
      ..moveTo(w, gap)
      ..lineTo(w, h / 2 - gap);
    Path pC = Path()
      ..moveTo(w, h / 2 + gap)
      ..lineTo(w, h - gap);

    // Bottom Horizontal (D1, D2) --> D1 is Right, D2 is Left
    Path pD1 = Path()
      ..moveTo(w / 2 + gap, h)
      ..lineTo(w - gap, h);
    Path pD2 = Path()
      ..moveTo(gap, h)
      ..lineTo(w / 2 - gap, h);

    // Left Vertical (E, F) --> E is Bottom, F is Top
    Path pE = Path()
      ..moveTo(0, h / 2 + gap)
      ..lineTo(0, h - gap);
    Path pF = Path()
      ..moveTo(0, gap)
      ..lineTo(0, h / 2 - gap);

    // Middle Horizontal (G1, G2) -> G1 Left, G2 Right
    Path pG1 = Path()
      ..moveTo(gap, h / 2)
      ..lineTo(w / 2 - gap, h / 2);
    Path pG2 = Path()
      ..moveTo(w / 2 + gap, h / 2)
      ..lineTo(w - gap, h / 2);

    // Inner Verticals (I, L) -> I Top, L Bottom
    Path pI = Path()
      ..moveTo(w / 2, gap)
      ..lineTo(w / 2, h / 2 - gap);
    Path pL = Path()
      ..moveTo(w / 2, h / 2 + gap)
      ..lineTo(w / 2, h - gap);

    // Diagonals
    // H (Top Left)
    Path pH = Path()
      ..moveTo(gap, gap)
      ..lineTo(w / 2 - gap, h / 2 - gap);
    // J (Top Right)
    Path pJ = Path()
      ..moveTo(w - gap, gap)
      ..lineTo(w / 2 + gap, h / 2 - gap);
    // K (Bottom Right)
    Path pK = Path()
      ..moveTo(w / 2 + gap, h / 2 + gap)
      ..lineTo(w - gap, h - gap);
    // M (Bottom Left)
    Path pM = Path()
      ..moveTo(w / 2 - gap, h / 2 + gap)
      ..lineTo(gap, h - gap);

    // Draw in order of bits defined in SegmentPatterns
    // 0: A1, 1: A2
    drawSeg(0, pA1);
    drawSeg(1, pA2);
    // 2: B, 3: C
    drawSeg(2, pB);
    drawSeg(3, pC);
    // 4: D1, 5: D2
    drawSeg(4, pD1);
    drawSeg(5, pD2);
    // 6: E, 7: F
    drawSeg(6, pE);
    drawSeg(7, pF);

    // 8: G1, 9: G2
    drawSeg(8, pG1);
    drawSeg(9, pG2);

    // 10: H (TL Diag)
    drawSeg(10, pH);
    // 11: I (Top Vert)
    drawSeg(11, pI);
    // 12: J (Top Right Diag)
    drawSeg(12, pJ);

    // 13: K (Bot Right Diag)
    drawSeg(13, pK);
    // 14: L (Bot Vert)
    drawSeg(14, pL);
    // 15: M (Bot Left Diag)
    drawSeg(15, pM);

    canvas.restore();

    // DP (Decimal Point)
    bool isDpOn = (mask & (1 << 16)) != 0;
    final paintOnFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final paintOffFill = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width - paddingX / 2, size.height - paddingY * 1.5),
      localStroke / 1.5,
      isDpOn ? paintOnFill : paintOffFill,
    );
  }

  @override
  bool shouldRepaint(covariant SegmentDisplayPainter oldDelegate) {
    return oldDelegate.mask != mask ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.is7Segment != is7Segment;
  }
}
