import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../../../core/presentation/responsive_layout.dart';
import '../infrastructure/projects_repository.dart';
import '../infrastructure/local_project_store.dart';
import '../../../core/network/api_client.dart';

class ProjectsDashboardScreen extends StatefulWidget {
  const ProjectsDashboardScreen({super.key});

  @override
  State<ProjectsDashboardScreen> createState() =>
      _ProjectsDashboardScreenState();
}

class _ProjectsDashboardScreenState extends State<ProjectsDashboardScreen>
    with TickerProviderStateMixin {
  late Future<List<ProjectMetadata>> _projectsFuture;
  String? _orgName;
  String? _planName;
  bool _isCreating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadProjects();
    _loadOrgAndPlan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loadProjects() {
    final coordinator = context.read<BootstrapCoordinator>();
    final projectsRepo = context.read<ProjectsRepository>();
    setState(() {
      _projectsFuture = projectsRepo
          .getProjects(coordinator.current.user!.organizationId!)
          .then((list) {
        _fadeController.forward(from: 0);
        return list;
      });
    });
  }

  Future<void> _loadOrgAndPlan() async {
    final coordinator = context.read<BootstrapCoordinator>();
    final user = coordinator.current.user;
    final entitlement = coordinator.current.entitlement;
    final token = await coordinator.authRepository.getAccessToken();
    if (token == null || user?.organizationId == null) return;
    final apiClient = context.read<ApiClient>();
    try {
      final orgResp = await http.get(
        Uri.parse('${apiClient.baseUrl}/organizations/${user!.organizationId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (orgResp.statusCode == 200 && mounted) {
        final data = jsonDecode(orgResp.body);
        setState(() => _orgName = data['name'] ?? user.organizationId);
      }
      if (entitlement?.planId != null) {
        final planResp = await http.get(
          Uri.parse('${apiClient.baseUrl}/billing/plans'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (planResp.statusCode == 200 && mounted) {
          final plans = jsonDecode(planResp.body) as List;
          final plan = plans.firstWhere(
            (p) => p['id'] == entitlement!.planId,
            orElse: () => null,
          );
          if (plan != null) setState(() => _planName = plan['name']);
        }
      }
    } catch (_) {}
  }

  Future<void> _createProject() async {
    if (_isCreating) return;
    final coordinator = context.read<BootstrapCoordinator>();
    final projectsRepo = context.read<ProjectsRepository>();
    final nameController = TextEditingController(text: 'New Project');
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateProjectDialog(
        nameController: nameController,
        descController: descController,
      ),
    );
    if (result != true || !mounted) return;
    setState(() => _isCreating = true);
    try {
      final project = await projectsRepo.createProject(
        coordinator.current.user!.organizationId!,
        nameController.text.trim().isEmpty ? 'New Project' : nameController.text.trim(),
        descController.text.trim().isEmpty ? null : descController.text.trim(),
      );
      if (mounted) context.go('/component-wizard?projectId=${project.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(orgName: _orgName, planName: _planName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<BootstrapCoordinator>();
    final user = coordinator.current.user;
    final entitlement = coordinator.current.entitlement;
    final displayName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final avatarInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final statusText = entitlement?.subscriptionStatus ?? 'FREE';
    final statusColor = statusText == 'TRIALING'
        ? const Color(0xFF6EE7B7)
        : statusText == 'ACTIVE'
            ? const Color(0xFF34D399)
            : const Color(0xFFFF7E7E);

    final isMobile = MediaQuery.of(context).size.width < 800;

    final sidebar = Container(
      width: 260,
      color: const Color(0xFF16161D),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.architecture, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Mandap',
                          style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E28),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(avatarInitial,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName.isEmpty ? 'User' : displayName,
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                            Text(user?.email ?? '',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WORKSPACE',
                          style: GoogleFonts.inter(
                              color: Colors.white24,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 16, color: Colors.white38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_orgName ?? 'Loading...',
                                style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: Colors.white38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_planName ?? 'Free Plan',
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _SidebarNavItem(icon: Icons.grid_view_rounded, label: 'Projects', isActive: true, onTap: () {}),
                _SidebarNavItem(icon: Icons.settings_rounded, label: 'Settings', onTap: _showSettings),
                _SidebarNavItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () async {
                    await coordinator.authRepository.clearTokens();
                    await coordinator.bootstrap();
                  },
                ),
          const SizedBox(height: 16),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: isMobile 
              ? const EdgeInsets.fromLTRB(20, 24, 20, 16)
              : const EdgeInsets.fromLTRB(36, 48, 36, 24),
          child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Projects',
                                style: GoogleFonts.outfit(
                                    fontSize: isMobile ? 24 : 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -1)),
                            const SizedBox(height: 4),
                            Text('Design and manage your mandap layouts',
                                style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14, color: Colors.white38)),
                          ],
                        ),
                      ),
                      _CreateButton(isLoading: _isCreating, onPressed: _createProject),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<ProjectMetadata>>(
                    future: _projectsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text('Failed to load projects',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadProjects,
                              child: const Text('Retry', style: TextStyle(color: Color(0xFF8B5CF6))),
                            ),
                          ]),
                        );
                      }
                      final projects = snapshot.data ?? [];
                      if (projects.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.add_rounded, size: 40, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 20),
                            Text('No projects yet',
                                style: GoogleFonts.outfit(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Create your first mandap layout to get started',
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                            const SizedBox(height: 28),
                            _CreateButton(isLoading: _isCreating, onPressed: _createProject),
                          ]),
                        );
                      }
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: GridView.builder(
                          padding: isMobile 
                              ? const EdgeInsets.fromLTRB(20, 8, 20, 36)
                              : const EdgeInsets.fromLTRB(36, 8, 36, 36),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : MediaQuery.of(context).size.width < 1200 ? 2 : 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: isMobile ? 2.0 : 1.4,
                          ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            return _ProjectCard(
                              project: projects[index],
                              onTap: () => context.go('/editor?projectId=${projects[index].id}'),
                              onDelete: _loadProjects,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

    return ResponsiveAppShell(
      sidebar: sidebar,
      mobileAppBar: const AppMobileHeader(),
      mobileBottomBar: AppBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) async {
          if (index == 0) {
            context.go('/component-wizard');
          } else if (index == 1) {
            // Already on projects
          } else if (index == 2) {
            _showSettings();
          } else if (index == 3) {
            await coordinator.authRepository.clearTokens();
            await coordinator.bootstrap();
          }
        },
      ),
      child: content,
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final ProjectMetadata project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ProjectCard({required this.project, required this.onTap, required this.onDelete});
  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.project.status == 'ACTIVE';
    final colorPairs = [
      [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      [const Color(0xFF6366F1), const Color(0xFF4338CA)],
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    ];
    final colors = colorPairs[widget.project.id.hashCode.abs() % colorPairs.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isActive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF16161D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered && isActive ? colors[0].withOpacity(0.5) : Colors.white10,
            ),
            boxShadow: _isHovered && isActive
                ? [BoxShadow(color: colors[0].withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                            : const LinearGradient(colors: [Color(0xFF1E1E28), Color(0xFF1E1E28)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      ),
                      child: Center(
                        child: Icon(
                          isActive ? Icons.architecture_rounded : Icons.archive_rounded,
                          size: 40,
                          color: isActive ? Colors.white70 : Colors.white24,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final coordinator = context.read<BootstrapCoordinator>();
                            final projectsRepo = context.read<ProjectsRepository>();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => const _DeleteConfirmationDialog(),
                            );
                            if (confirm != true) return;

                            try {
                              await projectsRepo.deleteProject(
                                coordinator.current.user!.organizationId!,
                                widget.project.id,
                              );
                              await LocalProjectStore().deleteProjectState(widget.project.id);
                              widget.onDelete();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Failed to delete project: $e'),
                                  backgroundColor: Colors.red.shade700,
                                ));
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.project.name,
                            style: GoogleFonts.inter(
                                color: isActive ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Text('ARCHIVED',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(_formatDate(widget.project.updatedAt),
                        style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _CreateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _CreateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isLoading)
                const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(isLoading ? 'Creating...' : 'New Project',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
  });
  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFFFF6B6B)
        : widget.isActive
            ? const Color(0xFF8B5CF6)
            : Colors.white54;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF8B5CF6).withOpacity(0.12)
                : _hovered
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25))
                : null,
          ),
          child: Row(children: [
            Icon(widget.icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(widget.label,
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  const _CreateProjectDialog({required this.nameController, required this.descController});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16161D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width < 500 ? double.infinity : 440,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Create New Project',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Give your mandap layout a name to get started.',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          _DialogField(controller: nameController, label: 'Project Name', hint: 'e.g. Sharma Wedding Layout'),
          const SizedBox(height: 16),
          _DialogField(
              controller: descController,
              label: 'Description (optional)',
              hint: 'Brief description...',
              maxLines: 3),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white12)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, true),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text('Create',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  const _DialogField({required this.controller, required this.label, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF0F0F13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}

class SettingsDialog extends StatelessWidget {
  final String? orgName;
  final String? planName;
  const SettingsDialog({super.key, this.orgName, this.planName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16161D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width < 500 ? double.infinity : 480,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_rounded, color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 14),
            Text('Settings',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 24),
          SettingsItem(label: 'Organization', value: orgName ?? 'Unknown', icon: Icons.business_rounded),
          const SizedBox(height: 12),
          SettingsItem(label: 'Current Plan', value: planName ?? 'Free Plan', icon: Icons.bolt_rounded),
          const SizedBox(height: 12),
          SettingsItem(label: 'Theme', value: 'Dark Mode', icon: Icons.dark_mode_rounded),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Close',
                  style: GoogleFonts.inter(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const SettingsItem({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16161D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width < 500 ? double.infinity : 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Delete Project?',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text('Delete',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
