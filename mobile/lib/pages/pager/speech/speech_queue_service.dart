import 'dart:async';
import 'dart:collection';
import '../../../core/voice/voice_service.dart';
import '../../../core/utils/logger.dart';

/// 台词播放优先级
enum SpeechPriority {
  /// 立即中断当前播放
  immediate,

  /// 等待当前播放完成后立即播放
  high,

  /// 普通优先级
  normal,

  /// 低优先级，在队列空闲时播放
  low,
}

/// 台词播放状态
enum SpeechState { pending, playing, completed, failed, cancelled }

/// 台词项
class SpeechItem {
  final String text;
  final int voiceId;
  final double speed;
  final SpeechPriority priority;
  final String? id;
  final DateTime createdAt;
  final Duration? timeout;
  final int maxRetries;
  int retryCount;
  SpeechState state;

  SpeechItem({
    required this.text,
    this.voiceId = 0,
    this.speed = 1.0,
    this.priority = SpeechPriority.normal,
    this.id,
    DateTime? createdAt,
    this.timeout,
    this.maxRetries = 1,
    this.retryCount = 0,
    this.state = SpeechState.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否应该重试
  bool get shouldRetry => retryCount < maxRetries;

  /// 是否已超时
  bool get isTimedOut {
    if (timeout == null) return false;
    final elapsed = DateTime.now().difference(createdAt);
    return elapsed > timeout!;
  }

  @override
  String toString() =>
      'SpeechItem(text: "$text", priority: $priority, state: $state)';
}

/// 台词队列服务 - 异步台词播放管理器
class SpeechQueueService {
  final VoiceService _voiceService;
  final List<StreamController<SpeechItem>> _itemControllers = [];

  // 优先级队列
  final _highPriorityQueue = Queue<SpeechItem>();
  final _normalPriorityQueue = Queue<SpeechItem>();
  final _lowPriorityQueue = Queue<SpeechItem>();

  // 状态管理
  SpeechItem? _currentItem;
  bool _isProcessing = false;
  bool _isPaused = false;
  bool _isStopping = false;

  // 事件流
  final StreamController<SpeechItem> _itemStartedController =
      StreamController.broadcast();
  final StreamController<SpeechItem> _itemCompletedController =
      StreamController.broadcast();
  final StreamController<SpeechItem> _itemFailedController =
      StreamController.broadcast();
  final StreamController<void> _queueEmptyController =
      StreamController.broadcast();
  final StreamController<SpeechPriority> _priorityChangedController =
      StreamController.broadcast();

  Stream<SpeechItem> get onItemStarted => _itemStartedController.stream;
  Stream<SpeechItem> get onItemCompleted => _itemCompletedController.stream;
  Stream<SpeechItem> get onItemFailed => _itemFailedController.stream;
  Stream<void> get onQueueEmpty => _queueEmptyController.stream;
  Stream<SpeechPriority> get onPriorityChanged =>
      _priorityChangedController.stream;

  /// 当前正在播放的台词项
  SpeechItem? get currentItem => _currentItem;

  /// 是否正在播放
  bool get isPlaying => _currentItem != null && !_isPaused;

  /// 是否已暂停
  bool get isPaused => _isPaused;

  /// 队列总长度
  int get totalQueueLength =>
      _highPriorityQueue.length +
      _normalPriorityQueue.length +
      _lowPriorityQueue.length;

  SpeechQueueService({VoiceService? voiceService})
    : _voiceService = voiceService ?? VoiceService();

  /// 添加台词到队列
  ///
  /// [text]: 台词文本
  /// [priority]: 播放优先级
  /// [voiceId]: 语音ID
  /// [speed]: 语速
  /// [id]: 唯一标识符（用于取消特定台词）
  /// [timeout]: 超时时间
  /// [maxRetries]: 最大重试次数
  ///
  /// 返回一个Stream，用于监听该台词的状态变化
  Stream<SpeechItem> enqueue({
    required String text,
    SpeechPriority priority = SpeechPriority.normal,
    int voiceId = 0,
    double speed = 1.0,
    String? id,
    Duration? timeout,
    int maxRetries = 1,
  }) {
    final item = SpeechItem(
      text: text,
      voiceId: voiceId,
      speed: speed,
      priority: priority,
      id: id,
      timeout: timeout,
      maxRetries: maxRetries,
    );

    // 根据优先级添加到对应队列
    switch (priority) {
      case SpeechPriority.immediate:
        // 立即优先级：中断当前播放，立即播放
        _handleImmediateItem(item);
        break;
      case SpeechPriority.high:
        _highPriorityQueue.add(item);
        break;
      case SpeechPriority.normal:
        _normalPriorityQueue.add(item);
        break;
      case SpeechPriority.low:
        _lowPriorityQueue.add(item);
        break;
    }

    // 创建该台词的专用事件流
    final controller = StreamController<SpeechItem>();
    _itemControllers.add(controller);

    // 监听通用事件并转发到专用流
    _setupItemStreamForwarding(item, controller);

    // 如果不在处理中且未暂停，开始处理队列
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }

    return controller.stream;
  }

  /// 添加台词到队列并等待播放完成
  ///
  /// [text]: 台词文本
  /// [priority]: 播放优先级
  /// [voiceId]: 语音ID
  /// [speed]: 语速
  /// [id]: 唯一标识符（用于取消特定台词）
  /// [timeout]: 超时时间
  /// [maxRetries]: 最大重试次数
  /// [playbackTimeout]: 播放超时时间（等待播放完成的超时）
  ///
  /// 返回一个Future，在台词播放完成、失败或超时时完成
  /// 成功时返回true，失败时抛出异常
  Future<bool> enqueueAndWait({
    required String text,
    SpeechPriority priority = SpeechPriority.normal,
    int voiceId = 0,
    double speed = 1.0,
    String? id,
    Duration? timeout,
    int maxRetries = 1,
    Duration playbackTimeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<bool>();
    final itemId = id ?? DateTime.now().microsecondsSinceEpoch.toString();

    logger.i(
      'SpeechQueueService.enqueueAndWait: 添加台词并等待: "$text" (ID: $itemId)',
    );

    try {
      // 使用enqueue方法添加台词到队列
      final stream = enqueue(
        text: text,
        priority: priority,
        voiceId: voiceId,
        speed: speed,
        id: itemId,
        timeout: timeout,
        maxRetries: maxRetries,
      );

      // 设置超时
      final timeoutFuture = Future.delayed(playbackTimeout, () {
        if (!completer.isCompleted) {
          logger.w('SpeechQueueService.enqueueAndWait: 播放超时: "$text"');
          completer.completeError(
            TimeoutException('台词播放超时: $text', playbackTimeout),
          );
        }
      });

      // 监听台词状态
      stream.listen(
        (item) {
          // 当台词状态发生变化时
          if (item.state == SpeechState.completed) {
            logger.i('SpeechQueueService.enqueueAndWait: 台词播放完成: "$text"');
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } else if (item.state == SpeechState.failed) {
            logger.w('SpeechQueueService.enqueueAndWait: 台词播放失败: "$text"');
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('台词播放失败: $text (重试次数: ${item.retryCount})'),
              );
            }
          } else if (item.state == SpeechState.cancelled) {
            logger.i('SpeechQueueService.enqueueAndWait: 台词被取消: "$text"');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          }
        },
        onError: (error) {
          logger.e('SpeechQueueService.enqueueAndWait: 监听流错误: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          // 流关闭但未完成播放（可能是被取消）
          if (!completer.isCompleted) {
            logger.i('SpeechQueueService.enqueueAndWait: 台词流关闭，可能被取消: "$text"');
            completer.complete(false);
          }
        },
        cancelOnError: false,
      );

      // 等待播放完成或超时
      await Future.any([completer.future, timeoutFuture]);

      // 如果超时先发生，这里会抛出异常
      return await completer.future;
    } catch (e, stackTrace) {
      logger.e(
        'SpeechQueueService.enqueueAndWait: 添加台词失败',
        error: e,
        stackTrace: stackTrace,
      );

      // 如果失败，尝试取消该台词
      cancelById(itemId);

      rethrow;
    }
  }

  /// 处理立即优先级台词（中断当前播放）
  void _handleImmediateItem(SpeechItem item) {
    logger.i('SpeechQueueService: 收到立即优先级台词: "${item.text}"');

    // 如果有正在播放的台词，停止它
    if (_currentItem != null) {
      logger.i('SpeechQueueService: 中断当前播放: "${_currentItem!.text}"');
      _currentItem!.state = SpeechState.cancelled;
      _itemCompletedController.add(_currentItem!);
      _voiceService.stop();
    }

    // 清空所有队列（立即优先级台词优先于一切）
    _highPriorityQueue.clear();
    _normalPriorityQueue.clear();
    _lowPriorityQueue.clear();

    // 立即播放
    _playItem(item);
  }

  /// 设置台词事件转发
  void _setupItemStreamForwarding(
    SpeechItem item,
    StreamController<SpeechItem> controller,
  ) {
    // 监听开始事件
    onItemStarted.listen((startedItem) {
      if (startedItem == item) {
        controller.add(startedItem);
      }
    });

    // 监听完成事件
    onItemCompleted.listen((completedItem) {
      if (completedItem == item) {
        controller.add(completedItem);
        controller.close();
        _itemControllers.remove(controller);
      }
    });

    // 监听失败事件
    onItemFailed.listen((failedItem) {
      if (failedItem == item) {
        controller.add(failedItem);
        // 如果应该重试，不关闭流
        if (!failedItem.shouldRetry) {
          controller.close();
          _itemControllers.remove(controller);
        }
      }
    });
  }

  /// 处理队列
  Future<void> _processQueue() async {
    if (_isProcessing || _isPaused) return;

    _isProcessing = true;

    try {
      while (totalQueueLength > 0 && !_isPaused && !_isStopping) {
        // 获取下一个要播放的台词（按优先级顺序）
        SpeechItem? nextItem;

        if (_highPriorityQueue.isNotEmpty) {
          nextItem = _highPriorityQueue.removeFirst();
        } else if (_normalPriorityQueue.isNotEmpty) {
          nextItem = _normalPriorityQueue.removeFirst();
        } else if (_lowPriorityQueue.isNotEmpty) {
          nextItem = _lowPriorityQueue.removeFirst();
        }

        if (nextItem != null) {
          await _playItem(nextItem);
        }

        // 给事件循环一个机会处理其他事件
        await Future.delayed(Duration.zero);
      }

      // 队列处理完成
      if (totalQueueLength == 0 && _currentItem == null) {
        logger.i('SpeechQueueService: 队列已空');
        _queueEmptyController.add(null);
      }
    } finally {
      _isProcessing = false;
      _currentItem = null;
    }
  }

  /// 播放单个台词项
  Future<void> _playItem(SpeechItem item) async {
    logger.i('SpeechQueueService: 开始播放台词: "${item.text}"');

    _currentItem = item;
    item.state = SpeechState.playing;
    _itemStartedController.add(item);

    try {
      // 播放TTS
      await _voiceService.speak(
        item.text,
        sid: item.voiceId,
        speed: item.speed,
      );

      // 播放成功
      item.state = SpeechState.completed;
      logger.i('SpeechQueueService: 台词播放完成: "${item.text}"');
      _itemCompletedController.add(item);
    } catch (e, stackTrace) {
      logger.e(
        'SpeechQueueService: 台词播放失败: "${item.text}"',
        error: e,
        stackTrace: stackTrace,
      );

      item.state = SpeechState.failed;
      item.retryCount++;

      if (item.shouldRetry && !item.isTimedOut) {
        logger.i(
          'SpeechQueueService: 准备重试台词 (${item.retryCount}/${item.maxRetries}): "${item.text}"',
        );

        // 根据优先级重新加入队列
        switch (item.priority) {
          case SpeechPriority.immediate:
            // 立即优先级失败时不重试（可能有问题）
            _itemFailedController.add(item);
            break;
          case SpeechPriority.high:
            _highPriorityQueue.addFirst(item);
            break;
          case SpeechPriority.normal:
            _normalPriorityQueue.addFirst(item);
            break;
          case SpeechPriority.low:
            _lowPriorityQueue.addFirst(item);
            break;
        }
      } else {
        logger.w('SpeechQueueService: 台词达到最大重试次数或超时: "${item.text}"');
        _itemFailedController.add(item);
      }
    } finally {
      _currentItem = null;
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (_isPaused || _currentItem == null) return;

    logger.i('SpeechQueueService: 暂停播放');
    _isPaused = true;

    try {
      await _voiceService.stop();
    } catch (e) {
      logger.e('SpeechQueueService: 暂停播放失败', error: e);
    }
  }

  /// 恢复播放
  Future<void> resume() async {
    if (!_isPaused) return;

    logger.i('SpeechQueueService: 恢复播放');
    _isPaused = false;

    // 如果当前有台词，重新播放
    if (_currentItem != null) {
      _currentItem!.state = SpeechState.playing;
      await _playItem(_currentItem!);
    } else if (totalQueueLength > 0) {
      // 否则重新开始处理队列
      _processQueue();
    }
  }

  /// 停止所有播放并清空队列
  Future<void> stop() async {
    logger.i('SpeechQueueService: 停止所有播放');

    _isStopping = true;
    _isPaused = false;

    try {
      await _voiceService.stop();
    } catch (e) {
      logger.e('SpeechQueueService: 停止播放失败', error: e);
    }

    // 清空队列
    _highPriorityQueue.clear();
    _normalPriorityQueue.clear();
    _lowPriorityQueue.clear();

    // 标记当前台词为已取消
    if (_currentItem != null) {
      _currentItem!.state = SpeechState.cancelled;
      _itemCompletedController.add(_currentItem!);
      _currentItem = null;
    }

    _isStopping = false;
    _isProcessing = false;

    // 通知队列已清空
    _queueEmptyController.add(null);
  }

  /// 取消特定ID的台词
  bool cancelById(String id) {
    logger.i('SpeechQueueService: 取消台词 ID: $id');

    bool cancelled = false;

    // 检查当前播放的台词
    if (_currentItem != null && _currentItem!.id == id) {
      logger.i('SpeechQueueService: 取消当前播放的台词');
      _currentItem!.state = SpeechState.cancelled;
      _itemCompletedController.add(_currentItem!);
      _voiceService.stop();
      _currentItem = null;
      cancelled = true;
    }

    // 检查各个队列
    cancelled = _cancelInQueue(_highPriorityQueue, id) || cancelled;
    cancelled = _cancelInQueue(_normalPriorityQueue, id) || cancelled;
    cancelled = _cancelInQueue(_lowPriorityQueue, id) || cancelled;

    return cancelled;
  }

  /// 在队列中取消特定ID的台词
  bool _cancelInQueue(Queue<SpeechItem> queue, String id) {
    bool cancelled = false;
    final itemsToRemove = <SpeechItem>[];

    for (final item in queue) {
      if (item.id == id) {
        itemsToRemove.add(item);
        item.state = SpeechState.cancelled;
        _itemCompletedController.add(item);
        cancelled = true;
      }
    }

    for (final item in itemsToRemove) {
      queue.remove(item);
    }

    return cancelled;
  }

  /// 清除所有低优先级台词
  void clearLowPriority() {
    logger.i('SpeechQueueService: 清除所有低优先级台词');
    _lowPriorityQueue.clear();
  }

  /// 获取队列状态快照
  Map<String, dynamic> getQueueStatus() {
    return {
      'currentItem': _currentItem?.text,
      'isPlaying': isPlaying,
      'isPaused': isPaused,
      'isProcessing': _isProcessing,
      'highPriorityCount': _highPriorityQueue.length,
      'normalPriorityCount': _normalPriorityQueue.length,
      'lowPriorityCount': _lowPriorityQueue.length,
      'totalCount': totalQueueLength,
    };
  }

  /// 释放资源
  Future<void> dispose() async {
    logger.i('SpeechQueueService: 释放资源');

    await stop();

    await _itemStartedController.close();
    await _itemCompletedController.close();
    await _itemFailedController.close();
    await _queueEmptyController.close();
    await _priorityChangedController.close();

    for (final controller in _itemControllers) {
      await controller.close();
    }
    _itemControllers.clear();
  }
}
