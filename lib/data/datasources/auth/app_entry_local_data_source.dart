import 'package:shared_preferences/shared_preferences.dart';

class AppEntryLocalDataSource {
  static const resolvedEntryModeKey = 'appEntryResolvedMode';

  final SharedPreferences _preferences;

  const AppEntryLocalDataSource(this._preferences);

  String? readResolvedEntryMode() {
    return _preferences.getString(resolvedEntryModeKey);
  }

  Future<void> persistResolvedEntryMode(String resolvedMode) {
    return _preferences.setString(resolvedEntryModeKey, resolvedMode);
  }

  Future<void> clearResolvedEntryMode() {
    return _preferences.remove(resolvedEntryModeKey);
  }
}
