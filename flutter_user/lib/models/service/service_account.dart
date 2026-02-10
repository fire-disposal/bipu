class ServiceAccount {
  final int id;
  final String name; // unique id string e.g. 'weather.service'
  final String? displayName;
  final String? description;
  final String? avatarUrl;
  final bool isActive;

  ServiceAccount({
    required this.id,
    required this.name,
    this.displayName,
    this.description,
    this.avatarUrl,
    required this.isActive,
  });

  factory ServiceAccount.fromJson(Map<String, dynamic> json) {
    return ServiceAccount(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      avatarUrl:
          json['avatar_url'] ??
          json['avatarUrl'], // Handle snake_case or camelCase
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }
}
