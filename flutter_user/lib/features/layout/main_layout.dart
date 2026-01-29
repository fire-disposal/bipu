import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import '../../core/services/toast_service.dart';
import '../../services/speech_recognition_service.dart';
import '../../core/bluetooth/ble_pipeline.dart';

/// 重构后的主布局
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final RecorderStream _recorder = RecorderStream();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final BlePipeline _blePipeline = BlePipeline();
  bool _isSpeechInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _recorder.initialize();
      await _speechService.init();
      if (mounted) {
        setState(() {
          _isSpeechInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
      if (mounted) {
        ToastService().showError('Speech service init failed: $e');
      }
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pager')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/pager');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Future<void> _onPagerLongPressed(BuildContext context) async {
    if (!_isSpeechInitialized) {
      if (mounted) {
        ToastService().showWarning(
          'Speech service initializing or failed. Check logs.',
        );
        _initSpeech();
      }
      return;
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ToastService().showWarning('Microphone permission required');
      }
      return;
    }

    try {
      await _recorder.start();
      _speechService.startListening(_recorder.audioStream);

      ToastService().showInfo(
        'Listening...',
        duration: const Duration(minutes: 1),
      );
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      ToastService().showError('Failed to start recording: $e');
    }
  }

  Future<void> _onPagerLongPressEnd(BuildContext context) async {
    ToastService().scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

    await _recorder.stop();
    _speechService.stop();

    if (mounted) {
      context.go('/pager');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: Column(
        children: [
          // 主内容区域
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home, 'Home', currentIndex),
              _buildPagerItem(context, 1, currentIndex),
              _buildNavItem(
                context,
                2,
                Icons.message,
                'Messages',
                currentIndex,
              ),
              _buildNavItem(context, 3, Icons.person, 'My', currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPagerItem(BuildContext context, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onItemTapped(index, context),
      onLongPress: () {
        if (isSelected) {
          _onPagerLongPressed(context);
        } else {
          _onItemTapped(index, context);
        }
      },
      onLongPressUp: () {
        if (isSelected) {
          _onPagerLongPressEnd(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, color: color, size: 28),
          Text('Pager', style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
