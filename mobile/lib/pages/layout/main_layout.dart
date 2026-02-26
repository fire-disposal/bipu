import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/toast_service.dart';
import '../../core/state/app_state_management.dart';
import 'enhanced_bottom_navigation.dart';

/// 重构后的主布局
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
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
    _onItemTappedAsync(index, context);
  }

  Future<void> _onItemTappedAsync(int index, BuildContext context) async {
    final uiCubit = StateProviders.getUiCubit(context);
    uiCubit.updateBottomNavIndex(index);

    // If currently listening and navigating away from pager, stop listening first
    if (_isListening && index != 1) {
      setState(() => _isListening = false);
    }

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
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ToastService().showWarning('Microphone permission required');
      }
      return;
    }

    setState(() => _isListening = true);
    ToastService().showInfo(
      'Listening...',
      duration: const Duration(minutes: 1),
    );
  }

  Future<void> _onPagerLongPressEnd(BuildContext context) async {
    setState(() => _isListening = false);

    ToastService().scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

    if (mounted) {
      if (context.mounted) {
        context.go('/pager');
      }
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
      body: widget.child,
      bottomNavigationBar: EnhancedBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        onPagerLongPress: () => _onPagerLongPressed(context),
        onPagerLongPressEnd: () => _onPagerLongPressEnd(context),
        isPagerListening: _isListening,
      ),
    );
  }
}
