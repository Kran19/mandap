import 'package:flutter/material.dart';
import '../../application/truss_boundary_controller.dart';

class TrussSideSummary extends StatelessWidget {
  final TrussBoundaryController controller;
  final String? selectedSideId;
  final ValueChanged<String> onSideSelected;

  const TrussSideSummary({
    super.key,
    required this.controller,
    required this.selectedSideId,
    required this.onSideSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Meta Bar (Plot Size, Truss Size, Poles Required)
          Row(
            children: [
              _buildTopMeta('Plot Size', '${controller.plotWidth.round()} × ${controller.plotDepth.round()} ft'),
              _buildMetaDivider(),
              _buildTopMeta('Truss Size', controller.initialTrussSize.label),
              _buildMetaDivider(),
              _buildTopMetaWithBadge('Poles Required', '${controller.requiredPolesCount}'),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 12),

          // 2. Metrics Strip: Poles Required | Actual Poles | Structural Nodes | Geometric Runs | Material Pieces | Total Boundary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Poles Req.', '${controller.requiredPolesCount}', isHighlighted: true),
              _buildVerticalDivider(),
              _buildStatColumn('Actual Poles', '${controller.actualPolesCount}'),
              _buildVerticalDivider(),
              _buildStatColumn('Nodes', '${controller.structuralNodesCount}'),
              _buildVerticalDivider(),
              _buildStatColumn('Runs', '${controller.totalGeometricRunsCount}'),
              _buildVerticalDivider(),
              _buildStatColumn('Material', '${_calculateTotalMaterialPieces()} pcs'),
              _buildVerticalDivider(),
              _buildStatColumn('Boundary', '${controller.totalBoundaryLength.round()} ft'),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Bottom Side Selector Pills (North, East, South, West)
          Row(
            children: [
              Expanded(child: _buildSidePill('north', 'North Side')),
              const SizedBox(width: 8),
              Expanded(child: _buildSidePill('east', 'East Side')),
              const SizedBox(width: 8),
              Expanded(child: _buildSidePill('south', 'South Side')),
              const SizedBox(width: 8),
              Expanded(child: _buildSidePill('west', 'West Side')),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateTotalMaterialPieces() {
    int total = 0;
    for (final reqs in controller.materialRequirements.values) {
      total += reqs.length;
    }
    return total;
  }

  Widget _buildTopMeta(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopMetaWithBadge(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFFACC15), fontSize: 14, fontWeight: FontWeight.bold, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaDivider() {
    return Container(width: 1, height: 28, color: const Color(0xFF1E293B), margin: const EdgeInsets.symmetric(horizontal: 10));
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFF1E293B));
  }

  Widget _buildStatColumn(String label, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFFFACC15) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSidePill(String sideId, String label) {
    final isSelected = selectedSideId == sideId;
    final side = controller.fourSides[sideId];
    final runsText = side != null ? side.runs.map((r) => '${r.geometricSpan.round()}').join(' + ') : '';

    return GestureDetector(
      onTap: () => onSideSelected(sideId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A5F) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, color: isSelected ? const Color(0xFF38BDF8) : Colors.white38, size: 12),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              runsText,
              style: TextStyle(
                color: isSelected ? const Color(0xFF38BDF8) : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
