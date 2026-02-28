import 'package:hive_flutter/hive_flutter.dart';
import '../models/operator_model.dart';
import 'package:collection/collection.dart';

/// 接线员管理服务
/// 负责操作员人格的加载、解锁状态追踪和本地持久化（使用 Hive）
class OperatorService {
  static const String _boxName = 'operator_unlocks';
  static const String _firstLaunchKey = 'first_launch_completed';

  late Box<dynamic> _box;
  bool _initialized = false;

  /// 所有可用的操作员
  late List<OperatorPersonality> _allOperators;

  /// 是否已完成首次启动
  bool _firstLaunchCompleted = false;

  OperatorService() {
    _allOperators = List.from(OperatorFactory.defaultOperators);
  }

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) return;

    // 初始化 Hive
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    // 加载解锁状态
    _loadUnlockedOperators();

    // 检查是否首次启动
    _firstLaunchCompleted = _box.get(_firstLaunchKey, defaultValue: false);

    _initialized = true;
  }

  /// 从 Hive 加载已解锁的操作员
  void _loadUnlockedOperators() {
    for (var i = 0; i < _allOperators.length; i++) {
      final op = _allOperators[i];
      final unlockData = _box.get('unlock_${op.id}');

      if (unlockData != null && unlockData is Map) {
        final isUnlocked = unlockData['unlocked'] ?? false;
        final unlockedAtMillis = unlockData['unlocked_at'];
        final conversationCount = unlockData['conversation_count'] ?? 0;

        _allOperators[i] = op.copyWith(
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAtMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(unlockedAtMillis)
              : null,
          conversationCount: conversationCount,
        );
      }
    }
  }

  /// 检查是否是首次启动
  bool isFirstLaunch() {
    return !_firstLaunchCompleted;
  }

  /// 标记首次启动已完成
  Future<void> markFirstLaunchCompleted() async {
    _firstLaunchCompleted = true;
    await _box.put(_firstLaunchKey, true);
  }

  /// 解锁操作员
  Future<bool> unlockOperator(String operatorId) async {
    final operator = getOperatorById(operatorId);
    if (operator == null || operator.isUnlocked) {
      return false;
    }

    // 保存到 Hive
    await _box.put('unlock_$operatorId', {
      'unlocked': true,
      'unlocked_at': DateTime.now().millisecondsSinceEpoch,
      'conversation_count': 0,
    });

    // 更新内存中的操作员状态
    final index = _allOperators.indexWhere((op) => op.id == operatorId);
    if (index != -1) {
      _allOperators[index] = _allOperators[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
    }

    return true;
  }

  /// 增加操作员的对话次数
  Future<void> incrementConversationCount(String operatorId) async {
    final unlockData = _box.get('unlock_$operatorId') ?? {};
    final currentCount = unlockData['conversation_count'] ?? 0;

    await _box.put('unlock_$operatorId', {
      ...unlockData,
      'conversation_count': currentCount + 1,
    });

    // 更新内存中的操作员状态
    final index = _allOperators.indexWhere((op) => op.id == operatorId);
    if (index != -1) {
      _allOperators[index] = _allOperators[index].copyWith(
        conversationCount: currentCount + 1,
      );
    }
  }

  /// 获取所有操作员
  List<OperatorPersonality> getAllOperators() {
    return List.from(_allOperators);
  }

  /// 获取所有已解锁的操作员
  List<OperatorPersonality> getUnlockedOperators() {
    return _allOperators.where((op) => op.isUnlocked).toList();
  }

  /// 获取所有未解锁的操作员
  List<OperatorPersonality> getLockedOperators() {
    return _allOperators.where((op) => !op.isUnlocked).toList();
  }

  /// 根据 ID 获取操作员
  OperatorPersonality? getOperatorById(String id) {
    return _allOperators.firstWhereOrNull((op) => op.id == id);
  }

  /// 获取随机操作员（优先已解锁的操作员）
  OperatorPersonality getRandomOperator() {
    final unlockedOperators = getUnlockedOperators();

    // 如果有已解锁的操作员，从已解锁中选
    if (unlockedOperators.isNotEmpty) {
      final random =
          DateTime.now().millisecondsSinceEpoch % unlockedOperators.length;
      return unlockedOperators[random];
    }

    // 否则随机选择任意操作员
    final random = DateTime.now().millisecondsSinceEpoch % _allOperators.length;
    return _allOperators[random];
  }

  /// 检查操作员是否已解锁
  bool isOperatorUnlocked(String operatorId) {
    final operator = getOperatorById(operatorId);
    return operator?.isUnlocked ?? false;
  }

  /// 获取已解锁的操作员数量
  int getUnlockedCount() {
    return _allOperators.where((op) => op.isUnlocked).length;
  }

  /// 清空所有解锁记录（用于测试）
  Future<void> clearAllUnlocks() async {
    await _box.clear();
    _firstLaunchCompleted = false;

    // 重置所有操作员状态
    for (var i = 0; i < _allOperators.length; i++) {
      _allOperators[i] = _allOperators[i].copyWith(
        isUnlocked: false,
        unlockedAt: null,
        conversationCount: 0,
      );
    }
  }

  /// 重置单个操作员的解锁状态
  Future<void> resetOperator(String operatorId) async {
    await _box.delete('unlock_$operatorId');

    // 更新内存状态
    final index = _allOperators.indexWhere((op) => op.id == operatorId);
    if (index != -1) {
      _allOperators[index] = _allOperators[index].copyWith(
        isUnlocked: false,
        unlockedAt: null,
        conversationCount: 0,
      );
    }
  }

  /// 获取操作员解锁数据
  Map<String, dynamic>? getOperatorUnlockData(String operatorId) {
    return _box.get('unlock_$operatorId');
  }

  /// 释放资源
  Future<void> dispose() async {
    await _box.close();
  }
}
