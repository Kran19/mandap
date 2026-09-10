import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/mandap_edge.dart';

class InspectorPanel extends StatelessWidget {
  final MandapEditorController controller;
  final ScrollController? scrollController;

  const InspectorPanel({
    super.key,
    required this.controller,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final nodeId = controller.selectedNodeId;
        final edgeId = controller.selectedEdgeId;

        Widget content;
        if (nodeId != null) {
          final node = controller.layout.getNode(nodeId);
          if (node != null) {
            content = _buildNodeInspector(context, l10n, node);
          } else {
            content = _buildEmptyState(l10n);
          }
        } else if (edgeId != null) {
          final edge = controller.layout.getEdge(edgeId);
          if (edge != null) {
            content = _buildEdgeInspector(context, l10n, edge);
          } else {
            content = _buildEmptyState(l10n);
          }
        } else {
          content = _buildEmptyState(l10n);
        }

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              if (scrollController != null) // Mobile drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [content],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'Select a ${l10n.node} or ${l10n.member} to inspect.',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNodeInspector(BuildContext context, AppLocalizations l10n, MandapNode node) {
    final isCenterControl = node.elevation > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCenterControl ? l10n.centerControl : l10n.node,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const Divider(),
        _buildPropertyRow(l10n.position, 'X: ${node.x.toStringAsFixed(2)} | Z: ${node.z.toStringAsFixed(2)}'),
        _buildPropertyRow(l10n.elevation, '${node.elevation.toStringAsFixed(2)} ft'),
        
        const SizedBox(height: 24),
        if (isCenterControl)
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reset),
            onPressed: () {
              controller.moveNode(nodeId: node.id, newX: 0, newZ: 0);
            },
          ),
        if (!isCenterControl)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete),
            label: Text(l10n.delete),
            onPressed: () => controller.deleteNode(node.id),
          ),
      ],
    );
  }

  Widget _buildEdgeInspector(BuildContext context, AppLocalizations l10n, MandapEdge edge) {
    final length = controller.layout.getEdgeLength(edge);
    final isTube = edge.profile == EdgeProfile.singleTube;
    
    // We create friendly presentation identifiers instead of raw UUIDs
    final startNodeStr = 'N-${edge.startNodeId.value.substring(0, 4)}';
    final endNodeStr = 'N-${edge.endNodeId.value.substring(0, 4)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.member} T-${edge.id.value.substring(0, 4)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const Divider(),
        _buildPropertyRow(l10n.profile, isTube ? l10n.singleTube : l10n.boxTruss),
        _buildPropertyRow(l10n.geometricLength, '${length.toString()} ft'),
        _buildPropertyRow(l10n.start, startNodeStr),
        _buildPropertyRow(l10n.end, endNodeStr),

        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.delete),
          label: Text(l10n.delete),
          onPressed: () => controller.deleteEdge(edge.id),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
