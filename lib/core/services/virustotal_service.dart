import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

enum UrlSafetyLevel { safe, suspicious, danger, unknown }

class UrlSafetyResult {
  final UrlSafetyLevel level;
  final String source;       // "VirusTotal" | "PhishTank" | "Unknown"
  final int maliciousCount;  // jumlah engine yang flag
  final int totalEngines;
  final String summary;      // teks ringkas untuk dikirim ke Gemini

  const UrlSafetyResult({
    required this.level,
    required this.source,
    this.maliciousCount = 0,
    this.totalEngines   = 0,
    required this.summary,
  });

  static const unknown = UrlSafetyResult(
    level: UrlSafetyLevel.unknown, source: 'Unknown',
    summary: 'Tidak ada data pra-pemeriksaan.',
  );
}

/// Pre-check URL & File sebelum Gemini → hemat token
/// Urutan: VirusTotal (jika ada key) → PhishTank (gratis) → unknown
class SafetyPreChecker {
  final String? vtApiKey; // VirusTotal key (optional)
  SafetyPreChecker({this.vtApiKey});

  bool get _hasVtKey =>
      vtApiKey != null &&
      vtApiKey!.isNotEmpty &&
      vtApiKey!.length > 20;

  Future<UrlSafetyResult> checkUrl(String url) async {
    // 1. VirusTotal (lebih akurat)
    if (_hasVtKey) {
      try {
        final vtResult = await _checkVirusTotalUrl(url);
        if (vtResult.level != UrlSafetyLevel.unknown) return vtResult;
      } catch (_) {}
    }

    // 2. PhishTank (gratis, tanpa API key)
    try {
      final ptResult = await _checkPhishTank(url);
      if (ptResult.level != UrlSafetyLevel.unknown) return ptResult;
    } catch (_) {}

    return UrlSafetyResult.unknown;
  }

  Future<UrlSafetyResult> checkFile(Uint8List bytes) async {
    if (!_hasVtKey) return UrlSafetyResult.unknown;

    try {
      // Hitung hash SHA-256
      final hash = sha256.convert(bytes).toString();
      
      final resp = await http.get(
        Uri.parse('https://www.virustotal.com/api/v3/files/$hash'),
        headers: {'x-apikey': vtApiKey!},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return UrlSafetyResult.unknown;

      final data  = jsonDecode(resp.body);
      final stats = data['data']?['attributes']?['last_analysis_stats'] as Map<String, dynamic>?;
      if (stats == null) return UrlSafetyResult.unknown;

      final malicious  = (stats['malicious']  as num?)?.toInt() ?? 0;
      final suspicious = (stats['suspicious'] as num?)?.toInt() ?? 0;
      final total      = stats.values.fold<int>(0, (s, v) => s + ((v as num?)?.toInt() ?? 0));

      final bad = malicious + suspicious;
      UrlSafetyLevel level;
      if (bad >= 3)       level = UrlSafetyLevel.danger;
      else if (bad >= 1)  level = UrlSafetyLevel.suspicious;
      else                level = UrlSafetyLevel.safe;

      return UrlSafetyResult(
        level          : level,
        source         : 'VirusTotal (File)',
        maliciousCount : bad,
        totalEngines   : total,
        summary        :
          'VirusTotal File Check: $bad/$total engine mendeteksi file ini sebagai '
          '${bad >= 3 ? "BERBAHAYA" : bad >= 1 ? "mencurigakan" : "AMAN"}.',
      );
    } catch (_) {
      return UrlSafetyResult.unknown;
    }
  }

  // ── VirusTotal v3 (URL) ──────────────────────────────────────────────────
  Future<UrlSafetyResult> _checkVirusTotalUrl(String url) async {
    // Encode URL ke base64 tanpa padding (format VT)
    final urlId = base64Url.encode(utf8.encode(url)).replaceAll('=', '');

    final resp = await http.get(
      Uri.parse('https://www.virustotal.com/api/v3/urls/$urlId'),
      headers: {'x-apikey': vtApiKey!},
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 404) {
      // URL belum pernah di-scan VT → submit untuk scan
      await http.post(
        Uri.parse('https://www.virustotal.com/api/v3/urls'),
        headers: {
          'x-apikey': vtApiKey!,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'url=${Uri.encodeComponent(url)}',
      ).timeout(const Duration(seconds: 10));
      return UrlSafetyResult.unknown;
    }

    if (resp.statusCode != 200) return UrlSafetyResult.unknown;

    final data  = jsonDecode(resp.body);
    final stats = data['data']?['attributes']?['last_analysis_stats']
        as Map<String, dynamic>?;
    if (stats == null) return UrlSafetyResult.unknown;

    final malicious  = (stats['malicious']  as num?)?.toInt() ?? 0;
    final suspicious = (stats['suspicious'] as num?)?.toInt() ?? 0;
    final total      = (stats.values.fold<int>(0, (s, v) => s + ((v as num?)?.toInt() ?? 0)));

    final bad = malicious + suspicious;
    UrlSafetyLevel level;
    if (bad >= 5)       level = UrlSafetyLevel.danger;
    else if (bad >= 1)  level = UrlSafetyLevel.suspicious;
    else                level = UrlSafetyLevel.safe;

    return UrlSafetyResult(
      level          : level,
      source         : 'VirusTotal',
      maliciousCount : bad,
      totalEngines   : total,
      summary        :
        'VirusTotal: $bad/$total engine menandai URL ini sebagai '
        '${bad >= 5 ? "BERBAHAYA" : bad >= 1 ? "mencurigakan" : "AMAN"}.',
    );
  }

  // ── PhishTank (gratis, no key needed) ─────────────────────────────────────
  Future<UrlSafetyResult> _checkPhishTank(String url) async {
    final resp = await http.post(
      Uri.parse('https://checkurl.phishtank.com/checkurl/'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent'  : 'phishtank/WaspadaAI',
      },
      body: {
        'url'    : base64Encode(utf8.encode(url)),
        'format' : 'json',
      },
    ).timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return UrlSafetyResult.unknown;

    final data    = jsonDecode(resp.body);
    final results = data['results'] as Map<String, dynamic>?;
    if (results == null) return UrlSafetyResult.unknown;

    final inDatabase = results['in_database'] as bool? ?? false;
    final valid      = results['valid']       as bool? ?? false;

    if (!inDatabase) return UrlSafetyResult.unknown;

    return UrlSafetyResult(
      level          : valid ? UrlSafetyLevel.danger : UrlSafetyLevel.suspicious,
      source         : 'PhishTank',
      maliciousCount : valid ? 1 : 0,
      totalEngines   : 1,
      summary        : valid
          ? 'PhishTank: URL ini TERDAFTAR sebagai situs phishing aktif.'
          : 'PhishTank: URL ada di database tapi belum dikonfirmasi phishing.',
    );
  }
}
