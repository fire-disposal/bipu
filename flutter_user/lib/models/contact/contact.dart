import '../user_model.dart';

class Contact {
  final int id;
  final String contactBipupuId;
  final String? remark;
  final DateTime createdAt;
  final User?
  info; // The user profile of the contact (optional, depends on API)

  Contact({
    required this.id,
    required this.contactBipupuId,
    this.remark,
    required this.createdAt,
    this.info,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      contactBipupuId: json['contact_bipupu_id'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['created_at']),
      info: json['contact_info'] != null
          ? User.fromJson(json['contact_info'])
          : null,
    );
  }
}
