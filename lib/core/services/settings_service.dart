import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static const String _profileKey = 'user_profile';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  Future<void> saveSettings(Map<String, bool> settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, bool> getSettings() {
    final String? settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson == null) {
      return {
        'pushNotifications': true,
        'locationServices': true,
        'darkMode': false,
      };
    }
    return Map<String, bool>.from(jsonDecode(settingsJson));
  }

  Future<void> saveProfileInfo(Map<String, dynamic> profileInfo) async {
    await _prefs.setString(_profileKey, jsonEncode(profileInfo));
  }

  Map<String, dynamic> getProfileInfo() {
    final String? profileJson = _prefs.getString(_profileKey);
    if (profileJson == null) {
      return {
        'name': '',
        'email': '',
        'phone': '',
        'carModel': '',
        'carBrand': '',
      };
    }
    return Map<String, dynamic>.from(jsonDecode(profileJson));
  }
}
