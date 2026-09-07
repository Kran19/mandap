class ProjectVersion {
  final String id;
  final String projectId;
  final int versionNumber;
  final Map<String, dynamic>? layoutData;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;

  ProjectVersion({
    required this.id,
    required this.projectId,
    required this.versionNumber,
    this.layoutData,
    this.metadata,
    this.createdBy,
    required this.createdAt,
  });
}
