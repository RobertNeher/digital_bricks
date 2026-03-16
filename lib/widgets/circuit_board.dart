import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../models/logic_component.dart'; // Needed for type
import '../models/connection.dart';
import 'component_widget.dart';
import 'wire_painter.dart';
import 'grid_painter.dart';
import '../utils/component_layout.dart';

class CircuitBoard extends StatefulWidget {
  const CircuitBoard({super.key});

  @override
  State<CircuitBoard> createState() => _CircuitBoardState();
}

// Intents
class DeleteIntent extends Intent {
  const DeleteIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class CancelSelectionIntent extends Intent {
  const CancelSelectionIntent();
}

class MoveIntent extends Intent {
  final Offset delta;
  const MoveIntent(this.delta);
}

class _CircuitBoardState extends State<CircuitBoard> {
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey(); // Key for the internal Container
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CircuitProvider>(context);

    // Register viewport calculator
    provider.getViewportCenter = () {
      final RenderBox? canvasBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (canvasBox != null) {
        // The center of the visible area of the CircuitBoard
        final RenderBox viewportBox = context.findRenderObject() as RenderBox;
        final Offset centerGlobal = viewportBox.localToGlobal(
          Offset(viewportBox.size.width / 2, viewportBox.size.height / 2),
        );

        // Convert to local coordinates of the canvas Container
        Offset localCenter = canvasBox.globalToLocal(centerGlobal);

        // Snap to grid
        double gs = CircuitProvider.gridSize;
        return Offset(
          (localCenter.dx / gs).round() * gs,
          (localCenter.dy / gs).round() * gs,
        );
      }
      return const Offset(500, 500); // Sensible fallback
    };

    // Canvas size
    const double canvasWidth = 10000;
    const double canvasHeight = 10000;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: false,
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.delete): const DeleteIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            const OpenIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const CancelSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveIntent(
          Offset(0, -20),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveIntent(
          Offset(0, 20),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const MoveIntent(
          Offset(-20, 0),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const MoveIntent(
          Offset(20, 0),
        ),
      },
      actions: <Type, Action<Intent>>{
        DeleteIntent: DeleteComponentAction(provider),
        SelectAllIntent: SelectAllAction(provider),
        SaveIntent: SaveCircuitAction(provider),
        OpenIntent: CallbackAction<OpenIntent>(
          onInvoke: (intent) {
            provider.loadCircuit();
            return null;
          },
        ),
        CancelSelectionIntent: CancelSelectionAction(provider),
        MoveIntent: MoveComponentAction(provider),
      },
      child: DragTarget<Object>(
        onAcceptWithDetails: (details) {
          _handleDrop(context, details.data, details.offset);
          _focusNode.requestFocus(); // Regain focus after drop
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              // Infinite Grid Layer (Background)
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(
                    gridSize: CircuitProvider.gridSize,
                    listenable: _transformController,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
              ),

              // Interactive Workspace
              InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 4.0,
                constrained: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapUp: (details) {
                    _handleSecondaryTap(
                      context,
                      details.localPosition,
                      provider,
                    );
                  },
                  onTap: () {
                    provider.clearSelection();
                  },
                  child: Container(
                    key: _canvasKey,
                    width: canvasWidth,
                    height: canvasHeight,
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Wires (Bottom layer)
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: WirePainter(
                                connections: provider.connections,
                                components: provider.components,
                              ),
                            ),
                          ),
                        ),

                        // Components
                        ...provider.components.map((comp) {
                          return Positioned(
                            key: ValueKey(comp.id),
                            left: comp.position.dx,
                            top: comp.position.dy,
                            child: ComponentWidget(
                              key: ValueKey(comp.id),
                              component: comp,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Selection Toolbar (Overlay)
              if (provider.selectedComponentIds.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.align_horizontal_left),
                            tooltip: "Align Left",
                            onPressed: () =>
                                provider.alignSelectedComponents('left'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.align_vertical_top),
                            tooltip: "Align Top",
                            onPressed: () =>
                                provider.alignSelectedComponents('top'),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 24, color: Colors.grey),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.archive,
                              color: provider.hasUnpackedComponents
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            tooltip: "Repack Selection",
                            onPressed: provider.hasUnpackedComponents
                                ? () => provider.repackSelectedComponents()
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Delete Selected",
                            onPressed: () =>
                                provider.deleteSelectedComponents(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: "Clear Selection",
                            onPressed: () => provider.clearSelection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleSecondaryTap(
    BuildContext context,
    Offset localPos,
    CircuitProvider provider,
  ) {
    // Check for wire hit
    for (var conn in provider.connections) {
      if (_isWireHit(conn, localPos, provider.components)) {
        _showWireContextMenu(context, conn.id);
        return;
      }
    }

    // Background hit
    _showCanvasContextMenu(context, localPos, provider);
  }

  void _showCanvasContextMenu(
    BuildContext context,
    Offset localPos,
    CircuitProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            if (provider.selectedComponentIds.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.archive,
                  color: provider.hasUnpackedComponents ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  "Repack Selection",
                  style: TextStyle(
                    color: provider.hasUnpackedComponents ? null : Colors.grey,
                  ),
                ),
                enabled: provider.hasUnpackedComponents,
                onTap: provider.hasUnpackedComponents
                    ? () {
                        provider.repackSelectedComponents();
                        Navigator.pop(ctx);
                      }
                    : null,
              ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text("Select All"),
              onTap: () {
                provider.selectAll();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers_clear),
              title: const Text("Clear Canvas"),
              onTap: () {
                Navigator.pop(ctx);
                // Trigger the refresh-style clearing with confirmation?
                // For now just call clear.
                provider.clearCircuit();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isWireHit(
    Connection conn,
    Offset tapPos,
    List<LogicComponent> components,
  ) {
    Offset? p1 = _getPinPos(conn.sourcePinId, components);
    Offset? p2 = _getPinPos(conn.targetPinId, components);

    if (p1 == null || p2 == null) return false;

    // Wire uses cubicTo. Checking hit on bezier is expensive.
    // Simplify: check distance to bounds or sample points?
    // Or check distance to the straight line? (Wont match curved wire well).
    // Or checking distance to the Bezier curve iteratively.

    // Let's use a simplified check: check points along the bezier curve
    // Bezier P0=p1, P1=(p1.x+d/2, p1.y), P2=(p2.x-d/2, p2.y), P3=p2
    double distX = (p2.dx - p1.dx).abs();
    Offset c1 = Offset(p1.dx + distX / 2, p1.dy);
    Offset c2 = Offset(p2.dx - distX / 2, p2.dy);

    // Check 20 steps
    for (double t = 0; t <= 1.0; t += 0.05) {
      Offset p = _evalCubicBezier(p1, c1, c2, p2, t);
      if ((p - tapPos).distance < 10.0) return true; // 10px tolerance
    }
    return false;
  }

  Offset _evalCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    double u = 1 - t;
    double tt = t * t;
    double uu = u * u;
    double uuu = uu * u;
    double ttt = tt * t;

    return p0 * uuu + p1 * (3 * uu * t) + p2 * (3 * u * tt) + p3 * ttt;
  }

  void _showWireContextMenu(BuildContext context, String connectionId) {
    // Get position for menu? showModalBottomSheet is easier
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete Connection"),
              onTap: () {
                Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).removeConnection(connectionId);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  Offset? _getPinPos(String pinId, List<LogicComponent> components) {
    for (var c in components) {
      for (int i = 0; i < c.inputs.length; i++) {
        if (c.inputs[i].id == pinId) {
          return ComponentLayout.getPinPosition(c, i, true);
        }
      }
      for (int i = 0; i < c.outputs.length; i++) {
        if (c.outputs[i].id == pinId) {
          return ComponentLayout.getPinPosition(c, i, false);
        }
      }
    }
    return null;
  }

  void _handleDrop(BuildContext context, dynamic data, Offset dropPos) {
    // dropPos is in global screen coordinates.
    // We need to convert it to the local coordinate system of the Container (Canvas).

    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset localPos = renderBox.globalToLocal(dropPos);

      // Snap to grid
      double gs = CircuitProvider.gridSize;
      double snapX = (localPos.dx / gs).round() * gs;
      double snapY = (localPos.dy / gs).round() * gs;

      try {
        if (data is ComponentType) {
          Provider.of<CircuitProvider>(
            context,
            listen: false,
          ).addComponentByType(data, Offset(snapX, snapY));
        }
      } catch (e, stack) {
        debugPrint('Error dropping component: $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing component: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

abstract class CircuitAction<T extends Intent> extends Action<T> {
  @override
  bool isEnabled(Object? intent) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return true;

    // Check the focus tree context
    final context = focus.context;
    if (context == null) return true;

    // 1. Check if the focused widget is an EditableText or contains one
    bool isFocusInText = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        isFocusInText = true;
        return false;
      }
      return true;
    });

    if (isFocusInText) return false;

    // 2. Check debug labels for common text field focus tags
    final debugLabel = focus.debugLabel;
    if (debugLabel != null) {
      final labelLower = debugLabel.toLowerCase();
      if (labelLower.contains('editabletext') ||
          labelLower.contains('textfield') ||
          labelLower.contains('textinput')) {
        return false;
      }
    }

    // 3. Check for RenderEditable in the focus target's subtree
    bool hasRenderEditable = false;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderEditable) {
      hasRenderEditable = true;
    } else if (renderObject is RenderBox) {
      // Check if it's a descendant of something that might handle text
    }

    return !hasRenderEditable;
  }
}

class DeleteComponentAction extends CircuitAction<DeleteIntent> {
  final CircuitProvider provider;
  DeleteComponentAction(this.provider);
  @override
  Object? invoke(DeleteIntent intent) {
    provider.deleteSelectedComponents();
    return null;
  }
}

class SelectAllAction extends CircuitAction<SelectAllIntent> {
  final CircuitProvider provider;
  SelectAllAction(this.provider);
  @override
  Object? invoke(SelectAllIntent intent) {
    provider.selectAll();
    return null;
  }
}

class SaveCircuitAction extends CircuitAction<SaveIntent> {
  final CircuitProvider provider;
  SaveCircuitAction(this.provider);
  @override
  Object? invoke(SaveIntent intent) {
    provider.saveCurrentCircuit();
    return null;
  }
}

class CancelSelectionAction extends CircuitAction<CancelSelectionIntent> {
  final CircuitProvider provider;
  CancelSelectionAction(this.provider);
  @override
  Object? invoke(CancelSelectionIntent intent) {
    provider.clearSelection();
    return null;
  }
}

class MoveComponentAction extends CircuitAction<MoveIntent> {
  final CircuitProvider provider;
  MoveComponentAction(this.provider);

  @override
  Object? invoke(MoveIntent intent) {
    provider.moveSelectedComponents(intent.delta);
    return null;
  }
}
