import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../projects/application/create_truss_project_command.dart';
import '../../../projects/infrastructure/local_project_store.dart';
import '../../../projects/application/project_sync_service.dart';
import '../editor/mandap_editor_shell.dart';

class ProjectWizardScreen extends StatefulWidget {
  const ProjectWizardScreen({super.key});

  @override
  State<ProjectWizardScreen> createState() => _ProjectWizardScreenState();
}

class _ProjectWizardScreenState extends State<ProjectWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  String _projectName = '';
  double _plotWidth = 100.0;
  double _plotDepth = 100.0;
  double _trussWidth = 40.0;
  double _trussDepth = 30.0;
  double _towerHeight = 12.0;
  int _points = 5;

  bool _isGenerating = false;

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isGenerating = true);

    try {
      final store = LocalProjectStore();
      // In a real dependency injection setup, we'd pull these from Provider.
      final command = CreateTrussProjectCommand(
        store: store,
        // The sync service for the new project isn't instantiated until the editor opens,
        // so we pass a null/dummy one or refactor the command to not strictly require it 
        // until the project is opened. For now, we mock/omit if not strictly needed in execute.
        syncService: context.read<ProjectSyncService>(), // This will likely throw if not provided globally, but we'll refactor if needed.
      );

      final req = CreateTrussProjectRequest(
        projectName: _projectName,
        plotWidth: _plotWidth,
        plotDepth: _plotDepth,
        trussWidth: _trussWidth,
        trussDepth: _trussDepth,
        towerHeight: _towerHeight,
        points: _points,
      );

      final projectId = await command.execute(req);

      if (!mounted) return;
      
      // Navigate to the builder shell with the newly generated projectId
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MandapEditorShell(projectId: projectId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating project: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.newProject),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Project Name
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.projectName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _projectName = v!,
                    ),
                    const SizedBox(height: 24),

                    // Plot Dimensions
                    Text(l10n.plotSize, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: l10n.plotWidth, border: const OutlineInputBorder()),
                            initialValue: _plotWidth.toString(),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            onSaved: (v) => _plotWidth = double.parse(v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: l10n.plotDepth, border: const OutlineInputBorder()),
                            initialValue: _plotDepth.toString(),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            onSaved: (v) => _plotDepth = double.parse(v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Truss Dimensions
                    Text(l10n.trussDimensions, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: l10n.trussWidth, border: const OutlineInputBorder()),
                            initialValue: _trussWidth.toString(),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            onSaved: (v) => _trussWidth = double.parse(v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: l10n.trussDepth, border: const OutlineInputBorder()),
                            initialValue: _trussDepth.toString(),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            onSaved: (v) => _trussDepth = double.parse(v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: l10n.towerHeight, border: const OutlineInputBorder()),
                            initialValue: _towerHeight.toString(),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                            onSaved: (v) => _towerHeight = double.parse(v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Configuration
                    Text(l10n.roofConfiguration, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 5, label: Text(l10n.points5)),
                        ButtonSegment(value: 6, label: Text(l10n.points6)),
                      ],
                      selected: {_points},
                      onSelectionChanged: (val) {
                        setState(() => _points = val.first);
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // Red accent
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isGenerating ? null : _handleGenerate,
                        child: _isGenerating 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.generateTruss, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
