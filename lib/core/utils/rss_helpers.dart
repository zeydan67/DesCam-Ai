import 'package:xml/xml.dart';
import '../constants/rss_constants.dart';

class RssHelpers {
  RssHelpers._();

  /// Extract text content from an XML element by tag name, cleaning CDATA.
  static String extractText(XmlElement element, String tag) {
    try {
      final found = element.findElements(tag).firstOrNull;
      if (found == null) return '';
      return cleanCdata(found.innerText.trim());
    } catch (_) {
      return '';
    }
  }

  /// Remove CDATA markers from a string.
  static String cleanCdata(String s) =>
      s.replaceAll('<![CDATA[', '').replaceAll(']]>', '').trim();

  /// Strip HTML tags and collapse whitespace.
  static String stripHtml(String html) =>
      html
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  /// Pick a deterministic fallback image based on a title hash.
  static String fallbackImageForTitle(String? title) {
    final hash = (title ?? '').hashCode.abs();
    return RssConstants.fallbackImages[hash % RssConstants.fallbackImages.length];
  }

  /// Deduplicate items by a key derived from their title prefix.
  static List<T> deduplicateByTitle<T>(
    List<T> items,
    String Function(T) titleGetter, {
    int prefixLength = 20,
    int? maxItems,
  }) {
    final seen = <String>{};
    final result = <T>[];
    for (final item in items) {
      final title = titleGetter(item);
      final key = title.toLowerCase().substring(
            0,
            title.length.clamp(0, prefixLength),
          );
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(item);
      }
    }
    return maxItems != null ? result.take(maxItems).toList() : result;
  }

  /// Build a CORS-proxied URL for fetching RSS feeds.
  static String proxiedUrl(String feedUrl) =>
      '${RssConstants.corsProxy}${Uri.encodeComponent(feedUrl)}';

  /// Parse RFC 822 / RFC 1123 date strings commonly found in RSS feeds.
  static DateTime parseRssDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      return _parseHttpDate(s);
    } catch (_) {}
    return DateTime.now();
  }

  static DateTime _parseHttpDate(String s) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.trim().split(RegExp(r'[\s,]+'));
    final day = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year = int.parse(parts[3]);
    final time = parts[4].split(':');
    return DateTime.utc(
        year, month, day, int.parse(time[0]), int.parse(time[1]));
  }
}
