import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bipupu/core/services/bluetooth_device_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  late AnimationController _titleAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;

  late PageController _posterController;
  int _currentPosterIndex = 0;
  List<dynamic> _posters = [];

  @override
  void initState() {
    super.initState();

    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleAnimationController, curve: Curves.easeOut),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _titleAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _titleAnimationController.forward();
    _posterController = PageController();
    _loadPosters();
    _setupBluetoothListener();
  }

  Future<void> _loadPosters() async {
    try {
      final response = await ApiClient.instance.api.posters
          .getApiPostersActive();
      if (mounted) {
        setState(() => _posters = response);
      }
    } catch (e) {
      debugPrint('Error loading posters: $e');
    }
  }

  void _setupBluetoothListener() {
    _bluetoothService.connectionState.addListener(() {
      if (mounted) {
        setState(
          () => _connectionState = _bluetoothService.connectionState.value,
        );
      }
    });
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _posterController.dispose();
    super.dispose();
  }

  // --- 逻辑辅助方法 ---
  bool get _isConnected =>
      _connectionState == BluetoothConnectionState.connected;

  String _buildPosterImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    final baseUrl = ApiClient.instance.dio.options.baseUrl;
    return '$baseUrl$imageUrl';
  }

  // --- UI 构建方法 ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 顶部标题区
            _buildTopHeader(context, topPadding, isDarkMode),

            // 2. 主内容区 (统一 Padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 海报轮播 (AspectRatio 解决抖动)
                  _buildPosterSection(context, isDarkMode),

                  const SizedBox(height: 16),

                  // 蓝牙设备卡片
                  _buildDeviceCard(context),

                  const SizedBox(height: 16),

                  // 快捷操作网格
                  _buildQuickActionsGrid(context),

                  // 底部安全间距
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    double topPadding,
    bool isDarkMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.surface
            : colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _titleSlideAnimation,
            child: FadeTransition(
              opacity: _titleFadeAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ).createShader(bounds),
                child: const Text(
                  'Bipupu',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'connection_communication_discovery'.tr(),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterSection(BuildContext context, bool isDarkMode) {
    return AspectRatio(
      aspectRatio: 1.8, // 约 16:9，固定比例防止加载时下方内容跳动
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _posters.isEmpty
              ? const Center(
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _posterController,
                      itemCount: _posters.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPosterIndex = i),
                      itemBuilder: (context, index) =>
                          _buildPosterItem(_posters[index]),
                    ),
                    _buildPosterIndicator(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPosterItem(dynamic poster) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _buildPosterImageUrl(poster.imageUrl ?? ''),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black12),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        ),
        // 文字遮罩渐变
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 50,
          child: Text(
            poster.title ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPosterIndicator() {
    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(_posters.length, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPosterIndex == index
                    ? Colors.white
                    : Colors.white54,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _isConnected ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(
                    _isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected
                            ? 'device_connected'.tr()
                            : 'my_device'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isConnected
                            ? 'send_messages_to_device'.tr()
                            : 'connect_bluetooth_to_enable'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isConnected ? 'connected'.tr() : 'not_connected'.tr(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _handleDeviceButtonPressed(context),
              icon: Icon(
                _isConnected ? Icons.send : Icons.bluetooth_searching,
                size: 18,
              ),
              label: Text(
                _isConnected ? 'transmit'.tr() : 'connect_device'.tr(),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: _isConnected
                    ? Colors.green
                    : colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          'friends'.tr(),
          Icons.people_alt_rounded,
          Colors.blue,
          () => context.push('/home/contacts'),
        ),
        _buildActionCard(
          context,
          'voice_test_title'.tr(),
          Icons.mic,
          const Color(0xFF49FF61),
          () => context.push('/home/voice_test'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeviceButtonPressed(BuildContext context) {
    if (_isConnected) {
      context.push('/home/bluetooth_message_test');
    } else {
      context.push('/profile/bluetooth/scan');
    }
  }
}
