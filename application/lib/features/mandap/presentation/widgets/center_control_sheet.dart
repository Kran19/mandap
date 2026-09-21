import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/mandap_node.dart';
import '../../application/mandap_editor_controller.dart';

/// Interactive modal sheet displayed when the user selects the center control point or line.
/// Supports modifying the internal truss position in all directions:
/// Left / Right (X-axis) and Front / Back (Z-axis).
class CenterControlSheet extends StatefulWidget {
  final MandapEditorController controller;
  final MandapNode centerNode;
  final double mainTrussElevation;
  final VoidCallback onClose;

  const CenterControlSheet({
    super.key,
    required this.controller,
    required this.centerNode,
    required this.mainTrussElevation,
    required this.onClose,
  });

  @override
  State<CenterControlSheet> createState() => _CenterControlSheetState();
}

class _CenterControlSheetState extends State<CenterControlSheet> {
  late double _posX;
  late double _posZ;
  late double _elevation;

  @override
  void initState() {
    super.initState();
    _posX = widget.centerNode.x;
    _posZ = widget.centerNode.z;
    _elevation = widget.centerNode.elevation > 0
        ? widget.centerNode.elevation
        : widget.mainTrussElevation;
  }

  @override
  void didUpdateWidget(covariant CenterControlSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.centerNode.x != widget.centerNode.x) {
      _posX = widget.centerNode.x;
    }
    if (oldWidget.centerNode.z != widget.centerNode.z) {
      _posZ = widget.centerNode.z;
    }
  }

  void _stepX(double direction) {
    final current = _posX;
    double target;
    if (direction > 0) {
      target = ((current / 5.0).floor() + 1) * 5.0;
    } else {
      target = ((current / 5.0).ceil() - 1) * 5.0;
    }
    _applyPos(targetX: target, targetZ: _posZ);
  }

  void _stepZ(double direction) {
    final current = _posZ;
    double target;
    if (direction > 0) {
      target = ((current / 5.0).floor() + 1) * 5.0;
    } else {
      target = ((current / 5.0).ceil() - 1) * 5.0;
    }
    _applyPos(targetX: _posX, targetZ: target);
  }

  void _applyPos({double? targetX, double? targetZ}) {
    final effectiveX = targetX ?? _posX;
    final effectiveZ = targetZ ?? _posZ;

    final minX = 5.0;
    final maxX = widget.controller.plotWidth > 10.0
        ? widget.controller.plotWidth - 5.0
        : 95.0;
    final minZ = 5.0;
    final maxZ = widget.controller.plotDepth > 10.0
        ? widget.controller.plotDepth - 5.0
        : 95.0;

    final clampedX = effectiveX.clamp(minX, maxX);
    final clampedZ = effectiveZ.clamp(minZ, maxZ);

    setState(() {
      _posX = clampedX;
      _posZ = clampedZ;
    });

    widget.controller.adjustCenterPosition(newX: clampedX, newZ: clampedZ);
  }

  void _resetToCenter() {
    final centerX = widget.controller.plotWidth / 2.0;
    final centerZ = widget.controller.plotDepth / 2.0;
    _applyPos(targetX: centerX, targetZ: centerZ);
  }

  @override
  Widget build(BuildContext context) {
    final plotWidth = widget.controller.plotWidth;
    final plotDepth = widget.controller.plotDepth;
    final defaultCenterX = plotWidth / 2.0;
    final defaultCenterZ = plotDepth / 2.0;

    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.trussLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.open_with_rounded,
                  color: AppColors.trussPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CENTER TRUSS POSITION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'All Directions Movement (Left/Right & Front/Back)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Left / Right (X-axis) Position Section
          const Text(
            'Left / Right (X-Axis)',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildStepButton(
                icon: Icons.arrow_back_rounded,
                tooltip: '-5 ft (Left)',
                onTap: () => _stepX(-1),
              ),
              Expanded(
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    'X: ${_posX.toStringAsFixed(1)} ft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildStepButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: '+5 ft (Right)',
                onTap: () => _stepX(1),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Front / Back (Z-axis) Position Section
          const Text(
            'Front / Back (Z-Axis)',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildStepButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: '-5 ft (Front)',
                onTap: () => _stepZ(-1),
              ),
              Expanded(
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    'Z: ${_posZ.toStringAsFixed(1)} ft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildStepButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: '+5 ft (Back)',
                onTap: () => _stepZ(1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Preset Values
          Row(
            children: [
              Expanded(
                child: _buildPresetChip(
                  'Center (${defaultCenterX.toStringAsFixed(0)}, ${defaultCenterZ.toStringAsFixed(0)})',
                  () => _applyPos(targetX: defaultCenterX, targetZ: defaultCenterZ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Reset and Apply
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToCenter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('RESET TO CENTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00F0FF),
            ),
          ),
        ),
      ),
    );
  }
}

