import '../domain/project.dart';
import '../domain/project_version.dart';

class ProjectDtoMapper {
  static Project fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      organizationId: json['organizationId'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      currentVersionId: json['currentVersionId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      archivedAt: json['archivedAt'] != null ? DateTime.parse(json['archivedAt']) : null,
    );
  }
}

class ProjectVersionDtoMapper {
  static ProjectVersion fromJson(Map<String, dynamic> json) {
    return ProjectVersion(
      id: json['id'],
      projectId: json['projectId'],
      versionNumber: json['versionNumber'],
      layoutData: json['layoutData'],
      metadata: json['metadata'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PaginatedProjects {
  final List<Project> data;
  final int total;
  final int page;
  final int limit;

  PaginatedProjects({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedProjects.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>;
    return PaginatedProjects(
      data: list.map((e) => ProjectDtoMapper.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? list.length,
    );
  }
}
