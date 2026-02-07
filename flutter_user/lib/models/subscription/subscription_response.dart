class SubscriptionTypeResponse {
  final int id;
  final String name;
  final String? description;
  final String category;
  final bool isActive;
  final Map<String, dynamic> defaultSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubscriptionTypeResponse({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.isActive,
    required this.defaultSettings,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionTypeResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionTypeResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      isActive: json['is_active'] ?? true,
      defaultSettings:
          (json['default_settings'] as Map<String, dynamic>?)
              ?.cast<String, dynamic>() ??
          {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'is_active': isActive,
    'default_settings': defaultSettings,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class UserSubscriptionModelResponse {
  final int id;
  final int userId;
  final int subscriptionTypeId;
  final bool isEnabled;
  final Map<String, dynamic> customSettings;
  final String notificationTimeStart;
  final String notificationTimeEnd;
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserSubscriptionModelResponse({
    required this.id,
    required this.userId,
    required this.subscriptionTypeId,
    required this.isEnabled,
    required this.customSettings,
    required this.notificationTimeStart,
    required this.notificationTimeEnd,
    required this.timezone,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSubscriptionModelResponse.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModelResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse(json['user_id'].toString()),
      subscriptionTypeId: json['subscription_type_id'] is int
          ? json['subscription_type_id'] as int
          : int.parse(json['subscription_type_id'].toString()),
      isEnabled: json['is_enabled'] ?? true,
      customSettings:
          (json['custom_settings'] as Map<String, dynamic>?)
              ?.cast<String, dynamic>() ??
          {},
      notificationTimeStart: json['notification_time_start'] as String,
      notificationTimeEnd: json['notification_time_end'] as String,
      timezone: json['timezone'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'subscription_type_id': subscriptionTypeId,
    'is_enabled': isEnabled,
    'custom_settings': customSettings,
    'notification_time_start': notificationTimeStart,
    'notification_time_end': notificationTimeEnd,
    'timezone': timezone,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class SubscribeResponse {
  final String message;
  final UserSubscriptionModelResponse? subscription;

  SubscribeResponse({required this.message, this.subscription});

  factory SubscribeResponse.fromJson(Map<String, dynamic> json) {
    return SubscribeResponse(
      message: json['message'] as String,
      subscription: json['subscription'] != null
          ? UserSubscriptionModelResponse.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'subscription': subscription?.toJson(),
  };
}

class MySubscriptionItem {
  final SubscriptionTypeResponse subscriptionType;
  final UserSubscriptionModelResponse? userSubscription;
  final bool isSubscribed;

  MySubscriptionItem({
    required this.subscriptionType,
    this.userSubscription,
    required this.isSubscribed,
  });

  factory MySubscriptionItem.fromJson(Map<String, dynamic> json) {
    return MySubscriptionItem(
      subscriptionType: SubscriptionTypeResponse.fromJson(
        json['subscription_type'] as Map<String, dynamic>,
      ),
      userSubscription: json['user_subscription'] != null
          ? UserSubscriptionModelResponse.fromJson(
              json['user_subscription'] as Map<String, dynamic>,
            )
          : null,
      isSubscribed: json['is_subscribed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'subscription_type': subscriptionType.toJson(),
    'user_subscription': userSubscription?.toJson(),
    'is_subscribed': isSubscribed,
  };
}
