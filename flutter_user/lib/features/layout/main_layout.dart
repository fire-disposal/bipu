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
    final theme = Theme.of(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.3 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.home_rounded,
                  '首页',
                  currentIndex,
                ),
                _buildPagerItem(context, 1, currentIndex),
                _buildNavItem(
                  context,
                  2,
                  Icons.chat_bubble_rounded,
                  '消息',
                  currentIndex,
                ),
                _buildNavItem(
                  context,
                  3,
                  Icons.person_rounded,
                  '我的',
                  currentIndex,
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagerItem(BuildContext context, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Expanded(
      child: GestureDetector(
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : activeColor.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.mic_rounded,
                color: isSelected
                    ? colorScheme.onPrimary
                    : activeColor.withOpacity(0.7),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '对讲',
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
