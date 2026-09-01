import 'package:flutter/material.dart';
import '../../../spikes/renderer_3d/mandap_3d_spike_screen.dart';
import '../application/mandap_editor_controller.dart';
import '../domain/entities/mandap_preset.dart';
import 'top_view_2d/mandap_2d_painter.dart';

enum ViewportMode { topView2D, view3D, splitView }

class DebugShellScreen extends StatefulWidget {
  const DebugShellScreen({super.key});

  @override
  State<DebugShellScreen> createState() => _DebugShellScreenState();
}

class _DebugShellScreenState extends State<DebugShellScreen> {
  late MandapEditorController controller;
  ViewportMode currentMode = ViewportMode.splitView;

  @override
  void initState() {
    super.initState();
    controller = MandapEditorController();
    controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final layout = controller.layout;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MANDAP — CORE LAYOUT EDITOR & CALCULATOR',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          // Preset Selector Dropdown
          DropdownButton<MandapPreset>(
            value: controller.currentPreset,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox(),
            items: MandapPreset.availablePresets().map((preset) {
              return DropdownMenuItem(
                value: preset,
                child: Text('Preset: ${preset.name}'),
              );
            }).toList(),
            onChanged: (preset) {
              if (preset != null) controller.loadPreset(preset);
            },
          ),
          const SizedBox(width: 8),
          // Viewport Mode Switcher
          SegmentedButton<ViewportMode>(
            segments: const [
              ButtonSegment(
                value: ViewportMode.topView2D,
                label: Text('2D', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: ViewportMode.view3D,
                label: Text('3D', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: ViewportMode.splitView,
                label: Text('Split', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (val) {
              setState(() {
                currentMode = val.first;
              });
            },
          ),
          const SizedBox(width: 8),
          // Undo & Redo Buttons
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: controller.history.canUndo
                ? () => controller.undo()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: controller.history.canRedo
                ? () => controller.redo()
                : null,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: Text(
              controller.isShortageTestMode ? 'Shortage Mode' : 'Stock Mode',
              style: const TextStyle(fontSize: 11),
            ),
            selected: controller.isShortageTestMode,
            onSelected: (val) => controller.toggleShortageMode(val),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          final panelWidget = Container(
            color: const Color(0xFFF8FAFC),
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 8),
                _buildPolesSummaryCard(),
                const SizedBox(height: 8),
                _buildBOMCard(),
                const SizedBox(height: 8),
                _buildEdgeBreakdownCard(),
                const SizedBox(height: 8),
                if (result.inventoryShortages.isNotEmpty) _buildShortagesCard(),
                if (result.warnings.isNotEmpty) _buildWarningsCard(),
              ],
            ),
          );

          final view2DWidget = Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.architecture,
                        color: Color(0xFF334155),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '2D TOP VIEW (GRAPH VISUALIZATION)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Legend: ● Corner  ● Generated Pole',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: Mandap2DPainter(
                      layout: layout,
                      result: result,
                      selectedEdgeId: controller.selectedEdgeId,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          );

          final view3DWidget = Stack(
            children: [
              const Mandap3DSpikeScreen(),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active Preset: ${controller.currentPreset.name} | Poles: ${result.totalPoleCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          );

          Widget viewportWidget;
          if (currentMode == ViewportMode.topView2D) {
            viewportWidget = view2DWidget;
          } else if (currentMode == ViewportMode.view3D) {
            viewportWidget = view3DWidget;
          } else {
            // Split View Mode
            viewportWidget = Row(
              children: [
                Expanded(child: view2DWidget),
                const VerticalDivider(width: 1),
                Expanded(child: view3DWidget),
              ],
            );
          }

          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 360, child: panelWidget),
                const VerticalDivider(width: 1),
                Expanded(child: viewportWidget),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 1, child: viewportWidget),
                const Divider(height: 1),
                Expanded(flex: 1, child: panelWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.currentPreset.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              controller.currentPreset.description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolesSummaryCard() {
    final result = controller.result;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUPPORT POLES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatItem(
                  'Total Poles',
                  '${result.totalPoleCount}',
                  Colors.blue[900]!,
                ),
                _buildStatItem(
                  'Corner Poles',
                  '${result.cornerPoleCount}',
                  const Color(0xFF1E293B),
                ),
                _buildStatItem(
                  'Generated (>30ft)',
                  '${result.generatedPoleCount}',
                  Colors.amber[800]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildBOMCard() {
    final result = controller.result;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AGGREGATED TRUSS BOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const Divider(),
            ...result.requiredTrussBySize.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${e.value} pcs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeBreakdownCard() {
    final result = controller.result;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EDGE DECOMPOSITION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const Divider(),
            ...result.edgeSolutions.entries.map((entry) {
              final edgeId = entry.key;
              final sol = entry.value;
              final pieceListStr = sol.pieces
                  .map((p) => '${p.length.ticks ~/ 2}ft')
                  .join(' + ');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Text(
                      '${edgeId.value}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${sol.targetLength}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sol.exactFit ? pieceListStr : 'NO FIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: sol.exactFit
                              ? const Color(0xFF0F172A)
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShortagesCard() {
    final result = controller.result;
    return Card(
      elevation: 0,
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STOCK SHORTAGES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF991B1B),
              ),
            ),
            const Divider(color: Color(0xFFFECACA)),
            ...result.inventoryShortages.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '• ${s.pieceType.name}: Needed ${s.requiredCount}, Available ${s.availableCount} (Shortage: ${s.shortageCount})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard() {
    final result = controller.result;
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENGINE WARNINGS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF92400E),
              ),
            ),
            const Divider(color: Color(0xFFFDE68A)),
            ...result.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '• $w',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
