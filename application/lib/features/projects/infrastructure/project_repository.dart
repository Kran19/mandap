import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../domain/project.dart';
import '../domain/project_version.dart';
import 'project_dtos.dart';

class ProjectRepository {
  final ApiClient apiClient;

  ProjectRepository({required this.apiClient});

  Future<PaginatedProjects> getProjects(String organizationId, {int page = 1, int limit = 20}) async {
    final response = await apiClient.get('/organizations/$organizationId/projects?page=$page&limit=$limit');
    return PaginatedProjects.fromJson(jsonDecode(response.body));
  }

  Future<Project> getProject(String organizationId, String projectId) async {
    final response = await apiClient.get('/organizations/$organizationId/projects/$projectId');
    return ProjectDtoMapper.fromJson(jsonDecode(response.body));
  }

  Future<Project> createProject(String organizationId, String name, String? description) async {
    final response = await apiClient.post('/organizations/$organizationId/projects', body: {
      'name': name,
      if (description != null) 'description': description,
    });
    return ProjectDtoMapper.fromJson(jsonDecode(response.body));
  }

  Future<Project> updateProject(String organizationId, String projectId, String? name, String? description) async {
    final response = await apiClient.patch('/organizations/$organizationId/projects/$projectId', body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    return ProjectDtoMapper.fromJson(jsonDecode(response.body));
  }

  Future<void> archiveProject(String organizationId, String projectId) async {
    await apiClient.post('/organizations/$organizationId/projects/$projectId/archive');
  }

  Future<void> restoreProject(String organizationId, String projectId) async {
    await apiClient.post('/organizations/$organizationId/projects/$projectId/restore');
  }
}
