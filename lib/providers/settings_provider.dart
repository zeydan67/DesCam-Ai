import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _useDefaultKey = 'use_default_api_key';
  static const String _customApiKey = 'custom_api_key';

  bool _useDefault = true;
  String _customKey = '';
  String _vtKey = '';

  bool get useDefault => _useDefault;
  String get customKey => _customKey;
  String get vtApiKey  => _vtKey;

  String get activeApiKey {
    if (_useDefault || _customKey.trim().isEmpty) {
      return AppConfig.defaultGeminiApiKey;
    }
    return _customKey;
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useDefault = prefs.getBool(_useDefaultKey) ?? true;
      _customKey  = prefs.getString(_customApiKey) ?? '';
      _vtKey      = prefs.getString('vt_api_key') ?? '';
    } catch (e) {
      debugPrint('[DesCam] Failed to load settings: $e');
    }
    notifyListeners();
  }

  Future<void> setUseDefault(bool val) async {
    _useDefault = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useDefaultKey, val);
    } catch (e) {
      debugPrint('[DesCam] Failed to persist useDefault setting: $e');
    }
  }

  Future<void> setCustomKey(String val) async {
    _customKey = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customApiKey, val);
    } catch (e) {
      debugPrint('[DesCam] Failed to persist custom API key: $e');
    }
  }

  Future<void> setVtKey(String val) async {
    _vtKey = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vt_api_key', val);
    } catch (e) {
      debugPrint('[DesCam] Failed to persist VirusTotal key: $e');
    }
  }
}
