import 'dart:async';
import 'dart:developer';
import 'dart:math' show max;

import 'im_service.dart';
import 'bluetooth_device_service.dart';
import '../api/models/message_response.dart';
import '../api/models/message_type.dart';

/// 蓝牙消息转发服务
///
/// ── 原理 ──────────────────────────────────────────────────────────────────
/// 本服务运行在 **主 Flutter 引擎（UI isolate）** 中，与 [ImService] 和
/// [BluetoothDeviceService] 处于同一 Dart 事件循环。
///
/// 当用户将 App 切换到后台（[AppLifecycleState.paused]），主引擎的事件循环
/// **依然持续运行**，前提是 Foreground Service（[BackgroundMessageService]）
/// 保持进程存活（AndroidManifest 已声明 foregroundServiceType=connectedDevice）。
///
/// 因此，ImService 长轮询收到的新消息会触发 [_onImServiceChanged]，
/// 进而通过 BLE 写入已绑定的蓝牙设备，实现**后台消息自动转发**。
///
/// ── 消息格式 ──────────────────────────────────────────────────────────────
/// 发送给蓝牙设备的文本格式为：
///   [senderBipupuId]: content（超出 BLE MTU 时末尾截断并加省略号）
///
/// 系统消息（[MessageType.system]）不转发，以免打扰。
class BluetoothForwardService {
  static final BluetoothForwardService _instance =
      BluetoothForwardService._internal();
  factory BluetoothForwardService() => _instance;
  BluetoothForwardService._internal();

  final ImService _imService = ImService();
  final BluetoothDeviceService _btService = BluetoothDeviceService();

  bool _running = false;

  /// 主引擎侧已转发的最大消息 ID，防止重复转发
  int _lastForwardedId = 0;

  // ── 公开 API ─────────────────────────────────────────────────────────────

  /// 启动转发服务
  ///
  /// 应在用户成功登录后调用（与 [BackgroundMessageService.start] 同步）。
  void start() {
    if (_running) return;
    _running = true;

    // 用当前已有消息初始化游标，避免把历史消息当新消息转发
    _initCursorFromCurrentMessages();

    _imService.addListener(_onImServiceChanged);
    log('[BtForward] 转发服务已启动，初始游标: $_lastForwardedId');
  }

  /// 停止转发服务（用户登出时调用）
  void stop() {
    if (!_running) return;
    _imService.removeListener(_onImServiceChanged);
    _running = false;
    _lastForwardedId =
        0; // 重置游标，下次 start() 通过 _initCursorFromCurrentMessages 重新初始化
    log('[BtForward] 转发服务已停止');
  }

  bool get isRunning => _running;

  /// 外部强制转发（由 main.dart 订阅后台服务 invoke 事件时调用）
  ///
  /// [rawMessages] 是后台 isolate 通过 `service.invoke('btForwardMessages')`
  /// 推送过来的原始 JSON 消息列表。用于应对主引擎 ImService 已恢复轮询之前的
  /// 短暂空窗期，属于"双保险"机制。
  Future<void> forwardRawMessages(List<dynamic> rawMessages) async {
    if (!_btService.isConnected) return;

    for (final raw in rawMessages) {
      if (raw is! Map) continue;
      final id = raw['id'] as int? ?? 0;
      if (id <= _lastForwardedId) continue; // 已处理，跳过

      final senderId = raw['sender_bipupu_id'] as String? ?? '未知';
      final content = (raw['content'] as String?) ?? '';
      final typeStr = raw['message_type'] as String? ?? '';

      // 跳过系统消息
      if (typeStr.toUpperCase() == 'SYSTEM') continue;

      await _sendToBluetooth(id: id, senderId: senderId, content: content);
    }
  }

  // ── 私有方法 ──────────────────────────────────────────────────────────────

  void _initCursorFromCurrentMessages() {
    final msgs = _imService.receivedMessages;
    if (msgs.isEmpty) return;

    int maxId = 0;
    for (final m in msgs) {
      final id = _extractId(m);
      if (id > maxId) maxId = id;
    }
    _lastForwardedId = maxId;
  }

  /// ImService 通知监听回调（每次 notifyListeners 触发）
  void _onImServiceChanged() {
    final msgs = _imService.receivedMessages;
    if (msgs.isEmpty) return;

    // 找出比当前游标新的消息
    final pending = <MessageResponse>[];
    for (final m in msgs) {
      if (m is MessageResponse && m.id > _lastForwardedId) {
        pending.add(m);
      }
    }

    if (pending.isEmpty) return;

    // 先更新游标，防止重入时重复转发
    _lastForwardedId = pending.map((m) => m.id).reduce(max);

    // 过滤系统消息，逐条异步转发
    for (final msg in pending) {
      if (msg.messageType == MessageType.system) continue;
      unawaited(
        _sendToBluetooth(
          id: msg.id,
          senderId: msg.senderBipupuId,
          content: msg.content,
        ),
      );
    }
  }

  /// 格式化并写入蓝牙设备
  Future<void> _sendToBluetooth({
    required int id,
    required String senderId,
    required String content,
  }) async {
    if (!_btService.isConnected) {
      log('[BtForward] 消息 $id：蓝牙未连接，跳过转发');
      return;
    }

    final maxLen = _btService.maxTextLength;

    // 前缀格式："[senderId]: "
    final prefix = '[$senderId]: ';
    final prefixLen = prefix.length;

    final maxBody = maxLen - prefixLen;
    final String body;
    if (maxBody <= 0) {
      // 极端情况：ID 本身太长，只发前缀
      body = '';
    } else if (content.length > maxBody) {
      // 截断并加省略号（占 1 个字符位）
      body = '${content.substring(0, maxBody - 1)}…';
    } else {
      body = content;
    }

    final text = '$prefix$body';
    final sent = await _btService.safeSendTextMessage(text);

    log('[BtForward] 消息 $id → 蓝牙 ${sent ? "✓ 成功" : "✗ 失败"}');
  }

  static int _extractId(dynamic m) {
    if (m is MessageResponse) return m.id;
    if (m is Map) return (m['id'] as int?) ?? 0;
    return 0;
  }
}
