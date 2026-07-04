import 'package:flutter_test/flutter_test.dart';
import 'package:waspadaai/core/constants/app_strings.dart';

void main() {
  group('AppStrings.get', () {
    test('returns the Indonesian string for a known key', () {
      expect(AppStrings.get('safe', 'id'), 'AMAN');
      expect(AppStrings.get('danger', 'id'), 'BAHAYA');
    });

    test('returns the English string for a known key', () {
      expect(AppStrings.get('safe', 'en'), 'SAFE');
      expect(AppStrings.get('danger', 'en'), 'DANGER');
    });

    test('falls back to English when the language is not available', () {
      // 'fr' has no entry, so the English value is used.
      expect(AppStrings.get('safe', 'fr'), 'SAFE');
    });

    test('returns the key itself when the key is unknown', () {
      expect(AppStrings.get('nonexistent_key', 'id'), 'nonexistent_key');
    });
  });
}
