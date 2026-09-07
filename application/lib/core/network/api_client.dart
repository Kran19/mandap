import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/api_exceptions.dart';
import '../../features/auth/infrastructure/auth_repository.dart';

class ApiClient {
  final String baseUrl;
  final AuthTokenProvider tokenProvider;
  final http.Client _client = http.Client();

  // Refresh lock mechanism (Single-flight)
  Completer<bool>? _refreshCompleter;

  ApiClient({required this.baseUrl, required this.tokenProvider});

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await tokenProvider.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    return _authenticatedRequest(
      () async => _client.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(requireAuth: requireAuth)),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body, bool requireAuth = true}) async {
    return _authenticatedRequest(
      () async => _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body, bool requireAuth = true}) async {
    return _authenticatedRequest(
      () async => _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function() requestFunc, {
    required bool requireAuth,
  }) async {
    try {
      // If a refresh is already in progress, wait for it before proceeding
      if (_refreshCompleter != null) {
        final success = await _refreshCompleter!.future;
        if (!success) {
          throw AuthenticationExpiredException('Refresh failed, session blocked');
        }
      }

      http.Response response = await requestFunc();

      if (response.statusCode == 401 && requireAuth) {
        // Attempt single-flight refresh
        final refreshSuccess = await _handleTokenRefresh();
        if (refreshSuccess) {
          // Retry original request
          response = await requestFunc();
        } else {
          throw AuthenticationExpiredException('Session expired and refresh failed');
        }
      }

      _handleErrors(response);
      return response;
    } on http.ClientException {
      throw NetworkUnavailableException('Failed to connect to the server');
    } on TimeoutException {
      throw RequestTimeoutException();
    }
  }

  Future<bool> _handleTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    bool success = false;

    try {
      success = await tokenProvider.refreshToken();
    } finally {
      _refreshCompleter!.complete(success);
      _refreshCompleter = null;
    }

    return success;
  }

  void _handleErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final String message = _extractErrorMessage(response.body);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        throw AuthenticationExpiredException(message);
      case 403:
        if (message.toLowerCase().contains('quota') || message.toLowerCase().contains('limit')) {
          throw QuotaExceededException(message);
        }
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 429:
        throw RateLimitedException(message);
      case 500:
        throw ServerErrorException(message);
      default:
        throw ApiException('HTTP Error ${response.statusCode}: $message', statusCode: response.statusCode);
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json.containsKey('message')) {
        final msg = json['message'];
        if (msg is List) {
          return msg.join(', ');
        }
        return msg.toString();
      }
    } catch (_) {}
    return body.isNotEmpty ? body : 'Unknown error';
  }
}
