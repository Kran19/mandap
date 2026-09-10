import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/presentation/responsive_layout.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../infrastructure/projects_repository.dart';
import 'projects_dashboard_screen.dart';
import '../../mandap/application/commands/add_component_commands.dart';
import '../../mandap/application/mandap_editor_controller.dart';
import '../../mandap/domain/entities/mandap_layout.dart';
import '../../mandap/domain/generators/base_truss_architecture_generator.dart';
import '../../mandap/domain/specifications/component_specifications.dart';
import '../domain/sync_state.dart';
import '../domain/local_project_sync_metadata.dart';
import '../infrastructure/local_project_store.dart';

/// Entry point for the Component Wizard.
/// Navigated to from [ProjectsDashboardScreen] when creating a NEW project,
/// or from the Editor via the "Add Component" button at any time.
///
/// Flow:
///   ComponentSelectionScreen (pick TRUSS / PIPE / FLOORING / STAGE)
///     → MeasurementFormScreen (enter measurements for chosen component)
///     → Execute Command → Persist DIRTY → Navigate to Editor
class ComponentWizardScreen extends StatefulWidget {
  final String projectId;

  const ComponentWizardScreen({super.key, required this.projectId});

  @override
  State<ComponentWizardScreen> createState() => _ComponentWizardScreenState();
}

enum _ComponentType { truss, pipe, flooring, stage }

class _ComponentWizardScreenState extends State<ComponentWizardScreen> {
  _ComponentType? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _selected == null
          ? AppBottomNavBar(
              currentIndex: 0,
              onTabSelected: (index) async {
                if (index == 0) {
                  // Already on Design/Components
                } else if (index == 1) {
                  context.go('/projects');
                } else if (index == 2) {
                  final coordinator = context.read<BootstrapCoordinator>();
                  final user = coordinator.current.user;
                  showDialog(
                    context: context,
                    builder: (ctx) => SettingsDialog(
                      orgName: user?.organizationId,
                      planName: 'Active Plan',
                    ),
                  );
                } else if (index == 3) {
                  final coordinator = context.read<BootstrapCoordinator>();
                  await coordinator.authRepository.clearTokens();
                  await coordinator.bootstrap();
                }
              },
            )
          : null,
      body: Stack(
        children: [
          // Dark premium background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
              ),
            ),
          ),

          // Ambient glow
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _selected == null
                ? _buildSelectionPage()
                : _buildMeasurementPage(_selected!),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          title: 'Add Component',
          subtitle: 'Choose the type of structure to design',
          onBack: (widget.projectId != 'new' && widget.projectId.isNotEmpty)
              ? () => context.go('/editor?projectId=${widget.projectId}')
              : null,
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildCapsuleCard(
                    type: _ComponentType.truss,
                    icon: Icons.architecture,
                    label: 'TRUSS',
                    description: 'Horizontal roof / portal truss system',
                    gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                  ),
                  const SizedBox(height: 16),
                  _buildCapsuleCard(
                    type: _ComponentType.pipe,
                    icon: Icons.vertical_align_top_rounded,
                    label: 'PIPE',
                    description: 'Vertical support pipe / pole element',
                    gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  const SizedBox(height: 16),
                  _buildCapsuleCard(
                    type: _ComponentType.flooring,
                    icon: Icons.square_foot_rounded,
                    label: 'FLOORING',
                    description: 'Event carpet / platform floor surface',
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  const SizedBox(height: 16),
                  _buildCapsuleCard(
                    type: _ComponentType.stage,
                    icon: Icons.theater_comedy_rounded,
                    label: 'STAGE',
                    description: 'Raised stage platform structure',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapsuleCard({
    required _ComponentType type,
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = type),
        borderRadius: BorderRadius.circular(32),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              // Capsule Icon Badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 18),

              // Title and Description
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Trailing Arrow Circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementPage(_ComponentType type) {
    return switch (type) {
      _ComponentType.truss => _TrussMeasurementForm(
          projectId: widget.projectId,
          onBack: () => setState(() => _selected = null),
        ),
      _ComponentType.pipe => _PipeMeasurementForm(
          projectId: widget.projectId,
          onBack: () => setState(() => _selected = null),
        ),
      _ComponentType.flooring => _FlooringMeasurementForm(
          projectId: widget.projectId,
          onBack: () => setState(() => _selected = null),
        ),
      _ComponentType.stage => _StageMeasurementForm(
          projectId: widget.projectId,
          onBack: () => setState(() => _selected = null),
        ),
    };
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    VoidCallback? onBack,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared measurement form widget base
// ─────────────────────────────────────────────────────────────────────────────

class _MeasurementFormBase extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _MeasurementFormBase({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...fields,
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 8,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'NEXT — Add to Design',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// Persists [layout] to the local store for [projectId] and marks it DIRTY.
/// The editor screen will pick up this change when it loads and trigger sync.
/// Does NOT mark as CLEAN or trigger a network call — that is the sync service's job.
/// Persists [layout] to the local store for [projectId] and marks it DIRTY.
/// The editor screen will pick up this change when it loads and trigger sync.
/// Does NOT mark as CLEAN or trigger a network call — that is the sync service's job.
Future<void> _persistLayout(String projectId, MandapLayout layout) async {
  final store = LocalProjectStore();
  await store.saveLayout(projectId, layout);

  // Retrieve current metadata to preserve the baseVersionId
  final existingMeta = await store.getMetadata(projectId);
  final meta = LocalProjectSyncMetadata(
    projectId: projectId,
    baseVersionId: existingMeta?.baseVersionId ?? '',
    syncState: SyncState.DIRTY,
    dirty: true,
  );
  await store.saveMetadata(meta);
}

Future<String> _ensureProjectId(BuildContext context, String currentProjectId) async {
  if (currentProjectId != 'new' && currentProjectId.trim().isNotEmpty) {
    return currentProjectId;
  }
  try {
    final coordinator = context.read<BootstrapCoordinator>();
    final projectsRepo = context.read<ProjectsRepository>();
    final orgId = coordinator.current.user?.organizationId;
    if (orgId != null) {
      final project = await projectsRepo.createProject(
        orgId,
        'New Project',
        null,
      );
      return project.id;
    }
  } catch (e) {
    print('Failed to create project on server: $e');
  }
  return 'proj_${DateTime.now().millisecondsSinceEpoch}';
}

Widget _numberField(TextEditingController ctrl, String label, {String? hint}) {

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
        suffixText: 'ft',
        suffixStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Truss
// ─────────────────────────────────────────────────────────────────────────────

class _TrussMeasurementForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onBack;
  const _TrussMeasurementForm({required this.projectId, required this.onBack});

  @override
  State<_TrussMeasurementForm> createState() => _TrussMeasurementFormState();
}

class _TrussMeasurementFormState extends State<_TrussMeasurementForm> {
  final _width = TextEditingController(text: '100');
  final _depth = TextEditingController(text: '100');
  final _poleSpacing = TextEditingController(text: '30');
  final _poleHeight = TextEditingController(text: '20');
  bool _includeCenterCross = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    final w = double.tryParse(_width.text) ?? 0;
    final d = double.tryParse(_depth.text) ?? 0;
    final s = double.tryParse(_poleSpacing.text) ?? 30.0;
    final h = double.tryParse(_poleHeight.text) ?? 20.0;

    if (w <= 0 || d <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plot Width and Depth must be positive values.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final effectiveId = await _ensureProjectId(context, widget.projectId);
      if (!mounted) return;

      final params = BaseTrussGenerationParams(
        plotWidth: w,
        plotDepth: d,
        preferredPoleSpacing: s > 0 ? s : 30.0,
        poleHeight: h > 0 ? h : 20.0,
        includeCenterControlPoint: _includeCenterCross,
        availableTrussSizes: const [10.0, 30.0, 50.0],
      );

      final generatedLayout = BaseTrussArchitectureGenerator.generate(params);

      await _persistLayout(effectiveId, generatedLayout);
      if (mounted) context.go('/editor?projectId=$effectiveId');
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating structure: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MeasurementFormBase(
        title: 'Truss Architecture Setup',
        subtitle: 'Configure plot size and structural spacing',
        isLoading: _isLoading,
        onBack: widget.onBack,
        onNext: _submit,
        fields: [
          // Available inventory chip row
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Truss Inventory',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['10 ft', '30 ft', '50 ft'].map((size) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6366F1)),
                      ),
                      child: Text(
                        size,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          _numberField(_width, 'Plot Width (X-axis)', hint: 'e.g. 100'),
          _numberField(_depth, 'Plot Depth (Z-axis)', hint: 'e.g. 100'),
          _numberField(_poleSpacing, 'Preferred Pole Spacing', hint: 'Default: 30'),
          _numberField(_poleHeight, 'Pole Height', hint: 'Default: 20'),
          // Center Structural Pole & Cross toggle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Center Structural Pole & Cross (+)',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Generates 17th center pole and 4-way internal truss division (600 ft total)',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
              ),
              value: _includeCenterCross,
              activeColor: const Color(0xFF6366F1),
              onChanged: (val) => setState(() => _includeCenterCross = val),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pipe/Pole
// ─────────────────────────────────────────────────────────────────────────────

class _PipeMeasurementForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onBack;
  const _PipeMeasurementForm({required this.projectId, required this.onBack});

  @override
  State<_PipeMeasurementForm> createState() => _PipeMeasurementFormState();
}

class _PipeMeasurementFormState extends State<_PipeMeasurementForm> {
  final _height = TextEditingController(text: '12');
  final _x = TextEditingController(text: '0');
  final _z = TextEditingController(text: '0');
  final _diameter = TextEditingController(text: '0.5');
  bool _isLoading = false;

  Future<void> _submit() async {
    final h = double.tryParse(_height.text) ?? 0;
    final x = double.tryParse(_x.text) ?? 0;
    final z = double.tryParse(_z.text) ?? 0;
    final dia = double.tryParse(_diameter.text) ?? 0.5;
    if (h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Height must be positive.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final effectiveId = await _ensureProjectId(context, widget.projectId);
      if (!mounted) return;
      final store = LocalProjectStore();
      final existingLayout = await store.getLayout(effectiveId);
      if (!mounted) return;

      final controller = MandapEditorController();
      if (existingLayout != null) {
        controller.layout = existingLayout;
      }
      final spec = PoleSpecification(height: h, x: x, z: z, diameter: dia);
      controller.executeCommand(AddPoleCommand(spec: spec));
      await _persistLayout(effectiveId, controller.layout);
      if (mounted) context.go('/editor?projectId=$effectiveId');
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding pipe: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MeasurementFormBase(
        title: 'Pipe Dimensions',
        subtitle: 'Vertical support pipe / pole element',
        isLoading: _isLoading,
        onBack: widget.onBack,
        onNext: _submit,
        fields: [
          _numberField(_height, 'Height', hint: 'e.g. 12'),
          _numberField(_diameter, 'Diameter', hint: 'e.g. 0.5'),
          _numberField(_x, 'Position X', hint: 'e.g. 0'),
          _numberField(_z, 'Position Z', hint: 'e.g. 0'),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Flooring
// ─────────────────────────────────────────────────────────────────────────────

class _FlooringMeasurementForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onBack;
  const _FlooringMeasurementForm({required this.projectId, required this.onBack});

  @override
  State<_FlooringMeasurementForm> createState() => _FlooringMeasurementFormState();
}

class _FlooringMeasurementFormState extends State<_FlooringMeasurementForm> {
  final _width = TextEditingController(text: '40');
  final _depth = TextEditingController(text: '30');
  final _x = TextEditingController(text: '0');
  final _z = TextEditingController(text: '0');
  bool _isLoading = false;

  Future<void> _submit() async {
    final w = double.tryParse(_width.text) ?? 0;
    final d = double.tryParse(_depth.text) ?? 0;
    final x = double.tryParse(_x.text) ?? 0;
    final z = double.tryParse(_z.text) ?? 0;
    if (w <= 0 || d <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Width and Depth must be positive.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final effectiveId = await _ensureProjectId(context, widget.projectId);
      if (!mounted) return;
      final store = LocalProjectStore();
      final existingLayout = await store.getLayout(effectiveId);
      if (!mounted) return;

      final controller = MandapEditorController();
      if (existingLayout != null) {
        controller.layout = existingLayout;
      }
      final spec = FlooringSpecification(width: w, depth: d, x: x, z: z);
      controller.executeCommand(AddCarpetCommand(spec: spec));
      await _persistLayout(effectiveId, controller.layout);
      if (mounted) context.go('/editor?projectId=$effectiveId');
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding flooring: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MeasurementFormBase(
        title: 'Flooring Dimensions',
        subtitle: 'Event carpet / platform floor surface',
        isLoading: _isLoading,
        onBack: widget.onBack,
        onNext: _submit,
        fields: [
          _numberField(_width, 'Width (X-axis)', hint: 'e.g. 40'),
          _numberField(_depth, 'Depth (Z-axis)', hint: 'e.g. 30'),
          _numberField(_x, 'Position X', hint: 'e.g. 0'),
          _numberField(_z, 'Position Z', hint: 'e.g. 0'),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage
// ─────────────────────────────────────────────────────────────────────────────

class _StageMeasurementForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onBack;
  const _StageMeasurementForm({required this.projectId, required this.onBack});

  @override
  State<_StageMeasurementForm> createState() => _StageMeasurementFormState();
}

class _StageMeasurementFormState extends State<_StageMeasurementForm> {
  final _width = TextEditingController(text: '20');
  final _depth = TextEditingController(text: '10');
  final _height = TextEditingController(text: '2');
  final _x = TextEditingController(text: '10');
  final _z = TextEditingController(text: '10');
  bool _isLoading = false;

  Future<void> _submit() async {
    final w = double.tryParse(_width.text) ?? 0;
    final d = double.tryParse(_depth.text) ?? 0;
    final h = double.tryParse(_height.text) ?? 0;
    final x = double.tryParse(_x.text) ?? 0;
    final z = double.tryParse(_z.text) ?? 0;
    if (w <= 0 || d <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Width, Depth, and Height must be positive.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final effectiveId = await _ensureProjectId(context, widget.projectId);
      if (!mounted) return;
      final store = LocalProjectStore();
      final existingLayout = await store.getLayout(effectiveId);
      if (!mounted) return;

      final controller = MandapEditorController();
      if (existingLayout != null) {
        controller.layout = existingLayout;
      }
      final spec = StageSpecification(width: w, depth: d, height: h, x: x, z: z);
      controller.executeCommand(AddStageCommand(spec: spec));
      await _persistLayout(effectiveId, controller.layout);
      if (mounted) context.go('/editor?projectId=$effectiveId');
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding stage: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MeasurementFormBase(
        title: 'Stage Dimensions',
        subtitle: 'Raised platform structure',
        isLoading: _isLoading,
        onBack: widget.onBack,
        onNext: _submit,
        fields: [
          _numberField(_width, 'Width (X-axis)', hint: 'e.g. 20'),
          _numberField(_depth, 'Depth (Z-axis)', hint: 'e.g. 10'),
          _numberField(_height, 'Platform height', hint: 'e.g. 2'),
          _numberField(_x, 'Position X', hint: 'e.g. 10'),
          _numberField(_z, 'Position Z', hint: 'e.g. 10'),
        ],
      );
}
