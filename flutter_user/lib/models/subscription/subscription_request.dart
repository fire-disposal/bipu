class SubscribeRequest {
  final bool isEnabled;
  final Map<String, dynamic>? customSettings;
  final String? notificationTimeStart;
  final String? notificationTimeEnd;
  final String? timezone;

  SubscribeRequest({
    this.isEnabled = true,
    this.customSettings,
    this.notificationTimeStart = "09:00",
    this.notificationTimeEnd = "22:00",
    this.timezone = "Asia/Shanghai",
  });

  factory SubscribeRequest.fromJson(Map<String, dynamic> json) {
    return SubscribeRequest(
      isEnabled: json['is_enabled'] ?? true,
      customSettings: (json['custom_settings'] as Map<String, dynamic>?)
          ?.cast<String, dynamic>(),
      notificationTimeStart: json['notification_time_start'] ?? "09:00",
      notificationTimeEnd: json['notification_time_end'] ?? "22:00",
      timezone: json['timezone'] ?? "Asia/Shanghai",
    );
  }

  Map<String, dynamic> toJson() => {
    'is_enabled': isEnabled,
    'custom_settings': customSettings,
    'notification_time_start': notificationTimeStart,
    'notification_time_end': notificationTimeEnd,
    'timezone': timezone,
  };
}
