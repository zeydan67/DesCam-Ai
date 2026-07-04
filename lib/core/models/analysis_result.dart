import 'package:flutter/foundation.dart';

enum ThreatLevel { safe, suspicious, danger }

// ─────────────────────────────────────────────────────────────
// Model untuk analisis dokumen hukum
// ─────────────────────────────────────────────────────────────
class LegalAnalysis {
  final String documentType;     // Jenis dokumen (SP, Somasi, Kontrak, dll)
  final String summary;          // Ringkasan isi
  final String legalStatus;      // 'valid', 'invalid', 'perlu_dikaji'
  final List<String> impacts;    // Dampak hukum
  final List<String> benefits;   // Keuntungan/Hak
  final List<String> risks;      // Risiko/Ancaman
  final List<String> relevantLaws; // Pasal/UU terkait
  final String recommendation;   // Rekomendasi tindakan

  const LegalAnalysis({
    required this.documentType,
    required this.summary,
    required this.legalStatus,
    required this.impacts,
    required this.benefits,
    required this.risks,
    required this.relevantLaws,
    required this.recommendation,
  });

  factory LegalAnalysis.fromJson(Map<String, dynamic> j) => LegalAnalysis(
    documentType  : j['document_type']  as String? ?? 'Dokumen Hukum',
    summary       : j['summary']        as String? ?? '',
    legalStatus   : j['legal_status']   as String? ?? 'perlu_dikaji',
    impacts       : List<String>.from(j['impacts']       as List? ?? []),
    benefits      : List<String>.from(j['benefits']      as List? ?? []),
    risks         : List<String>.from(j['risks']         as List? ?? []),
    relevantLaws  : List<String>.from(j['relevant_laws'] as List? ?? []),
    recommendation: j['recommendation'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────────
class SourceLink {
  final String title;
  final String url;
  const SourceLink({required this.title, required this.url});
}

class AnalysisResult {
  final ThreatLevel level;
  final String explanation;
  final double confidence;
  final String category;
  final List<String> tips;
  final List<SourceLink> sourceLinks;
  final LegalAnalysis? legalAnalysis; // null jika bukan dokumen hukum

  const AnalysisResult({
    required this.level,
    required this.explanation,
    required this.confidence,
    required this.category,
    required this.tips,
    this.sourceLinks = const [],
    this.legalAnalysis,
  });

  factory AnalysisResult.fromJson(
    Map<String, dynamic> j, {
    List<SourceLink> sourceLinks = const [],
  }) {
    LegalAnalysis? legal;
    if (j['legal_analysis'] != null &&
        j['legal_analysis'] is Map<String, dynamic>) {
      try {
        legal = LegalAnalysis.fromJson(
            j['legal_analysis'] as Map<String, dynamic>);
      } catch (e) {
        debugPrint('[DesCam] Failed to parse legal_analysis: $e');
      }
    }

    return AnalysisResult(
      level: _parseLevel(j['level'] as String?),
      explanation: j['explanation'] as String? ?? '',
      confidence: _calibrate(
        (j['confidence'] as num?)?.toDouble() ?? 0.0,
        j['level'] as String?,
      ),
      category: j['category'] as String? ?? 'Unknown',
      tips: List<String>.from(j['tips'] as List? ?? []),
      sourceLinks: sourceLinks,
      legalAnalysis: legal,
    );
  }

  static ThreatLevel _parseLevel(String? v) {
    switch (v?.toLowerCase()) {
      case 'safe':   return ThreatLevel.safe;
      case 'danger': return ThreatLevel.danger;
      default:       return ThreatLevel.suspicious;
    }
  }

  static double _calibrate(double raw, String? level) {
    final c = raw.clamp(0.0, 1.0);
    switch (level?.toLowerCase()) {
      case 'danger':     return c.clamp(0.55, 0.95);
      case 'safe':       return c.clamp(0.50, 0.95);
      case 'suspicious': return c.clamp(0.40, 0.80);
      default:           return c.clamp(0.40, 0.90);
    }
  }
}
