import 'package:flutter_core/models/user_model.dart';

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

// OpenAPI: SubscriptionTypeResponse
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
    this.isActive = true,
    this.defaultSettings = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionTypeResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionTypeResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      isActive: json['is_active'] as bool? ?? true,
      defaultSettings:
          (json['default_settings'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

// OpenAPI: SubscriptionTypeDetailResponse
class SubscriptionTypeDetailResponse {
  final int id;
  final String name;
  final String? description;
  final String category;
  final bool isActive;
  final Map<String, dynamic> defaultSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int subscriberCount;
  final int activeSubscriberCount;

  SubscriptionTypeDetailResponse({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.isActive,
    required this.defaultSettings,
    required this.createdAt,
    this.updatedAt,
    required this.subscriberCount,
    required this.activeSubscriberCount,
  });

  factory SubscriptionTypeDetailResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionTypeDetailResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      isActive: json['is_active'] as bool,
      defaultSettings:
          (json['default_settings'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      subscriberCount: json['subscriber_count'] as int,
      activeSubscriberCount: json['active_subscriber_count'] as int,
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

// OpenAPI: UserSubscriptionUpdate (request body)
class UserSubscriptionUpdate {
  final bool isEnabled;
  final Map<String, dynamic> customSettings;
  final String notificationTimeStart;
  final String notificationTimeEnd;
  final String timezone;

  UserSubscriptionUpdate({
    this.isEnabled = true,
    this.customSettings = const {},
    this.notificationTimeStart = '09:00',
    this.notificationTimeEnd = '22:00',
    this.timezone = 'Asia/Shanghai',
  });

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'custom_settings': customSettings,
      'notification_time_start': notificationTimeStart,
      'notification_time_end': notificationTimeEnd,
      'timezone': timezone,
    };
  }
}

// OpenAPI: UserSubscriptionModelResponse
class UserSubscriptionModelResponse {
  final bool isEnabled;
  final Map<String, dynamic> customSettings;
  final String notificationTimeStart;
  final String notificationTimeEnd;
  final String timezone;
  final int id;
  final int userId;
  final int subscriptionTypeId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserSubscriptionModelResponse({
    this.isEnabled = true,
    this.customSettings = const {},
    this.notificationTimeStart = '09:00',
    this.notificationTimeEnd = '22:00',
    this.timezone = 'Asia/Shanghai',
    required this.id,
    required this.userId,
    required this.subscriptionTypeId,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSubscriptionModelResponse.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModelResponse(
      isEnabled: json['is_enabled'] as bool? ?? true,
      customSettings:
          (json['custom_settings'] as Map<String, dynamic>?) ?? const {},
      notificationTimeStart:
          json['notification_time_start'] as String? ?? '09:00',
      notificationTimeEnd: json['notification_time_end'] as String? ?? '22:00',
      timezone: json['timezone'] as String? ?? 'Asia/Shanghai',
      id: json['id'] as int,
      userId: json['user_id'] as int,
      subscriptionTypeId: json['subscription_type_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

// OpenAPI: SubscribeRequest (request body)
class SubscribeRequest {
  final bool isEnabled;
  final Map<String, dynamic>? customSettings;
  final String? notificationTimeStart;
  final String? notificationTimeEnd;
  final String? timezone;

  SubscribeRequest({
    this.isEnabled = true,
    this.customSettings,
    this.notificationTimeStart = '09:00',
    this.notificationTimeEnd = '22:00',
    this.timezone = 'Asia/Shanghai',
  });

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      if (customSettings != null) 'custom_settings': customSettings,
      if (notificationTimeStart != null)
        'notification_time_start': notificationTimeStart,
      if (notificationTimeEnd != null)
        'notification_time_end': notificationTimeEnd,
      if (timezone != null) 'timezone': timezone,
    };
  }
}

// OpenAPI: SubscribeResponse
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
}

// OpenAPI: MySubscriptionItem
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
}

// OpenAPI: SubscriberItem
class SubscriberItem {
  final User user;
  final UserSubscriptionModelResponse subscription;
  final DateTime subscribedAt;

  SubscriberItem({
    required this.user,
    required this.subscription,
    required this.subscribedAt,
  });

  factory SubscriberItem.fromJson(Map<String, dynamic> json) {
    return SubscriberItem(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      subscription: UserSubscriptionModelResponse.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
      subscribedAt: DateTime.parse(json['subscribed_at'] as String),
    );
  }
}

// OpenAPI: SubscriptionCountResponse
class SubscriptionCountResponse {
  final int subscriptionTypeId;
  final String subscriptionTypeName;
  final int totalSubscribers;
  final int activeSubscribers;
  final int inactiveSubscribers;

  SubscriptionCountResponse({
    required this.subscriptionTypeId,
    required this.subscriptionTypeName,
    required this.totalSubscribers,
    required this.activeSubscribers,
    required this.inactiveSubscribers,
  });

  factory SubscriptionCountResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionCountResponse(
      subscriptionTypeId: json['subscription_type_id'] as int,
      subscriptionTypeName: json['subscription_type_name'] as String,
      totalSubscribers: json['total_subscribers'] as int,
      activeSubscribers: json['active_subscribers'] as int,
      inactiveSubscribers: json['inactive_subscribers'] as int,
    );
  }
}

// OpenAPI: SubscriptionStatsSummary
class SubscriptionStatsSummary {
  final int total;
  final int active;
  final int inactive;

  SubscriptionStatsSummary({
    required this.total,
    required this.active,
    required this.inactive,
  });

  factory SubscriptionStatsSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatsSummary(
      total: json['total'] as int,
      active: json['active'] as int,
      inactive: json['inactive'] as int,
    );
  }
}

// OpenAPI: PopularSubscriptionItem
class PopularSubscriptionItem {
  final int id;
  final String name;
  final int subscriberCount;

  PopularSubscriptionItem({
    required this.id,
    required this.name,
    required this.subscriberCount,
  });

  factory PopularSubscriptionItem.fromJson(Map<String, dynamic> json) {
    return PopularSubscriptionItem(
      id: json['id'] as int,
      name: json['name'] as String,
      subscriberCount: json['subscriber_count'] as int,
    );
  }
}

// OpenAPI: SubscriptionOverviewResponse
class SubscriptionOverviewResponse {
  final SubscriptionStatsSummary subscriptionTypes;
  final SubscriptionStatsSummary userSubscriptions;
  final Map<String, int> byCategory;
  final List<PopularSubscriptionItem> popularSubscriptions;

  SubscriptionOverviewResponse({
    required this.subscriptionTypes,
    required this.userSubscriptions,
    required this.byCategory,
    required this.popularSubscriptions,
  });

  factory SubscriptionOverviewResponse.fromJson(Map<String, dynamic> json) {
    final byCategoryMap = (json['by_category'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
    return SubscriptionOverviewResponse(
      subscriptionTypes: SubscriptionStatsSummary.fromJson(
        json['subscription_types'] as Map<String, dynamic>,
      ),
      userSubscriptions: SubscriptionStatsSummary.fromJson(
        json['user_subscriptions'] as Map<String, dynamic>,
      ),
      byCategory: byCategoryMap,
      popularSubscriptions: (json['popular_subscriptions'] as List)
          .map(
            (e) => PopularSubscriptionItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
