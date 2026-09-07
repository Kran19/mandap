import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/organization.dart';

class OrganizationRepository {
  final ApiClient apiClient;
  static const String _activeOrgKey = 'mandap_active_org_id';

  OrganizationRepository({required this.apiClient});

  Future<List<Organization>> getOrganizations() async {
    final response = await apiClient.get('/organizations');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Organization.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load organizations');
    }
  }

  Future<Organization?> getActiveOrganization() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString(_activeOrgKey);
    
    if (orgId == null) return null;

    try {
      final response = await apiClient.get('/organizations/$orgId');
      if (response.statusCode == 200) {
        return Organization.fromJson(jsonDecode(response.body));
      }
    } catch (_) {
      // If network fails, we might still want to return just the ID, 
      // but without the full object. For now, returning null to force re-fetch or selection.
    }
    return null;
  }

  Future<String?> getActiveOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeOrgKey);
  }

  Future<void> setActiveOrganizationId(String orgId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeOrgKey, orgId);
  }

  Future<void> clearActiveOrganization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrgKey);
  }
}
