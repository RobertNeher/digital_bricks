import 'package:flutter/material.dart';
import '../models/logic_component.dart';

class SelectionBar extends StatelessWidget {
  const SelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, // Increased width for categories
      color: Colors.grey[200],
      child: ListView(
        children: [
          _buildCategory("General", [ComponentType.markdownText]),
          _buildCategory("Basic Circuits", [
            ComponentType.and,
            ComponentType.nand,
            ComponentType.or,
            ComponentType.nor,
            ComponentType.xor,
            ComponentType.nxor,
            ComponentType.inverter,
          ]),
          _buildCategory("Input/Output", [
            ComponentType.circuitInput,
            ComponentType.circuitOutput,
            ComponentType.oscillator,
            ComponentType.led,
            ComponentType.segment7,
            ComponentType.segment16,
            ComponentType.button,
          ]),
          _buildCategory("Flip-flops", [
            ComponentType.dFlipFlop,
            ComponentType.jkFlipFlop,
            ComponentType.rsFlipFlop,
          ]),
          // Spacer for bottom
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<ComponentType> types) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: EdgeInsets.zero,
      children: types.map((type) => _buildDraggable(type)).toList(),
    );
  }

  Widget _buildDraggable(ComponentType type) {
    String label = _getComponentLabel(type);
    return Draggable<ComponentType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            color: Colors.white.withAlpha(80),
          ),
          child: Text(label),
        ),
      ),
      child: Tooltip(
        message: type.name.toUpperCase(),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 16),
          title: Text(label, style: const TextStyle(fontSize: 11)),
          leading: const Icon(Icons.drag_indicator, size: 16),
        ),
      ),
    );
  }

  String _getComponentLabel(ComponentType type) {
    switch (type) {
      case ComponentType.and:
        return "&";
      case ComponentType.nand:
        return "& ▷";
      case ComponentType.or:
        return "≥1";
      case ComponentType.nor:
        return "≥1 ▷";
      case ComponentType.xor:
        return "=1";
      case ComponentType.nxor:
        return "=1 ▷";
      case ComponentType.inverter:
        return "1 ▷";
      case ComponentType.markdownText:
        return "Text";
      case ComponentType.dFlipFlop:
        return "D type";
      case ComponentType.jkFlipFlop:
        return "JK type";
      case ComponentType.rsFlipFlop:
        return "RS type";
      default:
        return type.name.toUpperCase();
    }
  }
}
