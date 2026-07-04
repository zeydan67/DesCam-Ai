import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waspadaai/core/models/trending_threat.dart';
import 'package:waspadaai/core/services/trending_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cacheKey = 'trending_rss_v4';
  const cacheTimeKey = 'trending_rss_time_v4';

  Map<String, dynamic> cachedItem({
    String id = 'c1',
    String title = 'Judul Ancaman',
    String severity = 'high',
  }) =>
      {
        'id': id,
        'title': title,
        'description': 'Deskripsi ancaman',
        'severity': severity,
        'category': 'Phishing',
        'report_count': 1234,
        'image_url': 'https://example.com/img.png',
        'article_url': 'https://example.com/article',
      };

  group('getFallback', () {
    test('returns a non-empty, well-formed static list', () {
      final fallback = TrendingThreatService.getFallback();

      expect(fallback, isNotEmpty);
      for (final threat in fallback) {
        expect(threat.id, isNotEmpty);
        expect(threat.title, isNotEmpty);
        expect(threat.severity, isA<Severity>());
        expect(threat.reportCount, greaterThanOrEqualTo(0));
      }
    });
  });

  group('fetch (cache path)', () {
    test('returns cached data when the cache is still fresh', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        cacheTimeKey: now,
        cacheKey: jsonEncode([
          cachedItem(id: 'c1', severity: 'high'),
          cachedItem(id: 'c2', title: 'Kedua', severity: 'medium'),
        ]),
      });

      final threats = await TrendingThreatService().fetch();

      expect(threats, hasLength(2));
      expect(threats.first.id, 'c1');
      expect(threats.first.severity, Severity.high);
      expect(threats[1].severity, Severity.medium);
    });

    test('parses each cached severity value correctly', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        cacheTimeKey: now,
        cacheKey: jsonEncode([
          cachedItem(id: 'low', severity: 'low'),
          cachedItem(id: 'med', severity: 'medium'),
          cachedItem(id: 'high', severity: 'high'),
          cachedItem(id: 'other', severity: 'unrecognised'),
        ]),
      });

      final threats = await TrendingThreatService().fetch();
      final bySeverity = {for (final t in threats) t.id: t.severity};

      expect(bySeverity['low'], Severity.low);
      expect(bySeverity['med'], Severity.medium);
      expect(bySeverity['high'], Severity.high);
      // Unknown severity strings fall back to low.
      expect(bySeverity['other'], Severity.low);
    });

    test('preserves optional cached fields', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        cacheTimeKey: now,
        cacheKey: jsonEncode([cachedItem()]),
      });

      final threat = (await TrendingThreatService().fetch()).single;

      expect(threat.imageUrl, 'https://example.com/img.png');
      expect(threat.articleUrl, 'https://example.com/article');
      expect(threat.category, 'Phishing');
      expect(threat.reportCount, 1234);
    });
  });
}
