import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waspadaai/core/models/analysis_result.dart';
import 'package:waspadaai/core/services/analysis_service.dart';
import 'package:waspadaai/providers/analysis_provider.dart';

/// Deterministic in-memory [AnalysisService] used to drive the provider
/// without touching the network.
class _FakeAnalysisService implements AnalysisService {
  _FakeAnalysisService({
    this.mock = true,
    AnalysisResult? result,
    this.error,
  }) : _result = result ??
            const AnalysisResult(
              level: ThreatLevel.safe,
              explanation: 'ok',
              confidence: 0.8,
              category: 'Test',
              tips: [],
            );

  final bool mock;
  final Object? error;
  final AnalysisResult _result;
  int analyzeCalls = 0;

  @override
  bool get isMock => mock;

  @override
  Future<AnalysisResult> analyze({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async {
    analyzeCalls++;
    if (error != null) throw error!;
    return _result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Provide a fresh trending cache so the provider constructor never hits
    // the network during tests.
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'trending_rss_time_v4': now,
      'trending_rss_v4': jsonEncode([
        {
          'id': 't1',
          'title': 'Cached threat',
          'description': 'desc',
          'severity': 'high',
          'category': 'Phishing',
          'report_count': 10,
          'image_url': null,
          'article_url': null,
        },
      ]),
    });
  });

  test('starts in the idle state', () {
    final provider = AnalysisProvider(_FakeAnalysisService());

    expect(provider.state, AnalysisState.idle);
    expect(provider.result, isNull);
    expect(provider.errorMessage, isNull);
  });

  test('exposes the service mock flag', () {
    expect(AnalysisProvider(_FakeAnalysisService(mock: true)).isMockService,
        isTrue);
    expect(AnalysisProvider(_FakeAnalysisService(mock: false)).isMockService,
        isFalse);
  });

  group('analyze', () {
    test('does nothing when text is empty and no file is supplied', () async {
      final svc = _FakeAnalysisService();
      final provider = AnalysisProvider(svc);

      await provider.analyze(type: 'Text', text: '   ');

      expect(svc.analyzeCalls, 0);
      expect(provider.state, AnalysisState.idle);
    });

    test('stores the result on success', () async {
      const expected = AnalysisResult(
        level: ThreatLevel.danger,
        explanation: 'bad',
        confidence: 0.9,
        category: 'Scam',
        tips: [],
      );
      final provider = AnalysisProvider(
        _FakeAnalysisService(result: expected),
      );

      await provider.analyze(type: 'Text', text: 'something');

      expect(provider.state, AnalysisState.success);
      expect(provider.result, same(expected));
      expect(provider.errorMessage, isNull);
    });

    test('captures the error message on failure', () async {
      final provider = AnalysisProvider(
        _FakeAnalysisService(error: Exception('boom')),
      );

      await provider.analyze(type: 'Text', text: 'something');

      expect(provider.state, AnalysisState.error);
      expect(provider.result, isNull);
      expect(provider.errorMessage, contains('boom'));
    });

    test('runs when only file bytes are supplied', () async {
      final svc = _FakeAnalysisService();
      final provider = AnalysisProvider(svc);

      await provider.analyze(
        type: 'File',
        fileBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(svc.analyzeCalls, 1);
      expect(provider.state, AnalysisState.success);
    });
  });

  test('reset returns the provider to idle', () async {
    final provider = AnalysisProvider(_FakeAnalysisService());
    await provider.analyze(type: 'Text', text: 'something');
    expect(provider.state, AnalysisState.success);

    provider.reset();

    expect(provider.state, AnalysisState.idle);
    expect(provider.result, isNull);
    expect(provider.errorMessage, isNull);
  });
}
