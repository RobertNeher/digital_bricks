import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../utils/component_layout.dart';
import '../models/logic_component.dart';
import '../models/gates.dart';
import '../models/io_devices.dart';
import '../models/circuit_io.dart';
import 'gate_painter.dart';
import 'color_picker_dialog.dart';
import 'pin_widget.dart';
import 'segment_display_painter.dart';
import 'ic_painter.dart';
import '../models/integrated_circuit.dart';
import '../models/markdown_component.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../utils/segment_patterns.dart';

class ComponentWidget extends StatelessWidget {
  final LogicComponent component;

  const ComponentWidget({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final meta = ComponentLayout.getLayoutMetadata(component);

    Color? containerColor;
    if (component is SegmentDisplay) {
      containerColor = Color((component as SegmentDisplay).bodyColor);
    }

    return Container(
      width: meta.totalWidth,
      height: meta.totalHeight,
      padding: const EdgeInsets.all(4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (containerColor != null)
            Positioned(
              left: meta.inputColWidth,
              width: meta.bodyWidth,
              top: 0,
              bottom: 0,
              child: Container(color: containerColor),
            ),
          Row(
            children: [
              // Inputs Column
              SizedBox(
                width: meta.inputColWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:
                      (component is IntegratedCircuit &&
                          (component as IntegratedCircuit).isUnpacked)
                      ? []
                      : component.inputs.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Widget pw = PinWidget(pin: entry.value);
                          String? label;
                          if (component is SegmentDisplay) {
                            label =
                                entry.value.label ??
                                (component.inputs.length - 1 - idx).toString();
                          } else {
                            label = entry.value.label;
                          }

                          if (label != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                pw,
                              ],
                            );
                          }
                          return pw;
                        }).toList(),
                ),
              ),

              // Body area
              Expanded(
                child: Selector<CircuitProvider, bool>(
                  selector: (_, p) => p.isSelected(component.id),
                  builder: (context, isSelected, child) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          (component is MarkdownComponent &&
                              (component as MarkdownComponent).isEditing)
                          ? null
                          : () {
                              if (component is ButtonComponent) {
                                (component as ButtonComponent).toggle();
                              }
                              // Toggle selection (including for buttons)
                              Provider.of<CircuitProvider>(
                                context,
                                listen: false,
                              ).toggleComponentSelection(component.id);
                            },
                      onDoubleTap: (component is MarkdownComponent)
                          ? () {
                              (component as MarkdownComponent).isEditing = true;
                              Provider.of<CircuitProvider>(
                                context,
                                listen: false,
                              ).refresh();
                            }
                          : null,
                      onPanStart: (details) {
                        final provider = Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        );
                        provider.saveCheckpoint();
                        // If we start dragging a component that isn't selected, select it.
                        if (!provider.isSelected(component.id)) {
                          provider.selectComponent(
                            component.id,
                            additive: false,
                          );
                        }
                      },
                      onPanUpdate:
                          (component is MarkdownComponent &&
                              (component as MarkdownComponent).isEditing)
                          ? null
                          : (details) {
                              final provider = Provider.of<CircuitProvider>(
                                context,
                                listen: false,
                              );
                              if (provider.isSelected(component.id)) {
                                provider.moveSelectedComponents(details.delta);
                              } else {
                                provider.updateComponentPosition(
                                  component.id,
                                  details.delta,
                                );
                              }
                            },
                      onSecondaryTapDown: (details) =>
                          _showContextMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.grey[200]
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : (component is MarkdownComponent
                                      ? Colors.transparent
                                      : Colors.grey[300]!),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            if (component is SegmentDisplay)
                              Center(
                                child: _buildSegmentDisplayContent(
                                  component as SegmentDisplay,
                                ),
                              )
                            else if (component is Led)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      color:
                                          ((component as Led)
                                                  .inputs
                                                  .isNotEmpty &&
                                              (component as Led)
                                                  .inputs[0]
                                                  .value)
                                          ? Color((component as Led).colorHigh)
                                          : Color((component as Led).colorLow),
                                      size: 32,
                                    ),
                                    if ((component as Led).label.isNotEmpty)
                                      Text(
                                        (component as Led).label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              )
                            else if (component is IntegratedCircuit)
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity:
                                          (component as IntegratedCircuit)
                                              .isUnpacked
                                          ? 0.3
                                          : 1.0,
                                      child: CustomPaint(
                                        painter: ICPainter(
                                          component as IntegratedCircuit,
                                        ),
                                        size: Size(
                                          meta.bodyWidth - 10,
                                          meta.bodyHeight - 10,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        component.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (component is! MarkdownComponent)
                              // Fallback to GatePainter for everything else (Logic Gates, FlipFlops, IO, etc.)
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: Size(
                                        meta.bodyWidth - 10,
                                        meta.totalHeight - 20,
                                      ),
                                      painter: GatePainter(
                                        type: component.type,
                                        isActive: component is ButtonComponent
                                            ? (component as ButtonComponent)
                                                  .isPressed
                                            : false,
                                      ),
                                    ),
                                    if (component is CircuitInput)
                                      Text(
                                        (component as CircuitInput).label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (component is CircuitOutput)
                                      Text(
                                        (component as CircuitOutput).label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (component is ButtonComponent)
                                      Text(
                                        (component as ButtonComponent).label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (component.name.isNotEmpty &&
                                        component.name.length <= 4)
                                      Text(
                                        component.name,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            if (component is MarkdownComponent)
                              Positioned.fill(
                                child: FocusScope(
                                  child: _MarkdownEditorWidget(
                                    key: ValueKey('md_editor_${component.id}'),
                                    component: component as MarkdownComponent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Outputs Column
              SizedBox(
                width: meta.outputColWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      (component is IntegratedCircuit &&
                          (component as IntegratedCircuit).isUnpacked)
                      ? []
                      : component.outputs.asMap().entries.map((entry) {
                          Widget pw = PinWidget(pin: entry.value);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              pw,
                              if (entry.value.label != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    entry.value.label!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentDisplayContent(SegmentDisplay display) {
    int mask;
    bool is7Seg = display.segments == 7;

    if (is7Seg) {
      // Raw segment control: pin i corresponds to bit i
      mask = 0;
      for (int i = 0; i < display.inputs.length; i++) {
        if (display.inputs[i].value) {
          mask |= (1 << i);
        }
      }
    } else {
      // 16-segment ASCII mode
      int asciiVal = 0;
      // First 7 pins are ASCII bits (Top to Bottom: bits 6 down to 0)
      for (int i = 0; i < 7 && i < display.inputs.length; i++) {
        if (display.inputs[i].value) {
          asciiVal |= (1 << (6 - i));
        }
      }
      mask = SegmentPatterns.getMask(asciiVal);

      // 8th pin (index 7) is DP -> bit 16 in mask
      if (display.inputs.length > 7 && display.inputs[7].value) {
        mask |= (1 << 16);
      }
    }

    double h = display.fontSize;
    // Adjust aspect ratio based on type
    double w = h * (is7Seg ? 0.6 : 0.8);

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: SegmentDisplayPainter(
          mask: mask,
          color: Color(display.color),
          backgroundColor: Color(display.backgroundColor),
          bodyColor: Color(display.bodyColor),
          is7Segment: is7Seg,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).removeComponent(component.id);
                Navigator.pop(ctx);
              },
            ),
            if (component is MultiInputGate)
              ListTile(
                leading: const Icon(Icons.settings_input_component),
                title: const Text('Change Inputs'),
                trailing: DropdownButton<int>(
                  value: (component as MultiInputGate).inputCount,
                  items: [2, 3, 4, 8]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      (component as MultiInputGate).updateInputCount(val);
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
            if (component is Oscillator)
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Frequency'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFreqDialog(context, component as Oscillator);
                },
              ),
            if (component is ConstantSource)
              StatefulBuilder(
                builder: (context, setState) {
                  return ListTile(
                    leading: const Icon(Icons.power_settings_new),
                    title: const Text('Toggle High/Low'),
                    trailing: Switch(
                      value: (component as ConstantSource).state,
                      onChanged: (val) {
                        (component as ConstantSource).setState(val);
                        Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        ).refresh();
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            if (component is Led)
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Set Colors'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showColorDialog(context, component as Led);
                },
              ),
            if (component is SegmentDisplay) ...[
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Set Active Segment Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentColorDialog(context, component as SegmentDisplay);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_paint),
                title: const Text('Set Inactive Segment Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentBackgroundColorDialog(
                    context,
                    component as SegmentDisplay,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: const Text('Set Body Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentBodyColorDialog(
                    context,
                    component as SegmentDisplay,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Set Font Size'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentSizeDialog(context, component as SegmentDisplay);
                },
              ),
            ],
            if (component is CircuitInput ||
                component is CircuitOutput ||
                component is ButtonComponent ||
                component is Led)
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Edit Label'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLabelDialog(context, component);
                },
              ),
            if (component is MarkdownComponent)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Text'),
                onTap: () {
                  (component as MarkdownComponent).isEditing = true;
                  Provider.of<CircuitProvider>(
                    context,
                    listen: false,
                  ).refresh();
                  Navigator.pop(ctx);
                },
              ),
            if (component is IntegratedCircuit) ...[
              if ((component as IntegratedCircuit).isUnpacked)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Repack'),
                  onTap: () {
                    Provider.of<CircuitProvider>(
                      context,
                      listen: false,
                    ).repackExistingIC(component.id);
                    Navigator.pop(ctx);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.unarchive),
                  title: const Text('Unpack'),
                  onTap: () {
                    final provider = Provider.of<CircuitProvider>(
                      context,
                      listen: false,
                    );
                    if (provider.hasUnpackedComponents) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Only one circuit can be unpacked on canvas at a time.",
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      provider.unpackIntegratedCircuit(component.id);
                    }
                    Navigator.pop(ctx);
                  },
                ),
            ],
            Builder(
              builder: (context) {
                final parentIC = Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).findParentIC(component.id);
                if (parentIC != null) {
                  return ListTile(
                    leading: const Icon(Icons.archive),
                    title: Text('Repack Parent (${parentIC.name})'),
                    onTap: () {
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).repackExistingIC(parentIC.id);
                      Navigator.of(context).pop();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFreqDialog(BuildContext context, Oscillator osc) {
    TextEditingController controller = TextEditingController(
      text: osc.frequency.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Frequency (Hz)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Frequency (Hz)"),
          onSubmitted: (value) {
            double? v = double.tryParse(value);
            if (v != null) {
              osc.frequency = v;
              Provider.of<CircuitProvider>(context, listen: false).refresh();
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              double? v = double.tryParse(controller.text);
              if (v != null) {
                osc.frequency = v;
                Provider.of<CircuitProvider>(context, listen: false).refresh();
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showColorDialog(BuildContext context, Led led) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("LED Colors"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("High Output Color"),
                  onTap: () async {
                    await showColorPicker(context, Color(led.colorHigh), (c) {
                      led.colorHigh = c.value;
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                      setState(() {});
                    });
                  },
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(led.colorHigh),
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("Low Output Color"),
                  onTap: () async {
                    await showColorPicker(context, Color(led.colorLow), (c) {
                      led.colorLow = c.value;
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                      setState(() {});
                    });
                  },
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(led.colorLow),
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSegmentColorDialog(BuildContext context, SegmentDisplay display) {
    showColorPicker(context, Color(display.color), (c) {
      display.color = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
  }

  void _showSegmentBackgroundColorDialog(
    BuildContext context,
    SegmentDisplay display,
  ) {
    showColorPicker(context, Color(display.backgroundColor), (c) {
      display.backgroundColor = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
  }

  void _showSegmentBodyColorDialog(
    BuildContext context,
    SegmentDisplay display,
  ) {
    showColorPicker(context, Color(display.bodyColor), (c) {
      display.bodyColor = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
  }

  void _showSegmentSizeDialog(BuildContext context, SegmentDisplay display) {
    TextEditingController sizeCtrl = TextEditingController(
      text: display.fontSize.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Font Size"),
        content: TextField(
          controller: sizeCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Size (pixels)"),
          onSubmitted: (value) {
            double? s = double.tryParse(value);
            if (s != null) {
              if (s < 30) s = 30; // Enforce minimum
              display.fontSize = s;
              Provider.of<CircuitProvider>(context, listen: false).refresh();
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              double? s = double.tryParse(sizeCtrl.text);
              if (s != null) {
                if (s < 30) s = 30; // Enforce minimum
                display.fontSize = s;
                Provider.of<CircuitProvider>(context, listen: false).refresh();
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLabelDialog(BuildContext context, LogicComponent comp) {
    String currentLabel = "";
    bool forceUppercase = comp is CircuitInput || comp is CircuitOutput;

    if (comp is CircuitInput) currentLabel = comp.label;
    if (comp is CircuitOutput) currentLabel = comp.label;
    if (comp is ButtonComponent) currentLabel = comp.label;
    if (comp is Led) currentLabel = comp.label;

    TextEditingController controller = TextEditingController(
      text: forceUppercase ? currentLabel.toUpperCase() : currentLabel,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Label"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Label"),
          textCapitalization: forceUppercase
              ? TextCapitalization.characters
              : TextCapitalization.none,
          onChanged: (value) {
            if (forceUppercase) {
              final upper = value.toUpperCase();
              if (upper != value) {
                controller.value = controller.value.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            }
          },
          onSubmitted: (value) {
            final finalLabel = forceUppercase ? value.toUpperCase() : value;
            if (comp is CircuitInput) comp.label = finalLabel;
            if (comp is CircuitOutput) comp.label = finalLabel;
            if (comp is ButtonComponent) comp.label = finalLabel;
            if (comp is Led) comp.label = finalLabel;
            Provider.of<CircuitProvider>(context, listen: false).refresh();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final finalLabel = forceUppercase
                  ? controller.text.toUpperCase()
                  : controller.text;
              if (comp is CircuitInput) comp.label = finalLabel;
              if (comp is CircuitOutput) comp.label = finalLabel;
              if (comp is ButtonComponent) comp.label = finalLabel;
              if (comp is Led) comp.label = finalLabel;
              Provider.of<CircuitProvider>(context, listen: false).refresh();
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

class _MarkdownEditorWidget extends StatefulWidget {
  final MarkdownComponent component;

  const _MarkdownEditorWidget({super.key, required this.component});

  @override
  State<_MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<_MarkdownEditorWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.component.text.isEmpty
          ? MarkdownComponent.defaultTemplate
          : widget.component.text,
    );
    // Request focus in next frame once textfield is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.component.isEditing) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.component.isEditing) {
      return TapRegion(
        onTapOutside: (event) {
          setState(() {
            widget.component.isEditing = false;
            widget.component.text = _controller.text;
            Provider.of<CircuitProvider>(context, listen: false).refresh();
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: Border.all(
                color: Colors.blue.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                autofocus: true,
                onChanged: (val) {
                  widget.component.text = val;
                  Provider.of<CircuitProvider>(
                    context,
                    listen: false,
                  ).refresh();
                },
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.black,
                  height: 1.2,
                ),
                cursorColor: Theme.of(context).primaryColor,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Enter Markdown...',
                  hintStyle: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width:
                ComponentLayout.getLayoutMetadata(widget.component).bodyWidth -
                16, // Use the component width minus padding
            child: MarkdownBody(
              shrinkWrap: true,
              fitContent: true,
              data: widget.component.text.isEmpty
                  ? MarkdownComponent.defaultTemplate
                  : widget.component.text,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: const TextStyle(color: Colors.black, fontSize: 12),
                    h1: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    tableBody: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
              extensionSet: md.ExtensionSet.gitHubFlavored,
            ),
          ),
        ),
      ),
    );
  }
}
