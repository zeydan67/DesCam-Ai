import 'package:flutter_test/flutter_test.dart';
import 'package:waspadaai/providers/language_provider.dart';

void main() {
  group('LanguageProvider', () {
    test('defaults to Indonesian', () {
      expect(LanguageProvider().lang, 'id');
    });

    test('toggle switches between id and en', () {
      final provider = LanguageProvider();

      provider.toggle();
      expect(provider.lang, 'en');

      provider.toggle();
      expect(provider.lang, 'id');
    });

    test('notifies listeners on toggle', () {
      final provider = LanguageProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggle();
      provider.toggle();

      expect(notifications, 2);
    });
  });
}
