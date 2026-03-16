import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

// Helper to confirm selection
Future<void> showColorPicker(
  BuildContext context,
  Color initialColor,
  ValueChanged<Color> onConfirm,
) async {
  Color picked = initialColor;
  final bool confirmed =
      await ColorPicker(
        color: initialColor,
        onColorChanged: (Color color) => picked = color,
        width: 40,
        height: 40,
        borderRadius: 4,
        spacing: 5,
        runSpacing: 5,
        wheelDiameter: 150,
        heading: Text(
          'Select color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subheading: Text(
          'Select color shade',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        wheelSubheading: Text(
          'Selected color and its shades',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        showMaterialName: true,
        showColorName: true,
        showColorCode: true,
        copyPasteBehavior: const ColorPickerCopyPasteBehavior(
          longPressMenu: true,
        ),
        materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
        colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
        colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.both: false,
          ColorPickerType.primary: false,
          ColorPickerType.accent: false,
          ColorPickerType.bw: false,
          ColorPickerType.custom: false,
          ColorPickerType.wheel: true,
        },
      ).showPickerDialog(
        context,
        constraints: const BoxConstraints(
          minHeight: 460,
          minWidth: 300,
          maxWidth: 320,
        ),
      );

  if (confirmed) {
    onConfirm(picked);
  }
}
