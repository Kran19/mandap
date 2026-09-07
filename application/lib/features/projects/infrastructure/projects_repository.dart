import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/infrastructure/auth_repository.dart';

class ProjectMetadata {
  final String id;
  final String name;
  final String organizationId;
  final String status;
  final String? currentVersionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectMetadata({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.status,
    this.currentVersionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) {
    return ProjectMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      organizationId: json['organizationId'] as String,
      status: json['status'] as String,
      currentVersionId: json['currentVersionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ProjectsRepository {
  final String baseUrl;
  final AuthTokenProvider tokenProvider;

  ProjectsRepository({required this.baseUrl, required this.tokenProvider});

  Future<List<ProjectMetadata>> getProjects(String organizationId, {int page = 1, int limit = 25}) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/organizations/$organizationId/projects?page=$page&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final items = responseData['data'] as List;
      return items.map((e) => ProjectMetadata.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch projects');
  }

  Future<ProjectMetadata> createProject(String organizationId, String name, String? description) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/organizations/$organizationId/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return ProjectMetadata.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create project: ${response.body}');
  }

  Future<ProjectMetadata> getProject(String organizationId, String projectId) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/organizations/$organizationId/projects/$projectId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return ProjectMetadata.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch project');
  }

  Future<void> archiveProject(String organizationId, String projectId) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/organizations/$organizationId/projects/$projectId/archive'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to archive project');
    }
  }

  Future<void> restoreProject(String organizationId, String projectId) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/organizations/$organizationId/projects/$projectId/restore'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to restore project');
    }
  }

  Future<void> deleteProject(String organizationId, String projectId) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/organizations/$organizationId/projects/$projectId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete project');
    }
  }
}
