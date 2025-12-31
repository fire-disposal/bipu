class SubscriptionType {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final bool isActive;
  final Map<String, dynamic>? defaultSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubscriptionType({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.isActive,
    this.defaultSettings,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionType.fromJson(Map<String, dynamic> json) {
    return SubscriptionType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      isActive: json['is_active'] ?? true,
      defaultSettings: json['default_settings'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class UserSubscription {
  final int id;
  final int userId;
  final int subscriptionTypeId;
  final bool isEnabled;
  final Map<String, dynamic>? customSettings;
  final String? notificationTimeStart;
  final String? notificationTimeEnd;
  final String? timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.subscriptionTypeId,
    required this.isEnabled,
    this.customSettings,
    this.notificationTimeStart,
    this.notificationTimeEnd,
    this.timezone,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      subscriptionTypeId: json['subscription_type_id'],
      isEnabled: json['is_enabled'] ?? true,
      customSettings: json['custom_settings'],
      notificationTimeStart: json['notification_time_start'],
      notificationTimeEnd: json['notification_time_end'],
      timezone: json['timezone'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class UserSubscriptionResponse {
  final SubscriptionType subscriptionType;
  final UserSubscription? userSubscription;
  final bool isSubscribed;

  UserSubscriptionResponse({
    required this.subscriptionType,
    this.userSubscription,
    required this.isSubscribed,
  });

  factory UserSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionResponse(
      subscriptionType: SubscriptionType.fromJson(json['subscription_type']),
      userSubscription: json['user_subscription'] != null
          ? UserSubscription.fromJson(json['user_subscription'])
          : null,
      isSubscribed: json['is_subscribed'] ?? false,
    );
  }
}
