import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/widgets.dart';
import 'package:bipupu/api/api.dart';
import 'auth_service.dart';

typedef SocketEventHandler = void Function(Map<String, dynamic> event);

class ImSocketService {
  ImSocketService({required this.onEvent});

  final SocketEventHandler onEvent;

  IOWebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;
  Duration _reconnectDelay = const Duration(seconds: 5);
  Timer? _pingTimer;

  final ValueNotifier<bool> socketConnected = ValueNotifier<bool>(false);

  Future<void> connectSocket({String path = '/api/ws'}) async {
    try {
      final uri = Uri.parse(AppConfig.baseUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final port = uri.hasPort ? uri.port : (scheme == 'wss' ? 443 : 80);

      final token = await tokenStorage.getAccessToken();

      final wsUri = Uri(
        scheme: scheme,
        host: uri.host,
        port: port,
        path: path,
        queryParameters: token != null && token.isNotEmpty
            ? {'token': token}
            : null,
      );

      try {
        _wsSub?.cancel();
        _wsChannel?.sink.close();
      } catch (_) {}

      _wsChannel = IOWebSocketChannel.connect(wsUri.toString());
      socketConnected.value = true;

      _wsSub = _wsChannel!.stream.listen(
        (event) {
          _handleSocketEvent(event);
        },
        onDone: () async {
          socketConnected.value = false;
          _stopPing();
          await Future.delayed(_reconnectDelay);
          if (AuthService().authState.value == AuthStatus.authenticated) {
            unawaited(connectSocket(path: path));
          }
        },
        onError: (err) async {
          socketConnected.value = false;
          _stopPing();
          await Future.delayed(_reconnectDelay);
          if (AuthService().authState.value == AuthStatus.authenticated) {
            unawaited(connectSocket(path: path));
          }
        },
      );

      _startPing();
    } catch (e) {
      socketConnected.value = false;
      log('ImSocketService: connect failed: $e');
    }
  }

  void disconnectSocket() {
    try {
      _stopPing();
      _wsSub?.cancel();
      _wsChannel?.sink.close();
    } catch (_) {}
    _wsSub = null;
    _wsChannel = null;
    socketConnected.value = false;
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final String payload = event is String
          ? event
          : utf8.decode(event as List<int>);
      final Map<String, dynamic> data = json.decode(payload);
      onEvent(data);
    } catch (e) {
      // ignore parse errors
    }
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      try {
        if (_wsChannel != null) {
          _wsChannel!.sink.add(json.encode({'type': 'ping'}));
        }
      } catch (_) {}
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void dispose() {
    _stopPing();
    try {
      socketConnected.dispose();
    } catch (_) {}
    try {
      _wsSub?.cancel();
      _wsChannel?.sink.close();
    } catch (_) {}
  }
}
