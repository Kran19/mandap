import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/entitlement_result.dart';
import '../../auth/infrastructure/auth_repository.dart';

class BillingRepository {
  final String baseUrl;
  final AuthTokenProvider tokenProvider;

  BillingRepository({required this.baseUrl, required this.tokenProvider});

  Future<EntitlementResult?> getEntitlement(String organizationId) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/entitlement/$organizationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EntitlementResult.fromJson(data);
      } else {
        print('GET ENTITLEMENT ERROR STATUS: ${response.statusCode}, BODY: ${response.body}');
      }
    } catch (e) {
      // Network error or backend offline
      print('GET ENTITLEMENT ERROR: $e');
      return null;
    }
    return null;
  }

  Future<List<dynamic>> getActivePlans() async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/billing/plans'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>?> setupTrial({
    required String organizationId,
    required String planId,
    required String identityReference,
    required String idempotencyKey,
  }) async {
    final token = await tokenProvider.getAccessToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/billing/trial/$organizationId/setup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'planId': planId,
        'identityReference': identityReference,
        'idempotencyKey': idempotencyKey,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}
