import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../domain/project_version.dart';
import 'project_dtos.dart';

class ProjectVersionRepository {
  final ApiClient apiClient;

  ProjectVersionRepository({required this.apiClient});

  Future<List<ProjectVersion>> getVersions(String organizationId, String projectId) async {
    final response = await apiClient.get('/organizations/$organizationId/projects/$projectId/versions');
    final responseData = jsonDecode(response.body);
    final items = responseData['data'] as List;
    return items.map((json) => ProjectVersionDtoMapper.fromJson(json)).toList();
  }

  Future<ProjectVersion> getVersion(String organizationId, String projectId, String versionId) async {
    final response = await apiClient.get('/organizations/$organizationId/projects/$projectId/versions/$versionId');
    return ProjectVersionDtoMapper.fromJson(jsonDecode(response.body));
  }

  Future<ProjectVersion> createVersion(
    String organizationId,
    String projectId, {
    required Map<String, dynamic> layoutData,
    String? expectedCurrentVersionId,
  }) async {
    final body = {
      'layoutData': layoutData,
      if (expectedCurrentVersionId != null) 'expectedCurrentVersionId': expectedCurrentVersionId,
    };
    
    final response = await apiClient.post(
      '/organizations/$organizationId/projects/$projectId/versions',
      body: body,
    );
    return ProjectVersionDtoMapper.fromJson(jsonDecode(response.body));
  }

  Future<ProjectVersion> restoreVersion(String organizationId, String projectId, String versionId) async {
    final response = await apiClient.post('/organizations/$organizationId/projects/$projectId/versions/$versionId/restore');
    return ProjectVersionDtoMapper.fromJson(jsonDecode(response.body));
  }
}
