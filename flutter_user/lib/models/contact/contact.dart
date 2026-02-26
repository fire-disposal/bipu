import 'package:bipupu/models/user/user_response.dart';

class Contact {
  final int id;
  final String contactBipupuId;
  final String? remark;
  final DateTime createdAt;
  final UserResponse?
  info; // The user profile of the contact (optional, depends on API)

  Contact({
    this.id = 0,
    required this.contactBipupuId,
    this.remark,
    DateTime? createdAt,
    this.info,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Contact.fromJson(Map<String, dynamic> json) {
    // 解析日期
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Contact(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      contactBipupuId: json['contact_bipupu_id'] ?? '',
      remark: json['remark'],
      createdAt: parseDateTime(json['created_at']),
      info: json['contact_info'] != null
          ? UserResponse.fromJson(json['contact_info'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contact_bipupu_id': contactBipupuId,
    'remark': remark,
    'created_at': createdAt.toIso8601String(),
    'contact_info': info?.toJson(),
  };
}
