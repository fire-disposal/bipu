import 'dart:async';
import 'dart:developer';

import 'package:bipupu/core/network/network.dart';

import 'im_service.dart';
import 'bluetooth_device_service.dart';
import 'unified_bluetooth_protocol.dart';
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
///   [用户昵称/备注]: 消息正文（超出 BLE MTU 时末尾字节感知截断并加省略号）
///
/// ESP32 端（app_ble.c）会解析此前缀，分离出发送者名与正文后再显示。
/// 直接从测试页发送的消息无此前缀，ESP32 端显示为 "App"。
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

  /// bipupuId → 显示名称 缓存（alias > nickname > username > id）
  /// 懒加载：首次需要时加载，之后每 5 分钟刷新
  final Map<String, String> _senderDisplayNameCache = {};
  bool _cacheLoaded = false;
  bool _cacheLoading = false;

  /// 周期刷新定时器
  Timer? _cacheRefreshTimer;

  // ── 公开 API ─────────────────────────────────────────────────────────────

  /// 启动转发服务
  ///
  /// 应在用户成功登录后调用（与 [BackgroundMessageService.start] 同步）。
  void start() {
    if (_running) return;
    _running = true;

    // 用当前已有消息初始化游标，避免把历史消息当新消息转发
    _initCursorFromCurrentMessages();

    // 联系人缓存改为懒加载，不在此处加载

    // 每 5 分钟周期刷新一次（应对联系人多、备注名变更等场景）
    _cacheRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_refreshContactsCache()),
    );

    _imService.addListener(_onImServiceChanged);
    log('[BtForward] 转发服务已启动，初始游标：$_lastForwardedId');
  }

  /// 停止转发服务（用户登出时调用）
  void stop() {
    if (!_running) return;
    _imService.removeListener(_onImServiceChanged);
    _cacheRefreshTimer?.cancel();
    _cacheRefreshTimer = null;
    _running = false;
    _lastForwardedId = 0;
    _senderDisplayNameCache.clear();
    log('[BtForward] 转发服务已停止');
  }

  bool get isRunning => _running;

  /// 外部强制转发（由 main.dart 订阅后台服务 invoke 事件时调用）
  ///
  /// [rawMessages] 是后台 isolate 通过 `service.invoke('btForwardMessages')`
  /// 推送过来的原始 JSON 消息列表。
  ///
  /// 速率限制：每次最多处理 5 条，防止消息洪泛导致蓝牙写入串队。
  Future<void> forwardRawMessages(List<dynamic> rawMessages) async {
    if (!_btService.isConnected) return;

    const maxPerBatch = 5;
    int forwarded = 0;
    int maxProcessedId = _lastForwardedId;

    for (final raw in rawMessages) {
      if (raw is! Map) continue;
      final id = raw['id'] as int? ?? 0;
      if (id <= _lastForwardedId) continue; // 已处理，跳过

      if (forwarded >= maxPerBatch) {
        log('[BtForward] 批次限额已达（$maxPerBatch 条），剩余消息将在下次轮询处理');
        break;
      }

      final senderId = raw['sender_bipupu_id'] as String? ?? '未知';
      final content = (raw['content'] as String?) ?? '';
      final typeStr = raw['message_type'] as String? ?? '';

      if (typeStr.toUpperCase() == 'SYSTEM') continue;

      if (id > maxProcessedId) maxProcessedId = id;

      final displayName = _getSenderDisplayName(senderId);
      await _sendToBluetooth(
        id: id,
        senderDisplayName: displayName,
        content: content,
      );
      forwarded++;
    }

    // 更新游标：防止 _onImServiceChanged 重复转发相同消息
    if (maxProcessedId > _lastForwardedId) {
      _lastForwardedId = maxProcessedId;
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
    _lastForwardedId = pending.map((m) => m.id).reduce((a, b) => a > b ? a : b);

    // 过滤系统消息，逐条异步转发
    for (final msg in pending) {
      if (msg.messageType == MessageType.system) continue;
      // 将 bipupuId 转换为可读显示名，未命中缓存时退化为 ID 本身
      final displayName = _getSenderDisplayName(msg.senderBipupuId);
      unawaited(
        _sendToBluetooth(
          id: msg.id,
          senderDisplayName: displayName,
          content: msg.content,
        ),
      );
    }
  }

  /// 格式化并写入蓝牙设备
  ///
  /// [senderDisplayName] 与 [content] 作为两个独立参数传入 [BluetoothDeviceService.sendTextMessage]，
  /// 底层 [UnifiedBluetoothProtocol.createTextPacket] 将其编码为长度前缀二进制格式：
  ///   `[ 1B: sender_len ][ sender UTF-8 ][ body UTF-8 ]`
  /// ESP32 侧由 `bipupu_protocol.c` 在协议层直接解析，无字符串拼接/切割。
  ///
  /// 注意：使用 sendTextMessage() 会等待 ACK 确认，确保可靠送达
  Future<void> _sendToBluetooth({
    required int id,
    required String senderDisplayName,
    required String content,
  }) async {
    if (!_btService.isConnected) {
      log('[BtForward] 消息 $id：蓝牙未连接，跳过转发');
      return;
    }

    try {
      // 使用 sendTextMessage() 等待 ACK 确认（带重试机制）
      // 超时时间：5 秒 * 3 次重试 = 15 秒
      final sent = await _btService.sendTextMessage(
        content,
        sender: senderDisplayName,
      );
      log(
        '[BtForward] 消息 $id [from: $senderDisplayName] → 蓝牙 ${sent ? "✓ 成功 (ACK 确认)" : "✗ 失败 (未收到 ACK)"}',
      );
    } catch (e) {
      log(
        '[BtForward] 消息 $id [from: $senderDisplayName] → 蓝牙 ✗ 异常：$e',
      );
    }
  }

  // ── 联系人姓名缓存 ────────────────────────────────────────────────────────

  /// 从联系人 API 加载所有联系人，建立 bipupuId → displayName 映射
  ///
  /// 分页拉取直到全部加载完毕（服务器每页最多 100 条）。
  /// 失败时静默忽略——降级为直接显示 bipupuId。
  Future<void> _refreshContactsCache() async {
    if (_cacheLoading && !_cacheLoaded) {
      // 已经在加载中，跳过
      return;
    }
    
    try {
      const pageSize = 100;
      int page = 1;
      int loaded = 0;
      int total = 1;

      while (loaded < total) {
        final resp = await ApiClient.instance.api.contacts.getApiContacts(
          page: page,
          pageSize: pageSize,
        );
        total = resp.total;

        for (final c in resp.contacts) {
          final displayName =
              (c.alias?.isNotEmpty == true ? c.alias : null) ??
              (c.contactNickname?.isNotEmpty == true
                  ? c.contactNickname
                  : null) ??
              c.contactUsername;
          _senderDisplayNameCache[c.contactId] = displayName;
        }

        loaded += resp.contacts.length;
        page++;

        if (resp.contacts.isEmpty) break;
      }

      _cacheLoaded = true;
      log('[BtForward] 联系人缓存已加载，共 ${_senderDisplayNameCache.length} 条');
    } catch (e) {
      log('[BtForward] 加载联系人缓存失败（降级为 ID 显示）: $e');
    }
  }

  /// 根据 bipupuId 查询可读显示名，未命中时直接返回 id
  /// 懒加载：首次调用时触发加载
  String _getSenderDisplayName(String bipupuId) {
    // 如果缓存已加载，直接返回
    if (_cacheLoaded) {
      return _senderDisplayNameCache[bipupuId] ?? bipupuId;
    }
    
    // 如果正在加载，返回 ID（加载完成后会更新）
    if (_cacheLoading) {
      return bipupuId;
    }
    
    // 首次需要时触发加载
    _cacheLoading = true;
    unawaited(_refreshContactsCache().whenComplete(() => _cacheLoading = false));
    
    return bipupuId;
  }

  static int _extractId(dynamic m) {
    if (m is MessageResponse) return m.id;
    if (m is Map) return (m['id'] as int?) ?? 0;
    return 0;
  }
}
