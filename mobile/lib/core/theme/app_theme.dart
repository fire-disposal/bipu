import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 应用主题配置
final appThemeProvider = NotifierProvider<AppThemeNotifier, ThemeData>(
  AppThemeNotifier.new,
);

class AppThemeNotifier extends Notifier<ThemeData> {
  @override
  ThemeData build() {
    return _createTheme(Brightness.light);
  }

  /// 切换亮色/暗色主题
  void toggleTheme() {
    final currentBrightness = state.brightness;
    final newBrightness = currentBrightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    state = _createTheme(newBrightness);
  }

  /// 获取当前主题的亮度
  Brightness get brightness => state.brightness;

  /// 创建主题
  ThemeData _createTheme(Brightness brightness) {
    return FlexColorScheme(
      brightness: brightness,
      colorScheme: brightness == Brightness.light
          ? const ColorScheme.light(
              primary: Color(0xFF1976D2),
              secondary: Color(0xFF03A9F4),
            )
          : const ColorScheme.dark(
              primary: Color(0xFF1976D2),
              secondary: Color(0xFF03A9F4),
            ),
      useMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      subThemesData: const FlexSubThemesData(
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 12.0,
        elevatedButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        textButtonRadius: 12.0,
        filledButtonRadius: 12.0,
        inputDecoratorRadius: 12.0,
        chipRadius: 12.0,
        cardRadius: 12.0,
        popupMenuRadius: 12.0,
        dialogRadius: 12.0,
        bottomSheetRadius: 12.0,
        timePickerDialogRadius: 12.0,
        snackBarRadius: 12.0,
        bottomNavigationBarElevation: 0,
      ),
    ).toTheme;
  }
}
