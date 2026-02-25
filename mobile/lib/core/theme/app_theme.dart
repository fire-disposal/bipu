import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// 应用主题配置
final appTheme = _createTheme(Brightness.light);

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
