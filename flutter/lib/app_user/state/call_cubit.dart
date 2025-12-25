/// 传呼台状态管理Cubit
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/core.dart';
import 'device_control_state.dart';

/// 传呼台状态
abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class CallInitial extends CallState {
  const CallInitial();
}

/// 选择接线员状态
class CallOperatorSelection extends CallState {
  final List<OperatorInfo> operators;
  final String? selectedOperatorId;

  const CallOperatorSelection({
    required this.operators,
    this.selectedOperatorId,
  });

  @override
  List<Object?> get props => [operators, selectedOperatorId];
}

/// 消息自定义状态
class CallMessageCustomization extends CallState {
  final String? selectedOperatorId;
  final String? customMessage;
  final bool enableLightEffect;
  final bool enableVibration;
  final bool enableSpecialEffect;

  const CallMessageCustomization({
    this.selectedOperatorId,
    this.customMessage,
    this.enableLightEffect = false,
    this.enableVibration = true,
    this.enableSpecialEffect = false,
  });

  @override
  List<Object?> get props => [
    selectedOperatorId,
    customMessage,
    enableLightEffect,
    enableVibration,
    enableSpecialEffect,
  ];
}

/// 连接中状态
class CallConnecting extends CallState {
  final String? message;
  final bool isVoiceMode;

  const CallConnecting({this.message, this.isVoiceMode = false});

  @override
  List<Object?> get props => [message, isVoiceMode];
}

/// 连接成功状态
class CallSuccess extends CallState {
  final String? unlockedPartnerId;
  final String? unlockedPartnerName;

  const CallSuccess({this.unlockedPartnerId, this.unlockedPartnerName});

  @override
  List<Object?> get props => [unlockedPartnerId, unlockedPartnerName];
}

/// 图鉴状态
class CallGallery extends CallState {
  final List<PartnerInfo> partners;

  const CallGallery({required this.partners});

  @override
  List<Object?> get props => [partners];
}

/// 错误状态
class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 接线员信息
class OperatorInfo {
  final String id;
  final String name;
  final bool isOnline;
  final String? avatarUrl;

  const OperatorInfo({
    required this.id,
    required this.name,
    this.isOnline = true,
    this.avatarUrl,
  });
}

/// 搭档信息
class PartnerInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isUnlocked;
  final DateTime? unlockTime;

  const PartnerInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isUnlocked = false,
    this.unlockTime,
  });
}

/// 传呼台Cubit
class CallCubit extends Cubit<CallState> {
  final DeviceControlCubit _deviceControlCubit;

  CallCubit({required DeviceControlCubit deviceControlCubit})
    : _deviceControlCubit = deviceControlCubit,
      super(const CallInitial()) {
    _initialize();
  }

  /// 初始化传呼台
  void _initialize() {
    // 加载接线员列表
    final operators = _getOperators();
    emit(CallOperatorSelection(operators: operators));
  }

  /// 获取接线员列表
  List<OperatorInfo> _getOperators() {
    return [
      const OperatorInfo(id: 'op1', name: '接线员1', isOnline: true),
      const OperatorInfo(id: 'op2', name: '接线员2', isOnline: true),
      const OperatorInfo(id: 'op3', name: '接线员3', isOnline: false),
      const OperatorInfo(id: 'op4', name: '接线员4', isOnline: true),
      const OperatorInfo(id: 'op5', name: '接线员5', isOnline: true),
    ];
  }

  /// 选择接线员
  void selectOperator(String operatorId) {
    if (state is! CallOperatorSelection) return;

    final currentState = state as CallOperatorSelection;
    emit(
      CallOperatorSelection(
        operators: currentState.operators,
        selectedOperatorId: operatorId,
      ),
    );

    // 自动跳转到消息自定义页面
    Future.delayed(const Duration(milliseconds: 300), () {
      emit(CallMessageCustomization(selectedOperatorId: operatorId));
    });
  }

  /// 更新自定义消息
  void updateCustomMessage(String message) {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    emit(
      CallMessageCustomization(
        selectedOperatorId: currentState.selectedOperatorId,
        customMessage: message,
        enableLightEffect: currentState.enableLightEffect,
        enableVibration: currentState.enableVibration,
        enableSpecialEffect: currentState.enableSpecialEffect,
      ),
    );
  }

  /// 切换光效
  void toggleLightEffect() {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    emit(
      CallMessageCustomization(
        selectedOperatorId: currentState.selectedOperatorId,
        customMessage: currentState.customMessage,
        enableLightEffect: !currentState.enableLightEffect,
        enableVibration: currentState.enableVibration,
        enableSpecialEffect: currentState.enableSpecialEffect,
      ),
    );
  }

  /// 切换震动
  void toggleVibration() {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    emit(
      CallMessageCustomization(
        selectedOperatorId: currentState.selectedOperatorId,
        customMessage: currentState.customMessage,
        enableLightEffect: currentState.enableLightEffect,
        enableVibration: !currentState.enableVibration,
        enableSpecialEffect: currentState.enableSpecialEffect,
      ),
    );
  }

  /// 切换特效
  void toggleSpecialEffect() {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    emit(
      CallMessageCustomization(
        selectedOperatorId: currentState.selectedOperatorId,
        customMessage: currentState.customMessage,
        enableLightEffect: currentState.enableLightEffect,
        enableVibration: currentState.enableVibration,
        enableSpecialEffect: !currentState.enableSpecialEffect,
      ),
    );
  }

  /// 发送消息
  Future<void> sendMessage() async {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    final message = currentState.customMessage ?? '默认消息';

    if (!_deviceControlCubit.isConnected) {
      emit(const CallError('请先连接设备'));
      return;
    }

    emit(const CallConnecting(message: '正在发送消息...'));

    try {
      // 根据设置发送不同类型的消息
      if (currentState.enableLightEffect && currentState.enableVibration) {
        await _deviceControlCubit.sendRgbSequence(
          colors: [RgbColor.colorBlue, RgbColor.colorGreen],
          text: message,
          vibration: VibrationPattern.medium,
          duration: 3000,
        );
      } else if (currentState.enableLightEffect) {
        await _deviceControlCubit.sendRgbSequence(
          colors: [RgbColor.colorBlue],
          text: message,
          vibration: VibrationPattern.none,
          duration: 2000,
        );
      } else if (currentState.enableVibration) {
        await _deviceControlCubit.sendSimpleNotification(
          text: message,
          vibration: VibrationPattern.medium,
        );
      } else {
        await _deviceControlCubit.sendSimpleNotification(text: message);
      }

      // 模拟连接成功
      await Future.delayed(const Duration(seconds: 2));
      emit(
        const CallSuccess(
          unlockedPartnerId: 'partner_001',
          unlockedPartnerName: '新搭档',
        ),
      );
    } catch (e) {
      Logger.error('发送消息失败: $e');
      emit(CallError('发送消息失败: $e'));
    }
  }

  /// 开始语音输入
  void startVoiceInput() {
    if (state is! CallMessageCustomization) return;

    final currentState = state as CallMessageCustomization;
    emit(CallConnecting(message: '正在听取语音...', isVoiceMode: true));

    // 模拟语音识别
    Future.delayed(const Duration(seconds: 3), () {
      emit(
        CallMessageCustomization(
          selectedOperatorId: currentState.selectedOperatorId,
          customMessage: '语音识别结果：你好，这是一条语音消息',
          enableLightEffect: currentState.enableLightEffect,
          enableVibration: currentState.enableVibration,
          enableSpecialEffect: currentState.enableSpecialEffect,
        ),
      );
    });
  }

  /// 查看图鉴
  void viewGallery() {
    final partners = _getPartners();
    emit(CallGallery(partners: partners));
  }

  /// 获取搭档列表
  List<PartnerInfo> _getPartners() {
    return [
      PartnerInfo(
        id: 'partner_001',
        name: '新搭档',
        isUnlocked: true,
        unlockTime: DateTime.now(),
      ),
      PartnerInfo(
        id: 'partner_002',
        name: '老朋友',
        isUnlocked: true,
        unlockTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PartnerInfo(id: 'partner_003', name: '神秘人', isUnlocked: false),
      PartnerInfo(
        id: 'partner_004',
        name: '小伙伴',
        isUnlocked: true,
        unlockTime: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// 返回初始状态
  void backToInitial() {
    _initialize();
  }

  /// 返回消息自定义
  void backToMessageCustomization() {
    if (state is CallOperatorSelection) {
      final currentState = state as CallOperatorSelection;
      emit(
        CallMessageCustomization(
          selectedOperatorId: currentState.selectedOperatorId,
        ),
      );
    } else {
      _initialize();
    }
  }
}
