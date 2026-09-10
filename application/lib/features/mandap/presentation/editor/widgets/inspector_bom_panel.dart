import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mandap/core/theme/app_theme.dart';
import '../../../domain/entities/mandap_edge.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/entities/node_id.dart';
import '../../../application/commands/move_node_command.dart';
import '../../../application/commands/update_node_dimensions_command.dart';
import '../../../application/commands/set_node_support_command.dart';
import '../../../application/mandap_editor_controller.dart';
import '../../mandap_editor_screen.dart';

/// Unified right-side panel hosting Properties and BOM tabs.
/// Contextually adapts to:
/// - Default (Nothing selected) -> Project Details & View Controls
/// - Member selected -> Member coordinates, exact geometric length, inventory breakdown
/// - Pole selected -> Pole position, height editor, support type
/// - Center selected -> Center position, roof cross spans, reset center button
class InspectorBomPanel extends StatefulWidget {
  final MandapEditorController controller;
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onFitToScreen;
  final VoidCallback onResetView;
  final VoidCallback onToggleOrthographic;
  final bool isOrthographic;

  const InspectorBomPanel({
    super.key,
    required this.controller,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onFitToScreen,
    required this.onResetView,
    required this.onToggleOrthographic,
    this.isOrthographic = false,
  });

  @override
  State<InspectorBomPanel> createState() => _InspectorBomPanelState();
}

class _InspectorBomPanelState extends State<InspectorBomPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(left: BorderSide(color: AppColors.headerBorder, width: 1)),
      ),
      child: Column(
        children: [
          // Top Tab Switcher
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.trussPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Properties'),
                Tab(text: 'BOM'),
              ],
            ),
          ),
          Divider(color: AppColors.headerBorder, height: 1),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPropertiesTab(),
                _buildBomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab() {
    final c = widget.controller;

    // 1. Check if Member Selected
    if (c.selectedEdgeId != null) {
      final edge = c.layout.getEdge(c.selectedEdgeId!);
      if (edge != null) {
        return _buildMemberProperties(edge);
      }
    }

    // 2. Check if Node Selected
    if (c.selectedNodeId != null) {
      final node = c.layout.getNode(c.selectedNodeId!);
      if (node != null) {
        if (node.isControlPoint) {
          return _buildCenterControlProperties(node);
        } else if (node.hasPole) {
          return _buildPoleProperties(node);
        } else {
          return _buildGenericNodeProperties(node);
        }
      }
    }

    // 3. Default: Project Details & View Controls
    return _buildProjectDetailsDefault();
  }

  // ── Project Details Default ────────────────────────────────────────────────
  Widget _buildProjectDetailsDefault() {
    final c = widget.controller;

    // Derive approximate plot size from node bounding box
    double maxX = 0;
    double maxZ = 0;
    for (final node in c.layout.nodes.values) {
      if (node.x > maxX) maxX = node.x;
      if (node.z > maxZ) maxZ = node.z;
    }
    final lengthX = maxX > 0 ? maxX : 100.0;
    final widthZ = maxZ > 0 ? maxZ : 100.0;

    final hasCenterNode = c.layout.nodes.values.any((n) => n.isControlPoint);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROJECT DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          _buildDataRow('Length (X)', '${lengthX.toStringAsFixed(0)} ft'),
          const SizedBox(height: 10),
          _buildDataRow('Width (Z)', '${widthZ.toStringAsFixed(0)} ft'),
          const SizedBox(height: 10),
          _buildDataRow('Preferred Pole Spacing', '${c.standardTrussPieceSize.toStringAsFixed(0)} ft'),
          const SizedBox(height: 10),
          _buildDataRow(
            'Pole Height',
            '${(c.layout.nodes.values.firstWhere((n) => n.height != null, orElse: () => const MandapNode(id: NodeId('__temp__'), x: 0, z: 0, height: 20.0)).height ?? 20.0).toStringAsFixed(0)} ft',
          ),
          const SizedBox(height: 16),

          // Center Structure Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Center Structure (Cross)',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: hasCenterNode,
                  activeColor: const Color(0xFF3B82F6),
                  onChanged: (val) {
                    // Quick center toggle
                    if (!val && hasCenterNode) {
                      final centerNode = c.layout.nodes.values.firstWhere((n) => n.isControlPoint);
                      c.deleteNode(centerNode.id);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 16),

          // View Controls
          const Text(
            'VIEW CONTROLS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          // 2D / 3D Toggle
          Container(
            height: 38,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onViewModeChanged(ViewMode.topView2D),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.viewMode == ViewMode.topView2D ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('2D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onViewModeChanged(ViewMode.view3D),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.viewMode == ViewMode.view3D ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('3D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            icon: Icons.fullscreen_rounded,
            label: 'Fit to Screen',
            onTap: widget.onFitToScreen,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.restart_alt_rounded,
            label: 'Reset View',
            onTap: widget.onResetView,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.view_in_ar_rounded,
            label: widget.isOrthographic ? 'Perspective View' : 'Orthographic View',
            onTap: widget.onToggleOrthographic,
          ),
        ],
      ),
    );
  }

  // ── Member Selected ────────────────────────────────────────────────────────
  Widget _buildMemberProperties(MandapEdge edge) {
    final c = widget.controller;
    final start = c.layout.getNode(edge.startNodeId);
    final end = c.layout.getNode(edge.endNodeId);
    final geomDist = c.layout.getExactGeometricLengthFeet(edge);
    final sol = c.result.edgeSolutions[edge.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MEMBER PROPERTIES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF60A5FA)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => c.selectEdge(null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (start != null) ...[
            const Text('Start Position', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            _buildDataRow('X, Y, Z', '${start.x.toStringAsFixed(1)}, ${start.elevation.toStringAsFixed(1)}, ${start.z.toStringAsFixed(1)} ft'),
            const SizedBox(height: 10),
          ],

          if (end != null) ...[
            const Text('End Position', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            _buildDataRow('X, Y, Z', '${end.x.toStringAsFixed(1)}, ${end.elevation.toStringAsFixed(1)}, ${end.z.toStringAsFixed(1)} ft'),
            const SizedBox(height: 10),
          ],

          const Text('Geometric Length', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          _buildDataRow('Euclidean Distance', '${geomDist.toStringAsFixed(2)} ft'),
          const SizedBox(height: 10),

          _buildDataRow('Profile', edge.profile == EdgeProfile.singleTube ? 'Single Tube' : 'Box Truss'),
          const SizedBox(height: 14),

          if (sol != null && sol.pieces.isNotEmpty) ...[
            const Text('Inventory Decomposition', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sol.pieces.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${p.length.feet.toStringAsFixed(0)} ft piece',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFF87171)),
              label: const Text('Delete Member', style: TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => c.deleteEdge(edge.id),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pole Selected ──────────────────────────────────────────────────────────
  Widget _buildPoleProperties(MandapNode node) {
    final c = widget.controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'POLE PROPERTIES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF60A5FA)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => c.selectNode(null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildDataRow('Position X', '${node.x.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildDataRow('Position Z', '${node.z.toStringAsFixed(1)} ft'),
          const SizedBox(height: 12),

          const Text('Tower Height (Y)', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: (node.height ?? 20.0).clamp(8.0, 40.0),
                  min: 8.0,
                  max: 40.0,
                  divisions: 32,
                  activeColor: const Color(0xFF3B82F6),
                  onChanged: (val) {
                    c.executeCommand(
                      UpdateNodeDimensionsCommand(
                        nodeId: node.id,
                        oldWidth: node.width,
                        oldDepth: node.depth,
                        oldHeight: node.height,
                        oldRotation: node.rotation,
                        oldElevation: node.elevation,
                        newWidth: node.width,
                        newDepth: node.depth,
                        newHeight: val,
                        newRotation: node.rotation,
                        newElevation: node.elevation,
                      ),
                    );
                  },
                ),
              ),
              Text(
                '${(node.height ?? 20.0).toStringAsFixed(0)} ft',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildDataRow('Support Type', 'Physical Pole'),
          const SizedBox(height: 8),
          _buildDataRow('Structure', node.structureId),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.remove_circle_outline, size: 16, color: Color(0xFFF59E0B)),
              label: const Text('Remove Support Pole', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                c.removePoleSupport(node.id);
                c.selectNode(null);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Center Control Selected ────────────────────────────────────────────────
  Widget _buildCenterControlProperties(MandapNode node) {
    final c = widget.controller;

    // Calculate spans to surrounding perimeter midpoints
    double northSpan = 0;
    double eastSpan = 0;
    double southSpan = 0;
    double westSpan = 0;

    for (final edge in c.layout.edges.values) {
      if (edge.startNodeId == node.id || edge.endNodeId == node.id) {
        final otherId = edge.startNodeId == node.id ? edge.endNodeId : edge.startNodeId;
        final otherNode = c.layout.getNode(otherId);
        if (otherNode != null) {
          final dist = c.layout.getExactGeometricLengthFeet(edge);
          if (otherNode.z > node.z + 5) northSpan = dist;
          if (otherNode.x > node.x + 5) eastSpan = dist;
          if (otherNode.z < node.z - 5) southSpan = dist;
          if (otherNode.x < node.x - 5) westSpan = dist;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CENTER STRUCTURE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFFBBF24)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => c.selectNode(null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildDataRow('Position X', '${node.x.toStringAsFixed(2)} ft'),
          const SizedBox(height: 8),
          _buildDataRow('Position Z', '${node.z.toStringAsFixed(2)} ft'),
          const SizedBox(height: 16),

          const Text('ROOF / CROSS GEOMETRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 10),

          _buildDataRow('North Span', '${northSpan > 0 ? northSpan.toStringAsFixed(2) : "--"} ft'),
          const SizedBox(height: 8),
          _buildDataRow('East Span', '${eastSpan > 0 ? eastSpan.toStringAsFixed(2) : "--"} ft'),
          const SizedBox(height: 8),
          _buildDataRow('South Span', '${southSpan > 0 ? southSpan.toStringAsFixed(2) : "--"} ft'),
          const SizedBox(height: 8),
          _buildDataRow('West Span', '${westSpan > 0 ? westSpan.toStringAsFixed(2) : "--"} ft'),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Reset Center (50, 50)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                c.executeCommand(
                  MoveNodeCommand(
                    nodeId: node.id,
                    oldX: node.x,
                    oldZ: node.z,
                    newX: 50.0,
                    newZ: 50.0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericNodeProperties(MandapNode node) {
    final c = widget.controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NODE PROPERTIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF60A5FA))),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => c.selectNode(null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataRow('X, Z', '${node.x.toStringAsFixed(1)}, ${node.z.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildDataRow('Role', node.role.name),
          const SizedBox(height: 8),
          _buildDataRow('Support', node.support.name),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Support Pole Under Node', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                c.setNodeSupport(node.id, NodeSupport.pole);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── BOM Tab ────────────────────────────────────────────────────────────────
  Widget _buildBomTab() {
    final c = widget.controller;
    final totalTruss = c.totalLinearTrussFt;
    final poleCount = c.totalPoleCount;
    final result = c.result;

    // Piece breakdown
    final requiredTruss = result.requiredTrussBySize;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BILL OF MATERIALS (BOM)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          // Total Linear Truss
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Geometric Truss Length', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Text(
                  '${totalTruss.toStringAsFixed(1)} ft',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Box Truss Pieces Breakdown
          const Text(
            'BOX TRUSS PIECES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 8),

          if (requiredTruss.isEmpty)
            const Text('No pieces required for empty design', style: TextStyle(fontSize: 12, color: Colors.white54))
          else
            ...requiredTruss.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.length.feet.toStringAsFixed(0)} ft segment',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.value} pcs',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),

          // Vertical Towers
          const Text(
            'PHYSICAL POLES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFFFBBF24)),
          ),
          const SizedBox(height: 8),

          _buildDataRow('Total Support Towers', '$poleCount poles'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),

          // Summary Totals
          const Text(
            'TOTALS SUMMARY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 8),
          _buildDataRow('Total Truss Footage', '${totalTruss.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildDataRow('Total Physical Poles', '$poleCount towers'),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _buildDataRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF60A5FA)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
