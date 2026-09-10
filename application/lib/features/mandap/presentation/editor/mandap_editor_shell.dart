import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../projects/application/project_sync_service.dart';
import '../../../projects/infrastructure/local_project_store.dart';
import '../../../projects/infrastructure/project_version_repository.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/mandap_layout.dart';
import '../top_view_2d/mandap_2d_canvas.dart';
import '../../../spikes/renderer_3d/mandap_3d_spike_screen.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/sync_status_badge.dart';

class MandapEditorShell extends StatefulWidget {
  final String projectId;

  const MandapEditorShell({super.key, required this.projectId});

  @override
  State<MandapEditorShell> createState() => _MandapEditorShellState();
}

class _MandapEditorShellState extends State<MandapEditorShell> {
  late ProjectSyncService _syncService;
  late MandapEditorController _controller;
  bool _isInitialized = false;
  bool _is3DView = false;

  @override
  void initState() {
    super.initState();
    _controller = MandapEditorController();
    _initServices();
  }

  Future<void> _initServices() async {
    final store = LocalProjectStore();
    // Assuming organizationId is available via context or auth, hardcoding "org_1" for demo if absent
    final repo = context.read<ProjectVersionRepository>();

    _syncService = ProjectSyncService(
      organizationId: 'org_1', // TODO: Get from Auth/Org Context
      projectId: widget.projectId,
      store: store,
      versionRepo: repo,
    );

    await _syncService.initialize();

    // Load local layout
    final layout = await store.getLayout(widget.projectId);
    if (layout != null) {
      _controller.loadCustomLayout(layout);
    } else {
      // Fallback empty if nothing exists
      _controller.loadCustomLayout(const MandapLayout(nodes: {}, edges: {}, zones: []));
    }

    // Bind controller changes to SyncService auto-save
    _controller.addListener(_onControllerChanged);

    if (mounted) setState(() => _isInitialized = true);
  }

  void _onControllerChanged() {
    // A simplified trigger: If history changes (a new command was executed), trigger sync
    // In a full implementation, the controller would emit explicit layout mutation events.
    // We will just invoke it when isCustomLayout is updated via commands.
    _syncService.onLayoutModified(_controller.layout, 'local_base_version');
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF064E3B), // Deep engineering green
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _controller),
        Provider.value(value: _syncService),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF064E3B), // Engineering green background
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: const Text('MANDAP BUILDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            const SyncStatusBadge(),
            const SizedBox(width: 16),
          ],
        ),
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              _is3DView 
                ? const Mandap3DSpikeScreen()
                : Mandap2DCanvas(controller: _controller),
              
              // 2D/3D Switch Overlay
              Positioned(
                top: 16,
                right: 16,
                child: SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    selectedForegroundColor: Colors.white,
                    selectedIconColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(value: false, label: Text('2D')),
                    ButtonSegment(value: true, label: Text('3D')),
                  ],
                  selected: {_is3DView},
                  onSelectionChanged: (val) => setState(() => _is3DView = val.first),
                ),
              ),

              // Toolbar (Floating)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(child: EditorToolbar(controller: _controller)),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.black26),
        SizedBox(
          width: 320,
          child: InspectorPanel(controller: _controller),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        _is3DView 
          ? const Mandap3DSpikeScreen()
          : Mandap2DCanvas(controller: _controller),

        Positioned(
          top: 16,
          right: 16,
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
            segments: const [
              ButtonSegment(value: false, label: Text('2D')),
              ButtonSegment(value: true, label: Text('3D')),
            ],
            selected: {_is3DView},
            onSelectionChanged: (val) => setState(() => _is3DView = val.first),
          ),
        ),

        Positioned(
          bottom: 100, // Above bottom sheet
          left: 0,
          right: 0,
          child: Center(child: EditorToolbar(controller: _controller)),
        ),

        // Draggable Inspector Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.1,
          minChildSize: 0.1,
          maxChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: InspectorPanel(
                controller: _controller,
                scrollController: scrollController,
              ),
            );
          },
        ),
      ],
    );
  }
}
