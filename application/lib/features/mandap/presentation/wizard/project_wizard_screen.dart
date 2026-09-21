import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandap/l10n/app_localizations.dart';
import 'package:mandap/core/network/api_client.dart';
import 'package:mandap/features/auth/infrastructure/auth_repository.dart';
import 'package:mandap/features/projects/infrastructure/project_version_repository.dart';
import 'package:mandap/features/projects/infrastructure/local_project_store.dart';
import 'package:mandap/features/projects/application/project_sync_service.dart';
import 'package:mandap/features/projects/application/create_truss_project_command.dart';
import '../mandap_editor_screen.dart';

class _DummyTokenProvider implements AuthTokenProvider {
  const _DummyTokenProvider();
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<bool> refreshToken() async => false;
  @override
  Future<void> clearTokens() async {}
}

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
  double _trussWidth = 100.0;
  double _trussDepth = 100.0;
  double _towerHeight = 20.0;
  int _points = 5;
  bool _isGenerating = false;

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isGenerating = true);

    try {
      final store = LocalProjectStore();
      final command = CreateTrussProjectCommand(
        store: store,
        syncService: ProjectSyncService(
          organizationId: 'org_1',
          projectId: 'pending',
          store: store,
          versionRepo: ProjectVersionRepository(
            apiClient: ApiClient(
              baseUrl: 'http://localhost',
              tokenProvider: const _DummyTokenProvider(),
            ),
          ),
        ),
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
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MandapEditorScreen(projectId: projectId),
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
                    
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.projectName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _projectName = v!,
                    ),
                    const SizedBox(height: 24),

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
                          backgroundColor: const Color(0xFFDC2626),
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
