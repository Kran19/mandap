import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/local_project_sync_metadata.dart';
import '../../mandap/domain/entities/mandap_layout.dart';
import '../../mandap/infrastructure/layout_serializer.dart';

class LocalProjectStore {
  static const String _metaPrefix = 'mandap_meta_';
  static const String _layoutPrefix = 'mandap_layout_';

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
}
