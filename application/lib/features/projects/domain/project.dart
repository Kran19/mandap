class Project {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String status; // 'ACTIVE' or 'ARCHIVED'
  final String? currentVersionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  Project({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.status,
    this.currentVersionId,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isArchived => status == 'ARCHIVED';
}
