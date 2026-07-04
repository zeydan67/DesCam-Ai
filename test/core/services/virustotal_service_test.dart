import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waspadaai/core/services/virustotal_service.dart';

void main() {
  group('UrlSafetyResult', () {
    test('unknown constant has expected defaults', () {
      const unknown = UrlSafetyResult.unknown;

      expect(unknown.level, UrlSafetyLevel.unknown);
      expect(unknown.source, 'Unknown');
      expect(unknown.maliciousCount, 0);
      expect(unknown.totalEngines, 0);
      expect(unknown.summary, isNotEmpty);
    });

    test('constructor stores provided values', () {
      const result = UrlSafetyResult(
        level: UrlSafetyLevel.danger,
        source: 'VirusTotal',
        maliciousCount: 7,
        totalEngines: 70,
        summary: 'berbahaya',
      );

      expect(result.level, UrlSafetyLevel.danger);
      expect(result.source, 'VirusTotal');
      expect(result.maliciousCount, 7);
      expect(result.totalEngines, 70);
      expect(result.summary, 'berbahaya');
    });
  });

  group('SafetyPreChecker.checkFile', () {
    test('returns unknown when no VirusTotal key is configured', () async {
      final checker = SafetyPreChecker();
      final result = await checker.checkFile(Uint8List.fromList([1, 2, 3]));

      expect(result, same(UrlSafetyResult.unknown));
    });

    test('returns unknown when the key is too short to be valid', () async {
      final checker = SafetyPreChecker(vtApiKey: 'short-key');
      final result = await checker.checkFile(Uint8List.fromList([1, 2, 3]));

      expect(result, same(UrlSafetyResult.unknown));
    });

    test('treats an empty key as missing', () async {
      final checker = SafetyPreChecker(vtApiKey: '');
      final result = await checker.checkFile(Uint8List.fromList([9]));

      expect(result.level, UrlSafetyLevel.unknown);
    });
  });
}
