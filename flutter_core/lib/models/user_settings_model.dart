enum ProfileVisibility { public, friends, private }

class PrivacySettings {
  final ProfileVisibility profileVisibility;
  final bool messageProtection;
  final bool cooldownEnabled;
  final int cooldownDuration;

  PrivacySettings({
    this.profileVisibility = ProfileVisibility.friends,
    this.messageProtection = true,
    this.cooldownEnabled = true,
    this.cooldownDuration = 300,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['profile_visibility'],
        orElse: () => ProfileVisibility.friends,
      ),
      messageProtection: json['message_protection'] as bool? ?? true,
      cooldownEnabled: json['cooldown_enabled'] as bool? ?? true,
      cooldownDuration: json['cooldown_duration'] as int? ?? 300,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_visibility': profileVisibility.toString().split('.').last,
      'message_protection': messageProtection,
      'cooldown_enabled': cooldownEnabled,
      'cooldown_duration': cooldownDuration,
    };
  }
}

class SubscriptionSettings {
  final bool cosmicMessaging;
  final String notificationTimeStart;
  final String notificationTimeEnd;
  final String timezone;

  SubscriptionSettings({
    this.cosmicMessaging = true,
    this.notificationTimeStart = "09:00",
    this.notificationTimeEnd = "22:00",
    this.timezone = "Asia/Shanghai",
  });

  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) {
    return SubscriptionSettings(
      cosmicMessaging: json['cosmic_messaging'] as bool? ?? true,
      notificationTimeStart:
          json['notification_time_start'] as String? ?? "09:00",
      notificationTimeEnd: json['notification_time_end'] as String? ?? "22:00",
      timezone: json['timezone'] as String? ?? "Asia/Shanghai",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cosmic_messaging': cosmicMessaging,
      'notification_time_start': notificationTimeStart,
      'notification_time_end': notificationTimeEnd,
      'timezone': timezone,
    };
  }
}

class CosmicProfile {
  final String? energyType;
  final String? lifePath;
  final String? soulUrge;
  final int? destinyNumber;
  final int? personalYear;

  CosmicProfile({
    this.energyType,
    this.lifePath,
    this.soulUrge,
    this.destinyNumber,
    this.personalYear,
  });

  factory CosmicProfile.fromJson(Map<String, dynamic> json) {
    return CosmicProfile(
      energyType: json['energy_type'] as String?,
      lifePath: json['life_path'] as String?,
      soulUrge: json['soul_urge'] as String?,
      destinyNumber: json['destiny_number'] as int?,
      personalYear: json['personal_year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energy_type': energyType,
      'life_path': lifePath,
      'soul_urge': soulUrge,
      'destiny_number': destinyNumber,
      'personal_year': personalYear,
    };
  }
}

class BirthChart {
  final String? year;
  final String? month;
  final String? day;
  final String? hour;
  final String? element;
  final String? animal;

  BirthChart({
    this.year,
    this.month,
    this.day,
    this.hour,
    this.element,
    this.animal,
  });

  factory BirthChart.fromJson(Map<String, dynamic> json) {
    return BirthChart(
      year: json['year'] as String?,
      month: json['month'] as String?,
      day: json['day'] as String?,
      hour: json['hour'] as String?,
      element: json['element'] as String?,
      animal: json['animal'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'day': day,
      'hour': hour,
      'element': element,
      'animal': animal,
    };
  }
}

class UserProfile {
  final int id;
  final String email;
  final String username;
  final String? nickname;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? zodiacSign;
  final String? mbtiType;
  final BirthChart? birthChart;
  final CosmicProfile? cosmicProfile;
  final PrivacySettings privacySettings;
  final SubscriptionSettings subscriptionSettings;
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;
  final bool isActive;
  final String role;
  final DateTime? lastActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.nickname,
    this.fullName,
    this.avatarUrl,
    this.birthDate,
    this.zodiacSign,
    this.mbtiType,
    this.birthChart,
    this.cosmicProfile,
    required this.privacySettings,
    required this.subscriptionSettings,
    required this.termsAccepted,
    this.termsAcceptedAt,
    required this.isActive,
    required this.role,
    this.lastActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      zodiacSign: json['zodiac_sign'] as String?,
      mbtiType: json['mbti_type'] as String?,
      birthChart: json['birth_chart'] != null
          ? BirthChart.fromJson(json['birth_chart'])
          : null,
      cosmicProfile: json['cosmic_profile'] != null
          ? CosmicProfile.fromJson(json['cosmic_profile'])
          : null,
      privacySettings: PrivacySettings.fromJson(json['privacy_settings'] ?? {}),
      subscriptionSettings: SubscriptionSettings.fromJson(
        json['subscription_settings'] ?? {},
      ),
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      termsAcceptedAt: json['terms_accepted_at'] != null
          ? DateTime.parse(json['terms_accepted_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? 'user',
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class BlockedUser {
  final int id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      blockedAt: DateTime.parse(json['blocked_at'] as String),
    );
  }
}

