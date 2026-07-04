import 'package:flutter_test/flutter_test.dart';
import 'package:waspadaai/core/models/analysis_result.dart';
import 'package:waspadaai/core/services/mock_service.dart';

void main() {
  final service = MockAnalysisService();

  test('is flagged as a mock service', () {
    expect(service.isMock, isTrue);
  });

  group('MockAnalysisService.analyze', () {
    test('classifies legal documents by keyword', () async {
      final result = await service.analyze(
        type: 'Text',
        text: 'Saya menerima surat peringatan dari pengadilan',
      );

      expect(result.level, ThreatLevel.suspicious);
      expect(result.category, 'Dokumen Hukum');
      expect(result.legalAnalysis, isNotNull);
      expect(result.legalAnalysis!.documentType, 'Surat Peringatan (SP)');
      expect(result.tips, isNotEmpty);
    });

    test('classifies legal documents by type even without keyword', () async {
      final result = await service.analyze(type: 'Letter', text: 'apa saja');

      expect(result.category, 'Dokumen Hukum');
      expect(result.legalAnalysis, isNotNull);
    });

    test('flags prize/scam keywords as danger', () async {
      final result = await service.analyze(
        type: 'Text',
        text: 'Selamat anda menang hadiah, klik link ini',
      );

      expect(result.level, ThreatLevel.danger);
      expect(result.category, 'Penipuan Hadiah');
      expect(result.confidence, greaterThan(0.9));
      expect(result.legalAnalysis, isNull);
    });

    test('flags health hoax keywords as suspicious', () async {
      final result = await service.analyze(
        type: 'Text',
        text: 'Berita hoax tentang vaksin berbahaya',
      );

      expect(result.level, ThreatLevel.suspicious);
      expect(result.category, 'Hoaks Kesehatan');
    });

    test('treats neutral content as safe', () async {
      final result = await service.analyze(
        type: 'Text',
        text: 'Hari ini cuaca cerah di Jakarta',
      );

      expect(result.level, ThreatLevel.safe);
      expect(result.category, 'Konten Normal');
      expect(result.legalAnalysis, isNull);
    });

    test('treats null text as safe content', () async {
      final result = await service.analyze(type: 'Text');

      expect(result.level, ThreatLevel.safe);
      expect(result.category, 'Konten Normal');
    });

    test('keyword matching is case-insensitive', () async {
      final result = await service.analyze(
        type: 'Text',
        text: 'SOMASI RESMI',
      );

      expect(result.category, 'Dokumen Hukum');
    });
  });
}
