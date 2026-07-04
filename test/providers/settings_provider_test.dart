import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waspadaai/core/config/app_config.dart';
import 'package:waspadaai/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    test('defaults to using the built-in Gemini key', () {
      final provider = SettingsProvider();

      expect(provider.useDefault, isTrue);
      expect(provider.customKey, '');
      expect(provider.vtApiKey, '');
      expect(provider.activeApiKey, AppConfig.defaultGeminiApiKey);
    });

    group('activeApiKey', () {
      test('uses the custom key when useDefault is disabled', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = SettingsProvider();

        await provider.setCustomKey('AIzaCustomKeyValue0000000000');
        await provider.setUseDefault(false);

        expect(provider.activeApiKey, 'AIzaCustomKeyValue0000000000');
      });

      test('falls back to the default key when the custom key is blank',
          () async {
        SharedPreferences.setMockInitialValues({});
        final provider = SettingsProvider();

        await provider.setUseDefault(false);
        await provider.setCustomKey('   ');

        expect(provider.activeApiKey, AppConfig.defaultGeminiApiKey);
      });
    });

    group('loadSettings', () {
      test('reads persisted values', () async {
        SharedPreferences.setMockInitialValues({
          'use_default_api_key': false,
          'custom_api_key': 'AIzaStoredKey00000000000000',
          'vt_api_key': 'vt-stored-key',
        });
        final provider = SettingsProvider();

        await provider.loadSettings();

        expect(provider.useDefault, isFalse);
        expect(provider.customKey, 'AIzaStoredKey00000000000000');
        expect(provider.vtApiKey, 'vt-stored-key');
      });

      test('applies defaults when nothing is persisted', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = SettingsProvider();

        await provider.loadSettings();

        expect(provider.useDefault, isTrue);
        expect(provider.customKey, '');
        expect(provider.vtApiKey, '');
      });
    });

    group('setters persist and notify', () {
      test('setVtKey stores the VirusTotal key', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = SettingsProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.setVtKey('my-vt-key');

        expect(provider.vtApiKey, 'my-vt-key');
        expect(notified, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('vt_api_key'), 'my-vt-key');
      });

      test('setUseDefault stores the flag', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = SettingsProvider();

        await provider.setUseDefault(false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('use_default_api_key'), isFalse);
      });
    });
  });
}
