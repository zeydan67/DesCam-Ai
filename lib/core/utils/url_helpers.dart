class UrlHelpers {
  UrlHelpers._();

  /// Returns true if [text] looks like a URL (starts with http, contains ://, or www.).
  static bool isUrl(String? text) {
    if (text == null) return false;
    final t = text.trim().toLowerCase();
    return t.startsWith('http') || t.contains('://') || t.contains('www.');
  }
}
