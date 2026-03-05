import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

const _themeKey = 'app_theme_mode';

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 0;
    state = AppThemeMode.values[index];
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> cycleTheme() async {
    final nextIndex = (state.index + 1) % AppThemeMode.values.length;
    await setTheme(AppThemeMode.values[nextIndex]);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);
