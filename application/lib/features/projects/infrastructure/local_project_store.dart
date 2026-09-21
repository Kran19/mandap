import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/local_project_sync_metadata.dart';
import '../../mandap/domain/entities/mandap_layout.dart';
import '../../mandap/infrastructure/layout_serializer.dart';

class MandapSavedProject {
  final String id;
  final String title;
  final String moduleType; // 'truss', 'pole', 'stage', 'flooring'
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> parameters;

  MandapSavedProject({
    required this.id,
    required this.title,
    required this.moduleType,
    required this.createdAt,
    required this.updatedAt,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'moduleType': moduleType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'parameters': parameters,
      };

  factory MandapSavedProject.fromJson(Map<String, dynamic> json) => MandapSavedProject(
        id: json['id'] as String,
        title: json['title'] as String,
        moduleType: json['moduleType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      );
}

class LocalProjectStore {
  static const String _metaPrefix = 'mandap_meta_';
  static const String _layoutPrefix = 'mandap_layout_';
  static const String _projectCatalogPrefix = 'mandap_proj_';

  Future<LocalProjectSyncMetadata?> getMetadata(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString('$_metaPrefix$projectId');
      if (content == null) return null;
      return LocalProjectSyncMetadata.fromJson(jsonDecode(content));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMetadata(LocalProjectSyncMetadata metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_metaPrefix${metadata.projectId}', jsonEncode(metadata.toJson()));
  }

  Future<MandapLayout?> getLayout(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString('$_layoutPrefix$projectId');
      if (content == null) return null;
      final Map<String, dynamic> json = jsonDecode(content);
      return LayoutSerializer.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLayout(String projectId, MandapLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> layoutJson = LayoutSerializer.toJson(layout);
    await prefs.setString('$_layoutPrefix$projectId', jsonEncode(layoutJson));
  }

  Future<void> deleteProjectState(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_metaPrefix$projectId');
    await prefs.remove('$_layoutPrefix$projectId');
  }

  Future<List<String>> getAllLocalProjectIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final ids = <String>{};
    for (var key in keys) {
      if (key.startsWith(_metaPrefix)) {
        ids.add(key.substring(_metaPrefix.length));
      } else if (key.startsWith(_layoutPrefix)) {
        ids.add(key.substring(_layoutPrefix.length));
      }
    }
    return ids.toList();
  }

  // --- Unified Project Catalog Methods ---

  Future<void> saveProjectRecord(MandapSavedProject project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_projectCatalogPrefix${project.id}', jsonEncode(project.toJson()));
  }

  Future<MandapSavedProject?> getProjectRecord(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString('$_projectCatalogPrefix$projectId');
      if (content == null) return null;
      return MandapSavedProject.fromJson(jsonDecode(content));
    } catch (_) {
      return null;
    }
  }

  Future<List<MandapSavedProject>> getAllSavedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final list = <MandapSavedProject>[];
      for (final key in keys) {
        if (key.startsWith(_projectCatalogPrefix)) {
          final content = prefs.getString(key);
          if (content != null) {
            try {
              list.add(MandapSavedProject.fromJson(jsonDecode(content)));
            } catch (_) {}
          }
        }
      }
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteProjectRecord(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_projectCatalogPrefix$projectId');
    await deleteProjectState(projectId);
  }
}
