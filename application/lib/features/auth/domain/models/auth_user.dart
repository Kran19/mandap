class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool emailVerified;
  final bool mobileVerified;
  final bool identityVerified;
  final String? organizationId;

  const AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.emailVerified,
    required this.mobileVerified,
    required this.identityVerified,
    this.organizationId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      mobileVerified: json['mobileVerified'] as bool? ?? false,
      identityVerified: json['identityVerified'] as bool? ?? false,
      organizationId: json['organizationId'] as String?,
    );
  }
}
