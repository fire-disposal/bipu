/// 个人中心状态管理Cubit
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/core.dart';
import 'user_data_cubit.dart';

/// 个人中心状态
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// 加载中状态
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// 数据加载完成
class ProfileLoaded extends ProfileState {
  final UserProfile userProfile;
  final List<ProfileMenuItem> menuItems;
  final List<DeviceInfo> userDevices;
  final bool isEditing;

  const ProfileLoaded({
    required this.userProfile,
    required this.menuItems,
    required this.userDevices,
    this.isEditing = false,
  });

  @override
  List<Object?> get props => [userProfile, menuItems, userDevices, isEditing];
}

/// 编辑状态
class ProfileEditing extends ProfileState {
  final UserProfile originalProfile;
  final UserProfile editedProfile;
  final bool hasChanges;

  const ProfileEditing({
    required this.originalProfile,
    required this.editedProfile,
    this.hasChanges = false,
  });

  @override
  List<Object?> get props => [originalProfile, editedProfile, hasChanges];
}

/// 错误状态
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 用户资料数据模型
class UserProfile {
  final String id;
  final String username;
  final String nickname;
  final String email;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? constellation;
  final String? mbti;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.nickname,
    required this.email,
    this.avatarUrl,
    this.birthDate,
    this.constellation,
    this.mbti,
    required this.createdAt,
    this.lastLoginAt,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? nickname,
    String? email,
    String? avatarUrl,
    DateTime? birthDate,
    String? constellation,
    String? mbti,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      constellation: constellation ?? this.constellation,
      mbti: mbti ?? this.mbti,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// 个人中心菜单项数据模型
class ProfileMenuItem {
  final String id;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool hasNotification;
  final int? notificationCount;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle,
    this.hasNotification = false,
    this.notificationCount,
    this.onTap,
  });
}

/// 设备信息数据模型
class DeviceInfo {
  final String id;
  final String name;
  final String? deviceType;
  final bool isConnected;
  final DateTime? lastConnectedTime;
  final int? batteryLevel;

  const DeviceInfo({
    required this.id,
    required this.name,
    this.deviceType,
    this.isConnected = false,
    this.lastConnectedTime,
    this.batteryLevel,
  });
}

/// 个人中心Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final AuthService _authService;
  final UserDataCubit _userDataCubit;

  ProfileCubit({
    required AuthService authService,
    required UserDataCubit userDataCubit,
  }) : _authService = authService,
       _userDataCubit = userDataCubit,
       super(const ProfileInitial()) {
    _initialize();
  }

  /// 初始化个人中心
  Future<void> _initialize() async {
    emit(const ProfileLoading());

    try {
      // 获取用户信息
      final userProfile = await _getUserProfile();

      // 获取菜单项
      final menuItems = _getMenuItems();

      // 获取用户设备
      final userDevices = await _getUserDevices();

      emit(
        ProfileLoaded(
          userProfile: userProfile,
          menuItems: menuItems,
          userDevices: userDevices,
        ),
      );
    } catch (e) {
      Logger.error('个人中心初始化失败: $e');
      emit(ProfileError('加载数据失败: $e'));
    }
  }

  /// 获取用户资料
  Future<UserProfile> _getUserProfile() async {
    try {
      // 尝试从API获取用户信息
      final response = await _authService.getCurrentUser();
      if (response != null) {
        return UserProfile(
          id: response['id']?.toString() ?? 'unknown',
          username: response['username']?.toString() ?? 'unknown',
          nickname: response['nickname']?.toString() ?? '用户',
          email: response['email']?.toString() ?? '',
          avatarUrl: response['avatar_url']?.toString(),
          birthDate: response['birth_date'] != null
              ? DateTime.parse(response['birth_date'])
              : null,
          constellation: _calculateConstellation(response['birth_date']),
          mbti: response['mbti']?.toString(),
          createdAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : DateTime.now(),
          lastLoginAt: response['last_login_at'] != null
              ? DateTime.parse(response['last_login_at'])
              : null,
        );
      }
    } catch (e) {
      Logger.error('获取用户资料失败: $e');
    }

    // 返回默认用户资料
    return UserProfile(
      id: 'user_001',
      username: 'testuser',
      nickname: '测试用户',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );
  }

  /// 计算星座
  String? _calculateConstellation(dynamic birthDateStr) {
    if (birthDateStr == null) return null;

    try {
      final birthDate = DateTime.parse(birthDateStr.toString());
      final month = birthDate.month;
      final day = birthDate.day;

      if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return '白羊座';
      if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return '金牛座';
      if ((month == 5 && day >= 21) || (month == 6 && day <= 21)) return '双子座';
      if ((month == 6 && day >= 22) || (month == 7 && day <= 22)) return '巨蟹座';
      if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return '狮子座';
      if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return '处女座';
      if ((month == 9 && day >= 23) || (month == 10 && day <= 23)) return '天秤座';
      if ((month == 10 && day >= 24) || (month == 11 && day <= 22)) {
        return '天蝎座';
      }
      if ((month == 11 && day >= 23) || (month == 12 && day <= 21)) {
        return '射手座';
      }
      if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return '摩羯座';
      if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return '水瓶座';
      if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return '双鱼座';
    } catch (e) {
      Logger.error('计算星座失败: $e');
    }

    return null;
  }

  /// 获取菜单项
  List<ProfileMenuItem> _getMenuItems() {
    return [
      ProfileMenuItem(
        id: 'profile',
        icon: Icons.person_outline,
        title: '个人资料',
        subtitle: '查看和编辑个人信息',
        onTap: () => _handleProfileEdit(),
      ),
      ProfileMenuItem(
        id: 'devices',
        icon: Icons.devices_other,
        title: 'PuPu机',
        subtitle: '管理您的设备',
        hasNotification: true,
        notificationCount: 1,
        onTap: () => _handleDeviceManagement(),
      ),
      ProfileMenuItem(
        id: 'security',
        icon: Icons.security,
        title: '账号与安全',
        subtitle: '密码、隐私设置',
        onTap: () => _handleSecuritySettings(),
      ),
      ProfileMenuItem(
        id: 'settings',
        icon: Icons.settings,
        title: '设置',
        subtitle: '应用设置',
        onTap: () => _handleAppSettings(),
      ),
    ];
  }

  /// 获取用户设备
  Future<List<DeviceInfo>> _getUserDevices() async {
    try {
      // 从用户数据Cubit获取设备信息
      final userDataState = _userDataCubit.state;
      if (userDataState is UserDataLoaded) {
        return userDataState.connectedDevices.map((device) {
          return DeviceInfo(
            id: device.id,
            name: device.name,
            deviceType: 'PuPu机',
            isConnected: device.isConnected,
            lastConnectedTime: device.lastConnectedTime,
            batteryLevel: device.batteryLevel,
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取用户设备失败: $e');
    }

    // 返回默认设备信息
    return [
      const DeviceInfo(
        id: 'device_001',
        name: 'PuPu机-001',
        deviceType: 'PuPu机',
        isConnected: true,
        batteryLevel: 85,
      ),
    ];
  }

  /// 处理个人资料编辑
  void _handleProfileEdit() {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    emit(
      ProfileEditing(
        originalProfile: currentState.userProfile,
        editedProfile: currentState.userProfile,
        hasChanges: false,
      ),
    );
  }

  /// 处理设备管理
  void _handleDeviceManagement() {
    Logger.info('打开设备管理页面');
    // 这里可以导航到设备管理页面
  }

  /// 处理安全设置
  void _handleSecuritySettings() {
    Logger.info('打开安全设置页面');
    // 这里可以导航到安全设置页面
  }

  /// 处理应用设置
  void _handleAppSettings() {
    Logger.info('打开应用设置页面');
    // 这里可以导航到应用设置页面
  }

  /// 更新编辑中的用户资料
  void updateEditingProfile(UserProfile updatedProfile) {
    if (state is! ProfileEditing) return;

    final currentState = state as ProfileEditing;
    final hasChanges = updatedProfile != currentState.originalProfile;

    emit(
      ProfileEditing(
        originalProfile: currentState.originalProfile,
        editedProfile: updatedProfile,
        hasChanges: hasChanges,
      ),
    );
  }

  /// 保存编辑的用户资料
  Future<void> saveEditedProfile() async {
    if (state is! ProfileEditing) return;

    final currentState = state as ProfileEditing;
    if (!currentState.hasChanges) {
      cancelEditing();
      return;
    }

    emit(const ProfileLoading());

    try {
      // 这里可以调用API保存用户资料
      Logger.info('保存用户资料: ${currentState.editedProfile.nickname}');

      // 更新用户数据Cubit
      final userDataState = _userDataCubit.state;
      if (userDataState is UserDataLoaded) {
        // 这里可以调用用户数据Cubit的更新方法
        // _userDataCubit.updateUserProfile(currentState.editedProfile);
      }

      // 重新加载数据
      await _initialize();
    } catch (e) {
      Logger.error('保存用户资料失败: $e');
      emit(ProfileError('保存失败: $e'));
    }
  }

  /// 取消编辑
  void cancelEditing() {
    if (state is! ProfileEditing) return;

    _initialize();
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _initialize();
  }

  /// 处理菜单项点击
  void handleMenuItemClick(String menuId) {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    final menuItem = currentState.menuItems.firstWhere(
      (item) => item.id == menuId,
      orElse: () => currentState.menuItems.first,
    );

    if (menuItem.onTap != null) {
      menuItem.onTap!();
    }
  }

  /// 用户注销
  Future<void> logout() async {
    try {
      await _authService.logout();
      Logger.info('用户注销成功');
    } catch (e) {
      Logger.error('用户注销失败: $e');
      emit(ProfileError('注销失败: $e'));
    }
  }

  /// 获取用户ID
  String getUserId() {
    if (state is ProfileLoaded) {
      return (state as ProfileLoaded).userProfile.id;
    }
    return 'unknown';
  }

  /// 获取用户昵称
  String getUserNickname() {
    if (state is ProfileLoaded) {
      return (state as ProfileLoaded).userProfile.nickname;
    }
    return '用户';
  }
}
