import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shadcn UI 主题配置
class ShadcnThemeConfig {
  /// 获取亮色主题
  static ShadThemeData get lightTheme {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: ShadColorScheme(
        // 主色
        primary: const Color(0xFF007AFF),
        primaryForeground: Colors.white,

        // 次要色
        secondary: const Color(0xFF6B7280),
        secondaryForeground: Colors.white,

        // 背景色
        background: Colors.white,
        foreground: const Color(0xFF111827),

        // 卡片
        card: Colors.white,
        cardForeground: const Color(0xFF111827),

        // 弹出框
        popover: Colors.white,
        popoverForeground: const Color(0xFF111827),

        // 静音色
        muted: const Color(0xFFF9FAFB),
        mutedForeground: const Color(0xFF6B7280),

        // 强调色
        accent: const Color(0xFFF3F4F6),
        accentForeground: const Color(0xFF111827),

        // 警告色
        destructive: const Color(0xFFEF4444),
        destructiveForeground: Colors.white,

        // 边框
        border: const Color(0xFFE5E7EB),

        // 输入框
        input: const Color(0xFFE5E7EB),

        // 选择色
        selection: const Color(0xFF007AFF).withOpacity(0.2),

        // 环状色
        ring: const Color(0xFF007AFF),
      ),
    );
  }

  /// 获取暗色主题
  static ShadThemeData get darkTheme {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: ShadColorScheme(
        // 主色
        primary: const Color(0xFF3B82F6),
        primaryForeground: Colors.white,

        // 次要色
        secondary: const Color(0xFF9CA3AF),
        secondaryForeground: Colors.white,

        // 背景色
        background: const Color(0xFF111827),
        foreground: Colors.white,

        // 卡片
        card: const Color(0xFF1F2937),
        cardForeground: Colors.white,

        // 弹出框
        popover: const Color(0xFF1F2937),
        popoverForeground: Colors.white,

        // 静音色
        muted: const Color(0xFF1F2937),
        mutedForeground: const Color(0xFF9CA3AF),

        // 强调色
        accent: const Color(0xFF374151),
        accentForeground: Colors.white,

        // 警告色
        destructive: const Color(0xFFEF4444),
        destructiveForeground: Colors.white,

        // 边框
        border: const Color(0xFF374151),

        // 输入框
        input: const Color(0xFF374151),

        // 选择色
        selection: const Color(0xFF3B82F6).withOpacity(0.2),

        // 环状色
        ring: const Color(0xFF3B82F6),
      ),
    );
  }

  /// 创建ShadApp
  static ShadApp createShadApp({
    required Widget home,
    ThemeMode themeMode = ThemeMode.system,
  }) {
    return ShadApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: home,
    );
  }

  /// 创建带MaterialApp的ShadApp
  static ShadApp createShadAppWithMaterial({
    required Widget home,
    ThemeMode themeMode = ThemeMode.system,
  }) {
    return ShadApp.custom(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      appBuilder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
          home: home,
        );
      },
    );
  }

  /// 创建带GetMaterialApp的ShadApp
  static ShadApp createShadAppWithGetX({
    required Widget home,
    ThemeMode themeMode = ThemeMode.system,
    List<dynamic>? pages,
    String initialRoute = '/',
  }) {
    return ShadApp.custom(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      appBuilder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
          home: home,
        );
      },
    );
  }
}

/// Shadcn UI 工具扩展
extension ShadcnThemeExtension on BuildContext {
  /// 获取Shad主题
  ShadThemeData get shadTheme => ShadTheme.of(this);

  /// 获取颜色方案
  ShadColorScheme get shadColors => shadTheme.colorScheme;

  /// 是否是暗色模式
  bool get isShadDarkMode => shadTheme.brightness == Brightness.dark;

  /// 显示Shadcn风格的Snackbar
  void showShadSnackbar(String message, {String title = '提示'}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 显示Shadcn风格的对话框
  Future<T?> showShadDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return Dialog(
          backgroundColor: shadColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
    );
  }
}

/// Shadcn UI 样式常量
class ShadcnStyles {
  /// 边框半径
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  /// 间距
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  /// 阴影
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.15),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// 动画持续时间
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

/// Shadcn UI 文本样式
class ShadcnTextStyles {
  /// 大标题
  static TextStyle displayLarge(BuildContext context) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: context.shadColors.foreground,
      height: 1.2,
    );
  }

  /// 标题
  static TextStyle displayMedium(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: context.shadColors.foreground,
      height: 1.3,
    );
  }

  /// 小标题
  static TextStyle displaySmall(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: context.shadColors.foreground,
      height: 1.4,
    );
  }

  /// 正文大
  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: context.shadColors.foreground,
      height: 1.5,
    );
  }

  /// 正文
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: context.shadColors.foreground,
      height: 1.5,
    );
  }

  /// 正文小
  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: context.shadColors.mutedForeground,
      height: 1.5,
    );
  }

  /// 标签
  static TextStyle labelMedium(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: context.shadColors.mutedForeground,
      height: 1.5,
    );
  }
}
