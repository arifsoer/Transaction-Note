import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final deviceSettings = ref.watch(deviceSettingsProvider);
  return ThemeModeNotifier(deviceSettings);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final DeviceSettingsService _deviceSettings;

  ThemeModeNotifier(this._deviceSettings) : super(_loadTheme(_deviceSettings));

  static ThemeMode _loadTheme(DeviceSettingsService service) {
    final savedTheme = service.getThemeMode();
    if (savedTheme == 'dark') {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  void toggleTheme() {
    final newTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newTheme;
    _deviceSettings.setThemeMode(newTheme == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
