class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkUnavailableException extends ApiException {
  NetworkUnavailableException([String message = 'Network is unavailable']) : super(message);
}

class RequestTimeoutException extends ApiException {
  RequestTimeoutException([String message = 'Request timed out']) : super(message);
}

class AuthenticationExpiredException extends ApiException {
  AuthenticationExpiredException([String message = 'Authentication expired']) : super(message, statusCode: 401);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Forbidden']) : super(message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Resource not found']) : super(message, statusCode: 404);
}

class ValidationException extends ApiException {
  ValidationException([String message = 'Validation failed']) : super(message, statusCode: 400);
}

class ConflictException extends ApiException {
  ConflictException([String message = 'Version conflict (Optimistic lock failed)']) : super(message, statusCode: 409);
}

class QuotaExceededException extends ApiException {
  QuotaExceededException([String message = 'Entitlement quota exceeded']) : super(message, statusCode: 403);
}

class ServerErrorException extends ApiException {
  ServerErrorException([String message = 'Internal server error']) : super(message, statusCode: 500);
}

class RateLimitedException extends ApiException {
  RateLimitedException([String message = 'Too many requests, please slow down']) : super(message, statusCode: 429);
}

class SerializationException extends ApiException {
  SerializationException([String message = 'Data serialization failed']) : super(message);
}

class UnsupportedLayoutSchemaException extends ApiException {
  UnsupportedLayoutSchemaException([String message = 'Unsupported layout schema version']) : super(message);
}
