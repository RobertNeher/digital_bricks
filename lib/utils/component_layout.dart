import 'package:flutter/material.dart';
import '../models/logic_component.dart';
import '../models/io_devices.dart';
import '../models/integrated_circuit.dart';
import '../models/markdown_component.dart';

extension Vec2ToOffset on Vec2 {
  Offset toOffset() => Offset(dx, dy);
}

extension OffsetToVec2 on Offset {
  Vec2 toVec2() => Vec2(dx, dy);
}

class ComponentLayoutMetadata {
  final double totalWidth;
  final double totalHeight;
  final double inputColWidth;
  final double bodyWidth;
  final double bodyHeight;
  final double outputColWidth;

  ComponentLayoutMetadata({
    required this.totalWidth,
    required this.totalHeight,
    required this.inputColWidth,
    required this.bodyWidth,
    required this.bodyHeight,
    required this.outputColWidth,
  });

  Size get size => Size(totalWidth, totalHeight);
}

class ComponentLayout {
  static const double baseHeight = 60.0;
  static const double baseWidth = 60.0;
  static const double heightPerPin = 24.0;
  static const double pinSize = 24.0; // The container size in PinWidget

  static ComponentLayoutMetadata getLayoutMetadata(LogicComponent component) {
    // 1. Calculate Body Dimensions
    double bodyHeight = baseHeight;
    int maxPins = component.inputs.length > component.outputs.length
        ? component.inputs.length
        : component.outputs.length;

    if (maxPins > 2) {
      bodyHeight = maxPins * heightPerPin;
      if (bodyHeight < baseHeight) bodyHeight = baseHeight;
    }

    double bodyWidth = baseWidth;
    if (component is MarkdownComponent) {
      bodyWidth = 250.0;
      final textPainter = TextPainter(
        text: TextSpan(
          text: component.text,
          style: const TextStyle(fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: bodyWidth - 24);
      double multiplier = component.text.contains('|') ? 4.0 : 2.0;
      bodyHeight = (textPainter.height * multiplier) + 80.0;
    } else if (component is IntegratedCircuit) {
      bodyWidth = 120.0;
      // Height is already handled by maxPins logic
    } else if (component is SegmentDisplay) {
      double fontH = component.fontSize;
      if (fontH < 30) fontH = 30;
      double pinH = component.inputs.length * heightPerPin;
      bodyHeight = fontH > pinH ? fontH : pinH;
      bodyHeight += 10;
      bodyWidth = fontH * (component.segments == 7 ? 0.6 : 0.8);
    }

    // 2. Calculate Column Widths (Pins + Labels)
    bool anyInputLabel = component.inputs.any((p) => p.label != null);
    if (component is SegmentDisplay) anyInputLabel = true;

    bool anyOutputLabel = component.outputs.any((p) => p.label != null);

    double inputColWidth = pinSize + (anyInputLabel ? 48.0 : 0);
    double outputColWidth = pinSize + (anyOutputLabel ? 48.0 : 0);

    double totalWidth =
        inputColWidth +
        bodyWidth +
        outputColWidth +
        8.0; // +8 for 4px horizontal padding
    double totalHeight = bodyHeight + 8.0; // +8 for 4px vertical padding

    return ComponentLayoutMetadata(
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      inputColWidth: inputColWidth,
      bodyWidth: bodyWidth,
      bodyHeight: bodyHeight,
      outputColWidth: outputColWidth,
    );
  }

  static Size getComponentSize(LogicComponent component) {
    return getLayoutMetadata(component).size;
  }

  static Offset getPinPosition(
    LogicComponent component,
    int pinIndex,
    bool isInput,
  ) {
    final meta = getLayoutMetadata(component);

    // X position: Center of PinWidget (24x24)
    // Pins are now inner-aligned: adjacent to the body.
    // Account for 4.0 padding from Container
    double centerX = isInput
        ? (4.0 + meta.inputColWidth - (pinSize / 2))
        : (4.0 + meta.inputColWidth + meta.bodyWidth + (pinSize / 2));

    // Y position: spaceEvenly Column
    int count = isInput ? component.inputs.length : component.outputs.length;
    double space = (meta.totalHeight - (count * pinSize)) / (count + 1);
    if (space < 0) space = 0;

    double centerY =
        space * (pinIndex + 1) + pinSize * pinIndex + (pinSize / 2);

    return (component.position + Vec2(centerX, centerY)).toOffset();
  }
}
