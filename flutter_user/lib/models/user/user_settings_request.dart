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
      profileVisibility: _parseProfileVisibility(
        json['profile_visibility'] as String?,
      ),
      messageProtection: json['message_protection'] ?? true,
      cooldownEnabled: json['cooldown_enabled'] ?? true,
      cooldownDuration: json['cooldown_duration'] ?? 300,
    );
  }

  Map<String, dynamic> toJson() => {
    'profile_visibility': _profileVisibilityToString(profileVisibility),
    'message_protection': messageProtection,
    'cooldown_enabled': cooldownEnabled,
    'cooldown_duration': cooldownDuration,
  };
}

ProfileVisibility _parseProfileVisibility(String? value) {
  switch (value) {
    case 'public':
      return ProfileVisibility.public;
    case 'friends':
      return ProfileVisibility.friends;
    case 'private':
      return ProfileVisibility.private;
    default:
      return ProfileVisibility.friends;
  }
}

String _profileVisibilityToString(ProfileVisibility visibility) {
  switch (visibility) {
    case ProfileVisibility.public:
      return 'public';
    case ProfileVisibility.friends:
      return 'friends';
    case ProfileVisibility.private:
      return 'private';
  }
}

class SubscriptionSettings {
  // Add fields if needed
  SubscriptionSettings();

  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) {
    return SubscriptionSettings();
  }

  Map<String, dynamic> toJson() => {};
}

class UserSettingsUpdateRequest {
  final PrivacySettings? privacySettings;
  final SubscriptionSettings? subscriptionSettings;

  UserSettingsUpdateRequest({this.privacySettings, this.subscriptionSettings});

  factory UserSettingsUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserSettingsUpdateRequest(
      privacySettings: json['privacy_settings'] != null
          ? PrivacySettings.fromJson(
              json['privacy_settings'] as Map<String, dynamic>,
            )
          : null,
      subscriptionSettings: json['subscription_settings'] != null
          ? SubscriptionSettings.fromJson(
              json['subscription_settings'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'privacy_settings': privacySettings?.toJson(),
    'subscription_settings': subscriptionSettings?.toJson(),
  };
}

class BlockUserRequest {
  final int userId;
  final String? reason;

  BlockUserRequest({required this.userId, this.reason});

  factory BlockUserRequest.fromJson(Map<String, dynamic> json) {
    return BlockUserRequest(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse(json['user_id'].toString()),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'user_id': userId, 'reason': reason};
}

class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;

  PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  factory PasswordChangeRequest.fromJson(Map<String, dynamic> json) {
    return PasswordChangeRequest(
      currentPassword: json['current_password'] as String,
      newPassword: json['new_password'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}

class TermsAcceptanceRequest {
  final bool accepted;
  final String? ipAddress;
  final String? userAgent;

  TermsAcceptanceRequest({
    this.accepted = true,
    this.ipAddress,
    this.userAgent,
  });

  factory TermsAcceptanceRequest.fromJson(Map<String, dynamic> json) {
    return TermsAcceptanceRequest(
      accepted: json['accepted'] ?? true,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'accepted': accepted,
    'ip_address': ipAddress,
    'user_agent': userAgent,
  };
}
