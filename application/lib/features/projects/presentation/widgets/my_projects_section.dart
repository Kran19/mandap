import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../infrastructure/local_project_store.dart';

enum ProjectModuleFilter { all, truss, pole, stage, flooring }

class MyProjectsSection extends StatefulWidget {
  final VoidCallback? onCreateTrussTap;
  final VoidCallback? onCreatePoleTap;
  final VoidCallback? onCreateStageTap;
  final VoidCallback? onCreateFlooringTap;

  const MyProjectsSection({
    super.key,
    this.onCreateTrussTap,
    this.onCreatePoleTap,
    this.onCreateStageTap,
    this.onCreateFlooringTap,
  });

  @override
  State<MyProjectsSection> createState() => _MyProjectsSectionState();
}

class _MyProjectsSectionState extends State<MyProjectsSection> {
  final LocalProjectStore _store = LocalProjectStore();
  ProjectModuleFilter _activeFilter = ProjectModuleFilter.all;
  List<MandapSavedProject> _allProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await _store.getAllSavedProjects();
    if (mounted) {
      setState(() {
        _allProjects = projects;
        _isLoading = false;
      });
    }
  }

  List<MandapSavedProject> get _filteredProjects {
    switch (_activeFilter) {
      case ProjectModuleFilter.all:
        return _allProjects;
      case ProjectModuleFilter.truss:
        return _allProjects.where((p) => p.moduleType == 'truss').toList();
      case ProjectModuleFilter.pole:
        return _allProjects.where((p) => p.moduleType == 'pole').toList();
      case ProjectModuleFilter.stage:
        return _allProjects.where((p) => p.moduleType == 'stage').toList();
      case ProjectModuleFilter.flooring:
        return _allProjects.where((p) => p.moduleType == 'flooring').toList();
    }
  }

  int _countFor(ProjectModuleFilter filter) {
    switch (filter) {
      case ProjectModuleFilter.all:
        return _allProjects.length;
      case ProjectModuleFilter.truss:
        return _allProjects.where((p) => p.moduleType == 'truss').length;
      case ProjectModuleFilter.pole:
        return _allProjects.where((p) => p.moduleType == 'pole').length;
      case ProjectModuleFilter.stage:
        return _allProjects.where((p) => p.moduleType == 'stage').length;
      case ProjectModuleFilter.flooring:
        return _allProjects.where((p) => p.moduleType == 'flooring').length;
    }
  }

  void _openProject(MandapSavedProject project) {
    final params = project.parameters;
    switch (project.moduleType) {
      case 'truss':
        final trussSize = params['trussSize'] ?? 10.0;
        final width = params['width'] ?? 100.0;
        final length = params['length'] ?? 100.0;
        context.push('/editor?projectId=${project.id}&trussSize=$trussSize&width=$width&length=$length');
        break;
      case 'pole':
        final len = params['length'] ?? 100.0;
        final wid = params['width'] ?? 100.0;
        final pipe = params['pipeSize'] ?? 15.0;
        context.push('/pole?projectId=${project.id}&length=$len&width=$wid&pipeSize=$pipe');
        break;
      case 'stage':
        final len = params['length'] ?? 100.0;
        final wid = params['width'] ?? 100.0;
        final tl = params['tableLength'] ?? 4.0;
        final tw = params['tableWidth'] ?? 8.0;
        context.push('/stage?projectId=${project.id}&length=$len&width=$wid&tableLength=$tl&tableWidth=$tw');
        break;
      case 'flooring':
        final len = params['length'] ?? 100.0;
        final wid = params['width'] ?? 100.0;
        final cl = params['carpetLength'] ?? 4.0;
        final cw = params['carpetWidth'] ?? 4.0;
        context.push('/flooring?projectId=${project.id}&length=$len&width=$wid&carpetLength=$cl&carpetWidth=$cw');
        break;
    }
  }

  Future<void> _deleteProject(MandapSavedProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        title: const Text(
          'Delete Project?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete "${project.title}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stagePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _store.deleteProjectRecord(project.id);
      await _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filtered = _filteredProjects;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar Header
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                filter: ProjectModuleFilter.all,
                label: l10n?.all ?? 'All Projects',
                count: _countFor(ProjectModuleFilter.all),
                color: AppColors.primaryText,
                bgColor: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                filter: ProjectModuleFilter.truss,
                label: l10n?.truss ?? 'Truss',
                count: _countFor(ProjectModuleFilter.truss),
                color: AppColors.trussPrimary,
                bgColor: AppColors.trussLight,
                icon: Icons.architecture_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                filter: ProjectModuleFilter.pole,
                label: l10n?.pipe ?? 'Pipe',
                count: _countFor(ProjectModuleFilter.pole),
                color: AppColors.polePrimary,
                bgColor: AppColors.poleLight,
                icon: Icons.view_column_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                filter: ProjectModuleFilter.stage,
                label: l10n?.stage ?? 'Stage',
                count: _countFor(ProjectModuleFilter.stage),
                color: AppColors.stagePrimary,
                bgColor: AppColors.stageLight,
                icon: Icons.theater_comedy_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                filter: ProjectModuleFilter.flooring,
                label: l10n?.flooring ?? 'Flooring',
                count: _countFor(ProjectModuleFilter.flooring),
                color: AppColors.flooringPrimary,
                bgColor: AppColors.flooringLight,
                icon: Icons.grid_view_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Projects List or Empty State
        if (filtered.isEmpty)
          _buildEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 2.1 : 1.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildProjectCard(filtered[index]);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required ProjectModuleFilter filter,
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    IconData? icon,
  }) {
    final isSelected = _activeFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filter),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? color : AppColors.headerBorder,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? Colors.white : color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(MandapSavedProject project) {
    final l10n = AppLocalizations.of(context);
    final (accentColor, lightBg, moduleLabel, iconData) = switch (project.moduleType) {
      'truss' => (AppColors.trussPrimary, AppColors.trussLight, l10n?.truss.toUpperCase() ?? 'TRUSS', Icons.architecture_rounded),
      'pole' => (AppColors.polePrimary, AppColors.poleLight, l10n?.pipe.toUpperCase() ?? 'PIPE', Icons.view_column_rounded),
      'stage' => (AppColors.stagePrimary, AppColors.stageLight, l10n?.stage.toUpperCase() ?? 'STAGE', Icons.theater_comedy_rounded),
      'flooring' => (AppColors.flooringPrimary, AppColors.flooringLight, l10n?.flooring.toUpperCase() ?? 'FLOORING', Icons.grid_view_rounded),
      _ => (AppColors.trussPrimary, AppColors.trussLight, 'PROJECT', Icons.folder_rounded),
    };

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(project.updatedAt);
    final params = project.parameters;

    final specString = switch (project.moduleType) {
      'truss' => '${params['width'] ?? 100} × ${params['length'] ?? 100} ft · Truss: ${params['trussSize'] ?? 10} ft',
      'pole' => '${params['width'] ?? 100} × ${params['length'] ?? 100} ft · Pipe: ${params['pipeSize'] ?? 15} ft',
      'stage' => '${params['width'] ?? 100} × ${params['length'] ?? 100} ft · Table: ${params['tableLength'] ?? 4}×${params['tableWidth'] ?? 8} ft',
      'flooring' => '${params['width'] ?? 100} × ${params['length'] ?? 100} ft · Sheet: ${params['carpetLength'] ?? 4}×${params['carpetWidth'] ?? 4} ft',
      _ => '',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.headerBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openProject(project),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Module Badge & Delete action
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconData, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            moduleLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.secondaryText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete project',
                      onPressed: () => _deleteProject(project),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Middle: Project title & Specs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specString,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom row: Date & OPEN action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'OPEN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final (title, actionLabel, onAction) = switch (_activeFilter) {
      ProjectModuleFilter.all => ('No projects created yet', 'Create Truss Project', widget.onCreateTrussTap),
      ProjectModuleFilter.truss => ('No Truss projects found', 'Create Truss Project', widget.onCreateTrussTap),
      ProjectModuleFilter.pole => ('No Pipe projects found', 'Create Pipe Project', widget.onCreatePoleTap),
      ProjectModuleFilter.stage => ('No Stage projects found', 'Create Stage Project', widget.onCreateStageTap),
      ProjectModuleFilter.flooring => ('No Flooring projects found', 'Create Flooring Project', widget.onCreateFlooringTap),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.headerBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a module or create a project to start designing your event layout.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trussPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
