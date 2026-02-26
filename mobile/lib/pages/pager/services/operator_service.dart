import 'package:shared_preferences/shared_preferences.dart';
import '../models/operator_model.dart';
import 'package:collection/collection.dart';

/// 接线员管理服务
/// 负责操作员人格的加载、解锁状态追踪和本地持久化
class OperatorService {
  static const String _unlockedOperatorsKey = 'pager_unlocked_operators';
  static const String _operatorConversationCountKey =
      'pager_operator_conversation_count_';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 所有可用的操作员
  late List<OperatorPersonality> _allOperators;

  /// 已解锁的操作员ID集合
  late Set<String> _unlockedOperatorIds;

  OperatorService() {
    _allOperators = List.from(OperatorFactory.defaultOperators);
  }

  /// 初始化服务
  Future<void> init() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _loadUnlockedOperators();
    _initialized = true;
  }

  /// 从本地存储加载已解锁的操作员
  void _loadUnlockedOperators() {
    final unlockedJson = _prefs.getStringList(_unlockedOperatorsKey) ?? [];
    _unlockedOperatorIds = unlockedJson.toSet();

    // 更新操作员的解锁状态
    for (var i = 0; i < _allOperators.length; i++) {
      final op = _allOperators[i];
      if (_unlockedOperatorIds.contains(op.id)) {
        final conversationCount =
            _prefs.getInt('$_operatorConversationCountKey${op.id}') ?? 0;
        _allOperators[i] = op.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.fromMillisecondsSinceEpoch(
            _prefs.getInt(
                  '${_operatorConversationCountKey}${op.id}_unlock_time',
                ) ??
                0,
          ),
          conversationCount: conversationCount,
        );
      }
    }
  }

  /// 解锁操作员
  Future<bool> unlockOperator(String operatorId) async {
    final operator = getOperatorById(operatorId);
    if (operator == null || operator.isUnlocked) {
      return false;
    }

    _unlockedOperatorIds.add(operatorId);

    // 保存到本地存储
    await _prefs.setStringList(
      _unlockedOperatorsKey,
      _unlockedOperatorIds.toList(),
    );

    // 保存解锁时间
    await _prefs.setInt(
      '${_operatorConversationCountKey}${operatorId}_unlock_time',
      DateTime.now().millisecondsSinceEpoch,
    );

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
    final currentCount =
        _prefs.getInt('$_operatorConversationCountKey$operatorId') ?? 0;
    await _prefs.setInt(
      '$_operatorConversationCountKey$operatorId',
      currentCount + 1,
    );

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

  /// 根据ID获取操作员
  OperatorPersonality? getOperatorById(String id) {
    return _allOperators.firstWhereOrNull((op) => op.id == id);
  }

  /// 获取随机操作员（优先已解锁的操作员）
  OperatorPersonality getRandomOperator() {
    final unlockedOperators = getUnlockedOperators();

    // 如果有已解锁的操作员，从已解锁中选
    if (unlockedOperators.isNotEmpty) {
      final random = DateTime.now().microsecond % unlockedOperators.length;
      return unlockedOperators[random];
    }

    // 否则随机选择任意操作员
    final random = DateTime.now().microsecond % _allOperators.length;
    return _allOperators[random];
  }

  /// 检查操作员是否已解锁
  bool isOperatorUnlocked(String operatorId) {
    return _unlockedOperatorIds.contains(operatorId);
  }

  /// 获取已解锁的操作员数量
  int getUnlockedCount() {
    return _unlockedOperatorIds.length;
  }

  /// 清空所有解锁记录（用于测试）
  Future<void> clearAllUnlocks() async {
    _unlockedOperatorIds.clear();
    await _prefs.remove(_unlockedOperatorsKey);

    // 重置对话计数
    for (final op in _allOperators) {
      await _prefs.remove('$_operatorConversationCountKey${op.id}');
      await _prefs.remove(
        '${_operatorConversationCountKey}${op.id}_unlock_time',
      );
    }

    // 重新加载
    _loadUnlockedOperators();
  }

  /// 重置单个操作员的解锁状态
  Future<void> resetOperator(String operatorId) async {
    _unlockedOperatorIds.remove(operatorId);
    await _prefs.setStringList(
      _unlockedOperatorsKey,
      _unlockedOperatorIds.toList(),
    );

    await _prefs.remove('$_operatorConversationCountKey$operatorId');
    await _prefs.remove(
      '${_operatorConversationCountKey}${operatorId}_unlock_time',
    );

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
}
