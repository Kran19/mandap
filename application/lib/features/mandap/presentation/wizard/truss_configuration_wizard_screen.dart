import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/application/bootstrap_coordinator.dart';
import '../../../../features/projects/infrastructure/local_project_store.dart';
import '../../../../features/projects/infrastructure/projects_repository.dart';
import '../../domain/generators/base_truss_architecture_generator.dart';

/// Truss Configuration Wizard Screen
/// Allows arbitrary configuration of plot dimensions, spacing, height,
/// inventory pieces, and center structure before entering the editor.
class TrussConfigurationWizardScreen extends StatefulWidget {
  final String? existingProjectId;

  const TrussConfigurationWizardScreen({super.key, this.existingProjectId});

  @override
  State<TrussConfigurationWizardScreen> createState() =>
      _TrussConfigurationWizardScreenState();
}

class _TrussConfigurationWizardScreenState
    extends State<TrussConfigurationWizardScreen> {
  final _projectName = TextEditingController(text: 'Project 01');
  final _widthController = TextEditingController(text: '100');
  final _depthController = TextEditingController(text: '100');
  final _spacingController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '20');

  final Set<double> _selectedTrussSizes = {10.0, 30.0, 50.0};
  bool _includeCenterCross = true;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _projectName.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _spacingController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final name = _projectName.text.trim().isEmpty ? 'Project 01' : _projectName.text.trim();
    final width = double.tryParse(_widthController.text) ?? 0.0;
    final depth = double.tryParse(_depthController.text) ?? 0.0;
    final spacing = double.tryParse(_spacingController.text) ?? 30.0;
    final height = double.tryParse(_heightController.text) ?? 20.0;

    if (width < 10.0 || depth < 10.0) {
      setState(() => _errorMessage = 'Width and Depth must each be at least 10 ft.');
      return;
    }
    if (spacing < 5.0 || spacing > width || spacing > depth) {
      setState(() => _errorMessage = 'Pole spacing must be at least 5 ft and not exceed plot dimensions.');
      return;
    }
    if (height < 6.0 || height > 50.0) {
      setState(() => _errorMessage = 'Pole height must be between 6 ft and 50 ft.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final params = BaseTrussGenerationParams(
        plotWidth: width,
        plotDepth: depth,
        preferredPoleSpacing: spacing,
        poleHeight: height,
        includeCenterControlPoint: _includeCenterCross,
        availableTrussSizes: _selectedTrussSizes.toList()..sort(),
      );

      final layout = BaseTrussArchitectureGenerator.generate(params);

      // Generate or reuse project ID
      final coordinator = context.read<BootstrapCoordinator>();
      final orgId = coordinator.current.user?.organizationId ?? 'default_org';
      final projectId = widget.existingProjectId ?? 'proj_${DateTime.now().millisecondsSinceEpoch}';

      final store = LocalProjectStore();
      await store.saveLayout(projectId, layout);

      // Try creating in backend repository asynchronously if authenticated
      String effectiveProjectId = projectId;
      try {
        final projectsRepo = context.read<ProjectsRepository>();
        final project = await projectsRepo.createProject(
          orgId,
          name,
          'Truss Structure Design',
        );
        effectiveProjectId = project.id;
        await store.saveLayout(effectiveProjectId, layout);
      } catch (_) {
        // Offline / local resilience
      }

      if (mounted) {
        context.go('/editor?projectId=$effectiveProjectId&name=${Uri.encodeComponent(name)}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to generate truss: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    tooltip: 'Back to Modules',
                    onPressed: () => context.go('/modules'),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TRUSS PROJECT CONFIGURATION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Form Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Project Name
                        const Text(
                          'Project Name',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(controller: _projectName, hint: 'e.g. Project 01', icon: Icons.edit_note_rounded),
                        const SizedBox(height: 24),

                        // Plot Size Header
                        const Text(
                          'Plot Dimensions (Feet)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                controller: _widthController,
                                label: 'Width (X)',
                                hint: '100',
                                suffix: 'ft',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumberField(
                                controller: _depthController,
                                label: 'Depth (Z)',
                                hint: '100',
                                suffix: 'ft',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Preferred Pole Spacing & Pole Height
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                controller: _spacingController,
                                label: 'Preferred Pole Spacing',
                                hint: '30',
                                suffix: 'ft',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumberField(
                                controller: _heightController,
                                label: 'Pole Height',
                                hint: '20',
                                suffix: 'ft',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Truss Inventory Available Sizes
                        const Text(
                          'Truss Inventory (Available Sizes)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: [10.0, 20.0, 30.0, 40.0, 50.0].map((size) {
                            final isSelected = _selectedTrussSizes.contains(size);
                            return FilterChip(
                              label: Text('${size.toInt()} ft'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTrussSizes.add(size);
                                  } else {
                                    if (_selectedTrussSizes.length > 1) {
                                      _selectedTrussSizes.remove(size);
                                    }
                                  }
                                });
                              },
                              backgroundColor: const Color(0xFF1E293B),
                              selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              checkmarkColor: const Color(0xFF60A5FA),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Center Structure Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131C31),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF60A5FA), size: 20),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Center Structure (Cross)',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Creates center control pole and 4-way internal truss division',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _includeCenterCross,
                                activeColor: const Color(0xFF3B82F6),
                                onChanged: (val) => setState(() => _includeCenterCross = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isGenerating ? null : _handleGenerate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'GENERATE TRUSS',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F1523),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0F1523),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }
}
