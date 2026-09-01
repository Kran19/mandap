import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/geometry/length.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/edge_id.dart';
import '../../domain/entities/node_id.dart';

/// Context bottom sheet shown when a node or edge is selected.
///
/// For edges: shows length, truss decomposition, and an inline dimension
/// entry field.
/// For nodes: shows coordinates and a delete button.
class SelectionSheet extends StatefulWidget {
  final MandapEditorController controller;

  const SelectionSheet({super.key, required this.controller});

  @override
  State<SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<SelectionSheet> {
  final TextEditingController _lengthController = TextEditingController();

  @override
  void dispose() {
    _lengthController.dispose();
    super.dispose();
  }

  MandapEditorController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final selectedEdge = c.selectedEdgeId != null
        ? c.layout.getEdge(c.selectedEdgeId!)
        : null;
    final selectedNode = c.selectedNodeId != null
        ? c.layout.getNode(c.selectedNodeId!)
        : null;

    if (selectedEdge == null && selectedNode == null) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (selectedEdge != null) _buildEdgeSheet(selectedEdge.id),
          if (selectedNode != null) _buildNodeSheet(selectedNode.id),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEdgeSheet(EdgeId edgeId) {
    final edge = c.layout.getEdge(edgeId);
    if (edge == null) return const SizedBox();

    final startNode = c.layout.getNode(edge.startNodeId);
    final endNode = c.layout.getNode(edge.endNodeId);

    String lengthStr = '?';
    String piecesStr = '';
    if (startNode != null && endNode != null) {
      final len = c.layout.getEdgeLength(edge);
      lengthStr = len.toString();
      final sol = c.result.edgeSolutions[edgeId];
      if (sol != null && sol.exactFit) {
        piecesStr = sol.pieces
            .map((p) => '${p.length.ticks ~/ 2}ft')
            .join(' + ');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF2563EB), size: 16),
              const SizedBox(width: 8),
              Text(
                'Edge: ${edgeId.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              // Delete edge
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Delete edge',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  c.deleteEdge(edgeId);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Length: $lengthStr',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          if (piecesStr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Trusses: $piecesStr',
              style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          // Direct dimension entry
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter length in feet (multiples of 0.5)',
                    hintStyle: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _applyDirectLength(edgeId),
                child: const Text('Apply', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyDirectLength(EdgeId edgeId) {
    final text = _lengthController.text.trim();
    final feet = double.tryParse(text);
    if (feet == null || feet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid positive number of feet')),
      );
      return;
    }
    try {
      Length.fromFeet(feet);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Length must be a valid 0.5 ft increment (e.g. 37.5)'),
        ),
      );
      return;
    }

    final edge = c.layout.getEdge(edgeId);
    if (edge == null) return;

    final startNode = c.layout.getNode(edge.startNodeId);
    final endNode = c.layout.getNode(edge.endNodeId);
    if (startNode == null || endNode == null) return;

    // Move the end-node along the edge axis to achieve the requested length
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final currentLen = math
        .sqrt(dx * dx + dz * dz)
        .clamp(0.001, double.infinity);
    final ratio = feet / currentLen;
    final newEndX = startNode.x + dx * ratio;
    final newEndZ = startNode.z + dz * ratio;

    // Snap to 0.5 ft
    final snapped = ViewportSnapHelper.snapToHalf(newEndX, newEndZ);
    c.resizeEdge(
      edgeId: edgeId,
      movingNodeId: edge.endNodeId,
      newX: snapped.$1,
      newZ: snapped.$2,
    );
    _lengthController.clear();
  }

  Widget _buildNodeSheet(NodeId nodeId) {
    final node = c.layout.getNode(nodeId);
    if (node == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF0F172A), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Node: ${nodeId.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'X: ${node.x.toStringAsFixed(1)} ft   Z: ${node.z.toStringAsFixed(1)} ft',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            tooltip: 'Delete node + connected edges',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () => c.deleteNode(nodeId),
          ),
        ],
      ),
    );
  }
}

/// Quick snap helper used within the sheet without a full transform object.
class ViewportSnapHelper {
  static (double, double) snapToHalf(double x, double z) {
    return ((x / 0.5).round() * 0.5, (z / 0.5).round() * 0.5);
  }
}
