class AdminLog {
  final int id;
  final int adminId;
  final String action;
  final Map<String, dynamic>? detail;
  final DateTime timestamp;

  AdminLog({
    required this.id,
    required this.adminId,
    required this.action,
    this.detail,
    required this.timestamp,
  });

  factory AdminLog.fromJson(Map<String, dynamic> json) {
    return AdminLog(
      id: json['id'] as int,
      adminId: json['admin_id'] as int,
      action: json['action'] as String,
      detail: json['detail'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
