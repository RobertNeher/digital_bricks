import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../widgets/selection_bar.dart';
import '../widgets/circuit_board.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch provider to show stats or just for access?
    // Actions need access.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Bricks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final provider = Provider.of<CircuitProvider>(
                context,
                listen: false,
              );
              if (provider.currentFilePath != null) {
                // Show confirmation
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirm Overwrite"),
                    content: Text(
                      "Overwrite current file?\n${provider.currentFilePath}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Cancel
                          // Maybe open Save As?
                          provider.saveCircuitAs();
                        },
                        child: const Text("Save As..."),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.saveCurrentCircuit();
                        },
                        child: const Text("Overwrite"),
                      ),
                    ],
                  ),
                );
              } else {
                provider.saveCircuitAs();
              }
            },
            tooltip: "Save Circuit",
          ),
          IconButton(
            icon: const Icon(Icons.save_as),
            onPressed: () async {
              final provider = Provider.of<CircuitProvider>(context, listen: false);
              final oldPath = provider.currentFilePath;
              await provider.saveCircuitAs();
              if (context.mounted) {
                if (provider.currentFilePath != null && provider.currentFilePath != oldPath) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved as: ${provider.currentFilePath!.split(provider.pathSeparator).last}")),
                  );
                } else if (provider.currentFilePath != null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved circuit.")),
                  );
                }
              }
            },
            tooltip: "Save As",
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              final provider = Provider.of<CircuitProvider>(
                context,
                listen: false,
              );

              final result = await provider.pickAndReadCircuit();
              if (result == null || !context.mounted) return;

              final data = result.data;
              final name = result.name;

              // If canvas is empty, just load directly
              if (provider.components.isEmpty) {
                provider.clearCircuit();
                provider.packCircuit(data, name);
                return;
              }

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Load Circuit"),
                  content: const Text(
                    "Do you want to clear the current canvas before loading, or append the circuit to the existing one?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.clearCircuit();
                        provider.packCircuit(data, name);
                      },
                      child: const Text("Clear Canvas"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.packCircuit(data, name);
                      },
                      child: const Text("Append"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              );
            },
            tooltip: "Load Circuit",
          ),
          // Maybe a "Clear" button?
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Clear Canvas"),
                  content: const Text(
                    "Are you sure you want to clear the entire canvas?\nUnsaved changes will be lost.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        ).clearCircuit();
                      },
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: const [
          SelectionBar(),
          Expanded(child: CircuitBoard()),
        ],
      ),
    );
  }
}
