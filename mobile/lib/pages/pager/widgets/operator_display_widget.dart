import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 虚拟接线员立绘显示组件
/// 支持从网络URL或Asset路径加载立绘资源
class OperatorDisplayWidget extends StatefulWidget {
  final String imageUrl; // 立绘URL或Asset路径
  final bool isAnimating; // 是否播放动画
  final double scale; // 缩放比例
  final Duration animationDuration; // 动画时长

  const OperatorDisplayWidget({
    super.key,
    this.imageUrl = 'assets/operators/default_operator.png',
    this.isAnimating = false,
    this.scale = 1.0,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<OperatorDisplayWidget> createState() => _OperatorDisplayWidgetState();
}

class _OperatorDisplayWidgetState extends State<OperatorDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: widget.scale).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    if (widget.isAnimating) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OperatorDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 构建立绘图像
  Widget _buildOperatorImage() {
    // 判断是否为网络URL
    if (widget.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    } else {
      // Asset路径
      return Image.asset(
        widget.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  /// 占位符
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// 错误显示
  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              '接线员',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildOperatorImage(),
          ),
        ),
      ),
    );
  }
}

/// 虚拟接线员卡片容器
/// 包含立绘和其他信息的完整卡片
class OperatorCardWidget extends StatelessWidget {
  final String operatorName;
  final String operatorImageUrl;
  final String statusText;
  final bool isAnimating;
  final VoidCallback? onTap;

  const OperatorCardWidget({
    super.key,
    this.operatorName = '虚拟接线员',
    this.operatorImageUrl = 'assets/operators/default_operator.png',
    this.statusText = '准备就绪',
    this.isAnimating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 立绘
            Expanded(
              child: OperatorDisplayWidget(
                imageUrl: operatorImageUrl,
                isAnimating: isAnimating,
                scale: 1.0,
              ),
            ),
            const SizedBox(height: 16),

            // 接线员信息
            Text(
              operatorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // 状态指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
