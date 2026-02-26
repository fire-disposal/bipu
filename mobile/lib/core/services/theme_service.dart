import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'theme_mode';
  static const String _boxName = 'settings';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final themeString = box.get(_themeKey) as String?;
    if (themeString != null) {
      try {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeString,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      } catch (_) {
        // Ignore error, default to system
      }
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, mode.toString());
  }
}
