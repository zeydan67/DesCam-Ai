import 'package:flutter/foundation.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = 'id';
  String get lang => _lang;
  void toggle() {
    _lang = _lang == 'id' ? 'en' : 'id';
    notifyListeners();
  }
}