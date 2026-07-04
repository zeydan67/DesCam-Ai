import 'package:flutter_test/flutter_test.dart';
import 'package:waspadaai/core/models/analysis_result.dart';

void main() {
  group('AnalysisResult.fromJson', () {
    test('parses a complete JSON payload', () {
      final result = AnalysisResult.fromJson({
        'level': 'danger',
        'confidence': 0.9,
        'category': 'Penipuan',
        'explanation': 'Ini penipuan.',
        'tips': ['Tip A', 'Tip B'],
      });

      expect(result.level, ThreatLevel.danger);
      expect(result.category, 'Penipuan');
      expect(result.explanation, 'Ini penipuan.');
      expect(result.tips, ['Tip A', 'Tip B']);
      expect(result.sourceLinks, isEmpty);
      expect(result.legalAnalysis, isNull);
    });

    test('applies sensible defaults for missing fields', () {
      final result = AnalysisResult.fromJson(<String, dynamic>{});

      // Unknown level defaults to suspicious.
      expect(result.level, ThreatLevel.suspicious);
      expect(result.explanation, '');
      expect(result.category, 'Unknown');
      expect(result.tips, isEmpty);
      expect(result.sourceLinks, isEmpty);
      expect(result.legalAnalysis, isNull);
    });

    test('keeps provided sourceLinks', () {
      const links = [
        SourceLink(title: 'Kompas', url: 'https://kompas.com'),
      ];
      final result = AnalysisResult.fromJson(
        {'level': 'safe', 'confidence': 0.8},
        sourceLinks: links,
      );

      expect(result.sourceLinks, hasLength(1));
      expect(result.sourceLinks.first.title, 'Kompas');
      expect(result.sourceLinks.first.url, 'https://kompas.com');
    });

    group('level parsing', () {
      test('maps "safe" (case-insensitive) to ThreatLevel.safe', () {
        expect(
          AnalysisResult.fromJson({'level': 'SAFE'}).level,
          ThreatLevel.safe,
        );
      });

      test('maps "danger" to ThreatLevel.danger', () {
        expect(
          AnalysisResult.fromJson({'level': 'Danger'}).level,
          ThreatLevel.danger,
        );
      });

      test('maps unknown/null level to ThreatLevel.suspicious', () {
        expect(
          AnalysisResult.fromJson({'level': 'gibberish'}).level,
          ThreatLevel.suspicious,
        );
        expect(
          AnalysisResult.fromJson({'level': null}).level,
          ThreatLevel.suspicious,
        );
      });
    });

    group('confidence calibration', () {
      test('clamps danger confidence into [0.55, 0.95]', () {
        expect(
          AnalysisResult.fromJson({'level': 'danger', 'confidence': 0.1})
              .confidence,
          0.55,
        );
        expect(
          AnalysisResult.fromJson({'level': 'danger', 'confidence': 1.0})
              .confidence,
          0.95,
        );
      });

      test('clamps safe confidence into [0.50, 0.95]', () {
        expect(
          AnalysisResult.fromJson({'level': 'safe', 'confidence': 0.0})
              .confidence,
          0.50,
        );
      });

      test('clamps suspicious confidence into [0.40, 0.80]', () {
        expect(
          AnalysisResult.fromJson({'level': 'suspicious', 'confidence': 0.99})
              .confidence,
          0.80,
        );
        expect(
          AnalysisResult.fromJson({'level': 'suspicious', 'confidence': 0.1})
              .confidence,
          0.40,
        );
      });

      test('unknown level falls back to [0.40, 0.90] clamp', () {
        expect(
          AnalysisResult.fromJson({'level': 'weird', 'confidence': 1.5})
              .confidence,
          0.90,
        );
        expect(
          AnalysisResult.fromJson({'level': 'weird', 'confidence': -1.0})
              .confidence,
          0.40,
        );
      });

      test('leaves an in-range value untouched', () {
        expect(
          AnalysisResult.fromJson({'level': 'danger', 'confidence': 0.7})
              .confidence,
          closeTo(0.7, 1e-9),
        );
      });

      test('treats a missing confidence as 0 before clamping', () {
        expect(
          AnalysisResult.fromJson({'level': 'danger'}).confidence,
          0.55,
        );
      });
    });

    group('legal_analysis', () {
      test('parses a nested legal_analysis object', () {
        final result = AnalysisResult.fromJson({
          'level': 'suspicious',
          'confidence': 0.6,
          'legal_analysis': {
            'document_type': 'Somasi',
            'summary': 'Ringkasan',
            'legal_status': 'perlu_dikaji',
            'impacts': ['Dampak 1'],
            'benefits': ['Hak 1'],
            'risks': ['Risiko 1'],
            'relevant_laws': ['Pasal 1'],
            'recommendation': 'Hubungi advokat',
          },
        });

        final legal = result.legalAnalysis;
        expect(legal, isNotNull);
        expect(legal!.documentType, 'Somasi');
        expect(legal.summary, 'Ringkasan');
        expect(legal.legalStatus, 'perlu_dikaji');
        expect(legal.impacts, ['Dampak 1']);
        expect(legal.benefits, ['Hak 1']);
        expect(legal.risks, ['Risiko 1']);
        expect(legal.relevantLaws, ['Pasal 1']);
        expect(legal.recommendation, 'Hubungi advokat');
      });

      test('ignores a non-map legal_analysis value', () {
        final result = AnalysisResult.fromJson({
          'level': 'safe',
          'legal_analysis': 'not-a-map',
        });
        expect(result.legalAnalysis, isNull);
      });
    });
  });

  group('LegalAnalysis.fromJson', () {
    test('applies defaults for missing fields', () {
      final legal = LegalAnalysis.fromJson(<String, dynamic>{});

      expect(legal.documentType, 'Dokumen Hukum');
      expect(legal.summary, '');
      expect(legal.legalStatus, 'perlu_dikaji');
      expect(legal.impacts, isEmpty);
      expect(legal.benefits, isEmpty);
      expect(legal.risks, isEmpty);
      expect(legal.relevantLaws, isEmpty);
      expect(legal.recommendation, '');
    });
  });
}
