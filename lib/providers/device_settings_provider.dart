import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Override in ProviderScope or initialize asynchronously
});

final deviceSettingsProvider = Provider<DeviceSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DeviceSettingsService(prefs);
});

// A provider to manage the currently active filter on the home screen.
// Null means "All". Resets to null on app restart.
final activeHomeFilterProvider = StateProvider<String?>((ref) => null);

// A provider that exposes the current list of filter wallet IDs from SharedPreferences
final homeFilterWalletIdsProvider = StateNotifierProvider<HomeFilterWalletIdsNotifier, List<String>>((ref) {
  final service = ref.watch(deviceSettingsProvider);
  return HomeFilterWalletIdsNotifier(service);
});

class HomeFilterWalletIdsNotifier extends StateNotifier<List<String>> {
  final DeviceSettingsService _service;

  HomeFilterWalletIdsNotifier(this._service) : super(_service.getHomeFilterWalletIds());

  Future<void> addWalletId(String id) async {
    final current = state.toList();
    if (!current.contains(id)) {
      current.add(id);
      await _service.setHomeFilterWalletIds(current);
      state = current;
    }
  }

  Future<void> removeWalletId(String id) async {
    final current = state.toList();
    if (current.remove(id)) {
      await _service.setHomeFilterWalletIds(current);
      state = current;
    }
  }

  Future<void> clear() async {
    await _service.setHomeFilterWalletIds([]);
    state = [];
  }
}

// A provider for the default wallet ID
final defaultWalletIdProvider = StateNotifierProvider<DefaultWalletIdNotifier, String?>((ref) {
  final service = ref.watch(deviceSettingsProvider);
  return DefaultWalletIdNotifier(service);
});

class DefaultWalletIdNotifier extends StateNotifier<String?> {
  final DeviceSettingsService _service;

  DefaultWalletIdNotifier(this._service) : super(_service.getDefaultWalletId());

  Future<void> setDefaultWalletId(String? id) async {
    await _service.setDefaultWalletId(id);
    state = id;
  }
}

class DeviceSettingsService {
  final SharedPreferences _prefs;

  DeviceSettingsService(this._prefs);

  static const String _defaultWalletIdKey = 'defaultWalletId';
  static const String _homeFilterWalletIdsKey = 'homeFilterWalletIds';
  static const String _themeModeKey = 'themeMode';

  String? getDefaultWalletId() {
    return _prefs.getString(_defaultWalletIdKey);
  }

  Future<void> setDefaultWalletId(String? id) async {
    if (id == null) {
      await _prefs.remove(_defaultWalletIdKey);
    } else {
      await _prefs.setString(_defaultWalletIdKey, id);
    }
  }

  List<String> getHomeFilterWalletIds() {
    return _prefs.getStringList(_homeFilterWalletIdsKey) ?? [];
  }

  Future<void> setHomeFilterWalletIds(List<String> ids) async {
    await _prefs.setStringList(_homeFilterWalletIdsKey, ids);
  }

  String? getThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode);
  }
}
