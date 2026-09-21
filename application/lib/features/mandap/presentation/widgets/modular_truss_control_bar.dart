import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/mandap_editor_controller.dart';
import '../../application/commands/add_external_structure_command.dart';
import '../../../truss_boundary/domain/entities/truss_size.dart';

/// Single compact Plot Size button overlay on the canvas.
/// When tapped, opens an interactive configuration dialog displaying
/// Plot Size (Length / Width), Truss Size selector with the Authoritative
/// Support Pole Logic Table, and an Auto Generate Truss Structure button.
class ModularTrussControlBar extends StatelessWidget {
  final MandapEditorController controller;
  final VoidCallback onStructureGenerated;

  const ModularTrussControlBar({
    super.key,
    required this.controller,
    required this.onStructureGenerated,
  });

  static void showPlotSizeDialog(
    BuildContext context, {
    required MandapEditorController controller,
    required VoidCallback onStructureGenerated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PlotSizeConfigDialog(
        controller: controller,
        onStructureGenerated: onStructureGenerated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final len = controller.plotDepth > 0 ? controller.plotDepth.toInt() : 100;
        final width = controller.plotWidth > 0 ? controller.plotWidth.toInt() : 100;
        final truss = controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize.toInt() : 30;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showPlotSizeDialog(
              context,
              controller: controller,
              onStructureGenerated: onStructureGenerated,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0F263B), // Dark navy capsule
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.crop_free_rounded,
                    size: 16,
                    color: Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plot Size: $width × $len ft • $truss ft Truss',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlotSizeConfigDialog extends StatefulWidget {
  final MandapEditorController controller;
  final VoidCallback onStructureGenerated;

  const _PlotSizeConfigDialog({
    required this.controller,
    required this.onStructureGenerated,
  });

  @override
  State<_PlotSizeConfigDialog> createState() => _PlotSizeConfigDialogState();
}

class _PlotSizeConfigDialogState extends State<_PlotSizeConfigDialog> {
  // Tab index: 0 = Truss Spans, 1 = Gate & Entrances
  int _selectedTab = 0;

  // Map of truss piece length in ft -> count
  late Map<double, int> _pieceCounts;
  late TextEditingController _customSizeController;
  final FocusNode _customFocusNode = FocusNode();
  bool _showCustomInput = false;
  String? _errorMessage;

  // Gate / Entrance Configuration state
  EntranceSide _selectedSide = EntranceSide.southC; // Front / South by default
  double _gateWidth = 20.0;
  double _gateProjection = 10.0;
  double _gateHeight = 20.0;
  String _gateAlignment = 'center'; // 'center', 'left', 'right', 'custom'
  late TextEditingController _customGateWidthController;
  late TextEditingController _customGateProjController;
  late TextEditingController _customGateOffsetController;
  bool _showCustomGateWidth = false;
  bool _showCustomGateProj = false;
  String? _gateSuccessMessage;

  @override
  void initState() {
    super.initState();
    _customSizeController = TextEditingController();
    _customGateWidthController = TextEditingController(text: '20');
    _customGateProjController = TextEditingController(text: '10');
    _customGateOffsetController = TextEditingController(text: '0');

    // Default initial piece combination based on 100ft (e.g. 2 x 30ft + 1 x 40ft = 100ft, or 60+30+10)
    final initialStandard = widget.controller.standardTrussPieceSize > 0 ? widget.controller.standardTrussPieceSize : 30.0;
    if (initialStandard == 30.0) {
      _pieceCounts = {30.0: 2, 40.0: 1};
    } else {
      _pieceCounts = {initialStandard: 2};
    }
  }

  @override
  void dispose() {
    _customSizeController.dispose();
    _customFocusNode.dispose();
    _customGateWidthController.dispose();
    _customGateProjController.dispose();
    _customGateOffsetController.dispose();
    super.dispose();
  }

  double get _targetLength => widget.controller.plotWidth > 0 ? widget.controller.plotWidth : 100.0;

  double get _currentSum {
    double sum = 0.0;
    _pieceCounts.forEach((len, count) {
      sum += len * count;
    });
    return sum;
  }

  List<double> _buildFlatSequence() {
    final seq = <double>[];
    final sortedKeys = _pieceCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final len in sortedKeys) {
      final count = _pieceCounts[len] ?? 0;
      for (int i = 0; i < count; i++) {
        seq.add(len);
      }
    }
    return seq;
  }

  void _addPiece(double len) {
    setState(() {
      _pieceCounts[len] = (_pieceCounts[len] ?? 0) + 1;
      _errorMessage = null;
    });
  }

  void _removePiece(double len) {
    setState(() {
      final count = _pieceCounts[len] ?? 0;
      if (count > 1) {
        _pieceCounts[len] = count - 1;
      } else {
        _pieceCounts.remove(len);
      }
      _errorMessage = null;
    });
  }

  void _setPreset(Map<double, int> preset) {
    setState(() {
      _pieceCounts = Map.from(preset);
      _errorMessage = null;
    });
  }

  void _onAddCustomPiece() {
    final val = double.tryParse(_customSizeController.text.trim());
    if (val == null || val <= 0) {
      setState(() => _errorMessage = 'Please enter a valid piece size (e.g. 15, 35 ft).');
      return;
    }
    _addPiece(val);
    _customSizeController.clear();
    setState(() {
      _showCustomInput = false;
      _errorMessage = null;
    });
  }

  void _onGenerate() {
    final sum = _currentSum;
    final seq = _buildFlatSequence();

    if (seq.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one truss piece.');
      return;
    }

    widget.controller.reconfigureWithTrussPieces(
      pieceSpans: seq,
      plotWidth: sum > 0 ? sum : _targetLength,
      plotLength: sum > 0 ? sum : _targetLength,
    );

    widget.onStructureGenerated();
    Navigator.of(context).pop();
  }

  String _getSideDisplayName(EntranceSide side) {
    switch (side) {
      case EntranceSide.northA:
        return 'Top (North / Back)';
      case EntranceSide.eastB:
        return 'Right (East)';
      case EntranceSide.southC:
        return 'Bottom (South / Front)';
      case EntranceSide.westD:
        return 'Left (West)';
    }
  }

  void _onAddGate() {
    final wallLength = (_selectedSide == EntranceSide.northA || _selectedSide == EntranceSide.southC)
        ? (widget.controller.plotWidth > 0 ? widget.controller.plotWidth : 100.0)
        : (widget.controller.plotDepth > 0 ? widget.controller.plotDepth : 100.0);

    double effectiveOffset;
    if (_gateAlignment == 'center') {
      effectiveOffset = math.max(0.0, (wallLength - _gateWidth) / 2.0);
    } else if (_gateAlignment == 'left') {
      effectiveOffset = 0.0;
    } else if (_gateAlignment == 'right') {
      effectiveOffset = math.max(0.0, wallLength - _gateWidth);
    } else {
      effectiveOffset = double.tryParse(_customGateOffsetController.text.trim()) ?? 0.0;
    }

    final gateCount = widget.controller.layout.nodes.values
        .map((n) => n.structureId)
        .where((id) => id != 'main')
        .toSet()
        .length;

    final gateId = 'gate_${_selectedSide.name}_${gateCount + 1}';

    widget.controller.addExternalStructure(
      structureId: gateId,
      side: _selectedSide,
      width: _gateWidth,
      projection: _gateProjection,
      offset: effectiveOffset,
      height: _gateHeight,
    );

    widget.onStructureGenerated();

    setState(() {
      _gateSuccessMessage = '✓ Added ${_gateWidth.toInt()}×${_gateProjection.toInt()} ft Gate to ${_getSideDisplayName(_selectedSide)}!';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sum = _currentSum;
    final target = _targetLength;
    final isExact = (sum - target).abs() < 0.1;
    final progress = target > 0 ? (sum / target).clamp(0.0, 1.0) : 1.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Premium Header with Close Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2B48),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: Color(0xFF00E5FF)),
                        SizedBox(width: 8),
                        Text(
                          'Truss & Gate Configuration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              // 2. Segmented Navigation Tabs
              Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1323),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        index: 0,
                        label: 'Truss Spans',
                        icon: Icons.straighten_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildTabButton(
                        index: 1,
                        label: 'Add Gate / Entrance',
                        icon: Icons.door_front_door_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: _selectedTab == 0
                    ? _buildTrussSpanTab(sum, target, isExact, progress)
                    : _buildGateConfigTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: const Color(0xFF00E5FF), width: 1.2) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrussSpanTab(double sum, double target, bool isExact, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Target Length & Live Sum Status Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExact ? const Color(0xFF00E5FF) : const Color(0xFF334155),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Target Plot Span',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isExact ? const Color(0x3300E5FF) : const Color(0x22F59E0B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isExact ? const Color(0xFF00E5FF) : const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Text(
                      isExact ? '✓ Complete' : '${(target - sum).abs().toInt()} ft ${sum < target ? 'Needed' : 'Over'}',
                      style: TextStyle(
                        color: isExact ? const Color(0xFF00E5FF) : const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${sum.toInt()}',
                    style: TextStyle(
                      color: isExact ? const Color(0xFF00E5FF) : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / ${target.toInt()} ft',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExact ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Selected Truss Pieces List
        const Text(
          'ACTIVE TRUSS PIECES',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        if (_pieceCounts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text(
              'No truss pieces added yet. Tap a button below to add.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pieceCounts.entries.map((entry) {
              final len = entry.key;
              final count = entry.value;
              final lenStr = len % 1 == 0 ? len.toInt().toString() : len.toStringAsFixed(1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$lenStr ft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B48),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '×$count',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removePiece(len),
                      child: const Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _addPiece(len),
                      child: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 14),

        // Quick Add Pieces Chips
        const Text(
          'ADD TRUSS PIECE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildAddPieceButton(10.0),
            _buildAddPieceButton(20.0),
            _buildAddPieceButton(25.0),
            _buildAddPieceButton(30.0),
            _buildAddPieceButton(40.0),
            _buildAddPieceButton(50.0),
            _buildCustomToggleButton(),
          ],
        ),

        if (_showCustomInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _customSizeController,
                    focusNode: _customFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Enter ft (e.g. 15, 35)',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _onAddCustomPiece(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onAddCustomPiece,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Quick Presets
        const Text(
          'QUICK PRESETS (100 FT TOTAL)',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPresetChip('2 × 30ft + 1 × 40ft', {30.0: 2, 40.0: 1}),
            _buildPresetChip('2 × 50ft', {50.0: 2}),
            _buildPresetChip('5 × 20ft', {20.0: 5}),
            _buildPresetChip('2 × 40ft + 1 × 20ft', {40.0: 2, 20.0: 1}),
          ],
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
            ),
          ),
        ],

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _onGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D6AE5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
          child: const Text(
            'Auto Generate Truss Structure',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGateConfigTab() {
    final externalStructures = widget.controller.layout.nodes.values
        .map((n) => n.structureId)
        .where((id) => id != 'main')
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Interactive Side Selector (Top / North, Bottom / South, Left / West, Right / East)
        const Text(
          'SELECT ATTACHMENT SIDE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            _buildSideSelectorCard(EntranceSide.northA, 'Top (North / Back)', Icons.arrow_upward_rounded),
            _buildSideSelectorCard(EntranceSide.southC, 'Bottom (South / Front)', Icons.arrow_downward_rounded),
            _buildSideSelectorCard(EntranceSide.westD, 'Left (West)', Icons.arrow_back_rounded),
            _buildSideSelectorCard(EntranceSide.eastB, 'Right (East)', Icons.arrow_forward_rounded),
          ],
        ),

        const SizedBox(height: 14),

        // 2. Gate Width Selector
        const Text(
          'GATE WIDTH (ALONG WALL)',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDimensionChip(15.0, _gateWidth, (v) => setState(() => _gateWidth = v)),
            _buildDimensionChip(20.0, _gateWidth, (v) => setState(() => _gateWidth = v)),
            _buildDimensionChip(30.0, _gateWidth, (v) => setState(() => _gateWidth = v)),
            _buildDimensionChip(40.0, _gateWidth, (v) => setState(() => _gateWidth = v)),
            _buildCustomGateToggle('Width', _showCustomGateWidth, () {
              setState(() => _showCustomGateWidth = !_showCustomGateWidth);
            }),
          ],
        ),

        if (_showCustomGateWidth) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _customGateWidthController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Custom Width in ft',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val);
                      if (v != null && v > 0) {
                        setState(() => _gateWidth = v);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // 3. Gate Projection / Depth Selector (Extends outward)
        const Text(
          'GATE PROJECTION (OUTWARD DEPTH)',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDimensionChip(10.0, _gateProjection, (v) => setState(() => _gateProjection = v)),
            _buildDimensionChip(15.0, _gateProjection, (v) => setState(() => _gateProjection = v)),
            _buildDimensionChip(20.0, _gateProjection, (v) => setState(() => _gateProjection = v)),
            _buildDimensionChip(25.0, _gateProjection, (v) => setState(() => _gateProjection = v)),
            _buildCustomGateToggle('Depth', _showCustomGateProj, () {
              setState(() => _showCustomGateProj = !_showCustomGateProj);
            }),
          ],
        ),

        if (_showCustomGateProj) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _customGateProjController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Custom Depth in ft',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val);
                      if (v != null && v > 0) {
                        setState(() => _gateProjection = v);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // 4. Position on Wall Alignment
        const Text(
          'ALIGNMENT ON WALL',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: _buildAlignmentChip('center', 'Centered', Icons.align_horizontal_center_rounded),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildAlignmentChip('left', 'Start / Left', Icons.align_horizontal_left_rounded),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildAlignmentChip('right', 'End / Right', Icons.align_horizontal_right_rounded),
            ),
          ],
        ),

        // Live preview summary card
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF00E5FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attach ${_gateWidth.toInt()}×${_gateProjection.toInt()} ft Gate to ${_getSideDisplayName(_selectedSide)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        if (_gateSuccessMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
            ),
            child: Text(
              _gateSuccessMessage!,
              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Action button to Add Gate
        ElevatedButton.icon(
          onPressed: _onAddGate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Attach Gate to Selected Side',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),

        // 5. Existing attached gates list
        if (externalStructures.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          const Text(
            'ATTACHED GATES & STRUCTURES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          ...externalStructures.map((structId) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.door_front_door_rounded, size: 15, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 8),
                      Text(
                        structId.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.controller.removeExternalStructure(structId);
                      widget.onStructureGenerated();
                      setState(() {
                        _gateSuccessMessage = '✓ Removed $structId';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSideSelectorCard(EntranceSide side, String label, IconData icon) {
    final isSelected = _selectedSide == side;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedSide = side),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionChip(double val, double currentVal, ValueChanged<double> onSelect) {
    final isSelected = (val - currentVal).abs() < 0.1;
    final valStr = val.toInt().toString();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            '$valStr ft',
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomGateToggle(String label, bool isToggled, VoidCallback onToggle) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isToggled ? const Color(0xFF0F2B48) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToggled ? const Color(0xFF00E5FF) : const Color(0xFF334155),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 12, color: isToggled ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                'Custom $label',
                style: TextStyle(
                  color: isToggled ? const Color(0xFF00E5FF) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignmentChip(String value, String label, IconData icon) {
    final isSelected = _gateAlignment == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _gateAlignment = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPieceButton(double len) {
    final lenStr = len.toInt().toString();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addPiece(len),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 13, color: Color(0xFF00E5FF)),
              const SizedBox(width: 4),
              Text(
                '$lenStr ft',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomToggleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showCustomInput = !_showCustomInput;
          });
          if (_showCustomInput) {
            _customFocusNode.requestFocus();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _showCustomInput ? const Color(0xFF0F2B48) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _showCustomInput ? const Color(0xFF00E5FF) : const Color(0xFF334155),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 12, color: Color(0xFF00E5FF)),
              SizedBox(width: 4),
              Text(
                'Custom',
                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, Map<double, int> preset) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPreset(preset),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1728),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E3A5F)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
