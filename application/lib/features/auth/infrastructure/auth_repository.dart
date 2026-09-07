import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/auth_user.dart';

class SessionData {
  final String? accessToken;
  final String? refreshToken;

  const SessionData({this.accessToken, this.refreshToken});
}

abstract class AuthTokenProvider {
  Future<String?> getAccessToken();
  Future<void> clearTokens();
  Future<bool> refreshToken();
}

class AuthRepository implements AuthTokenProvider {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _accessTokenKey = 'mandap_access_token';
  static const String _refreshTokenKey = 'mandap_refresh_token';

  SessionData _currentSession = const SessionData();
  
  final String baseUrl;

  AuthRepository({required this.baseUrl});

  Future<void> initialize() async {
    final access = await _secureStorage.read(key: _accessTokenKey);
    final refresh = await _secureStorage.read(key: _refreshTokenKey);

    _currentSession = SessionData(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  @override
  Future<String?> getAccessToken() async {
    return _currentSession.accessToken;
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    
    _currentSession = const SessionData();
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _secureStorage.write(key: _accessTokenKey, value: access);
    await _secureStorage.write(key: _refreshTokenKey, value: refresh);

    _currentSession = SessionData(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  @override
  Future<bool> refreshToken() async {
    final currentRefresh = _currentSession.refreshToken;
    if (currentRefresh == null) {
      await clearTokens();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': currentRefresh,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['accessToken'];
        final newRefresh = data['refreshToken'];
        
        await saveTokens(newAccess, newRefresh ?? currentRefresh);
        return true;
      }
    } catch (_) {
      // Network error during refresh, retain tokens for retry
      return false; // Typically handled by AuthBlocked + retain local db
    }

    await clearTokens();
    return false;
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['message'] is List ? errorData['message'].join(', ') : errorData['message'] ?? 'Login failed';
      }
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  Future<String?> register({
    required String email, 
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? gender,
    String? aadhaarNumber,
    String? aadhaarFrontUrl,
    String? aadhaarBackUrl,
  }) async {
    try {
      final body = {
        'email': email, 
        'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
        if (aadhaarFrontUrl != null) 'aadhaarFrontUrl': aadhaarFrontUrl,
        if (aadhaarBackUrl != null) 'aadhaarBackUrl': aadhaarBackUrl,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        return null; // null means success
      } else {
        final errorData = jsonDecode(response.body);
        // NestJS ValidationPipe sometimes returns an array of messages
        return errorData['message'] is List ? errorData['message'].join(', ') : errorData['message'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Network error. Please try again.';
    }
  }

  Future<String?> uploadFile(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        return data['url'];
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> verifyEmail(String token) async {
    final access = await getAccessToken();
    if (access == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/email/verify'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $access'},
        body: jsonEncode({'token': token}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) { return false; }
  }

  Future<bool> sendMobileOtp(String phone) async {
    final access = await getAccessToken();
    if (access == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/mobile/send-otp'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $access'},
        body: jsonEncode({'phone': phone}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) { return false; }
  }

  Future<bool> verifyMobileOtp(String phone, String code) async {
    final access = await getAccessToken();
    if (access == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/mobile/verify-otp'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $access'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) { return false; }
  }

  Future<bool> verifyIdentity(String identityReference) async {
    final access = await getAccessToken();
    if (access == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/identity/verify'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $access'},
        body: jsonEncode({'identityReference': identityReference}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) { return false; }
  }

  Future<AuthUser?> getMe() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthUser.fromJson(data);
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return getMe();
        }
      }
    } catch (_) {
      // Network error or other exception
      return null;
    }
    return null;
  }
}
