class Organization {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String role; // OWNER, EDITOR, VIEWER

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.role,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      status: json['status'],
      // Assuming the API returns the user's role in the organization in the payload, e.g. via members or direct mapped property.
      // E.g., `role: json['role'] ?? 'VIEWER'`
      role: json['role'] ?? 'VIEWER', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'status': status,
      'role': role,
    };
  }
}
