import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/analysis_result.dart';
import 'analysis_service.dart';
import 'virustotal_service.dart';

class GeminiAnalysisService implements AnalysisService {
  final String apiKey;
  final String? vtApiKey;
  GeminiAnalysisService({required this.apiKey, this.vtApiKey});

  @override
  bool get isMock => false;

  static final Map<String, AnalysisResult> _cache = {};
  static const int _maxCache = 30;
  String _cacheKey(String type, String? text) =>
      '$type|${(text ?? '').trim().toLowerCase()}';

  bool get _isKeyInvalid =>
      apiKey.isEmpty || apiKey == 'YOUR_API_KEY' ||
      apiKey.contains('ISI_API_KEY') || apiKey.length < 20;

  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
  ];

  bool _isUrl(String? text) {
    if (text == null) return false;
    final t = text.trim().toLowerCase();
    return t.startsWith('http') || t.contains('://') || t.contains('www.');
  }

  bool _isLegalDocument(String? text, String type) {
    if (type == 'Letter') return true;
    if (text == null) return false;
    final lo = text.toLowerCase();
    return ['surat peringatan','somasi','sp1','sp2','sp3','kontrak',
      'perjanjian','akta','notaris','gugatan','tuntutan','putusan',
      'pengadilan','kuasa hukum','pengacara','wanprestasi','ganti rugi',
      'pasal ','undang-undang','kuhp','kuhperdata',
    ].any((k) => lo.contains(k));
  }

  @override
  Future<AnalysisResult> analyze({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async {
    // ── 0. Analisis Heuristik Lokal (Sangat Cepat & Tanpa Quota) ───────────
    final localResult = _localHeuristicAnalysis(
      type: type,
      text: text,
      fileBytes: fileBytes,
      mimeType: mimeType,
      fileName: fileName,
    );
    if (localResult != null) return localResult;

    if (_isKeyInvalid) {
      throw Exception(
        'API Key Gemini belum diatur.\n\n'
        '👉 Buka ⚙️ Pengaturan → masukkan key (AIza...) → tekan ✅',
      );
    }

    // Cache check
    if (fileBytes == null && text != null) {
      final key = _cacheKey(type, text);
      if (_cache.containsKey(key)) return _cache[key]!;
    }

    // ── Pre-check Keamanan (VirusTotal / PhishTank) ───────────────────────
    String preCheckNote = '';
    final checker = SafetyPreChecker(vtApiKey: vtApiKey);

    // 1. Check URL
    if (_isUrl(text) && fileBytes == null) {
      try {
        final vtResult = await checker.checkUrl(text!.trim());
        if (vtResult.level == UrlSafetyLevel.danger) {
          return AnalysisResult(
            level: ThreatLevel.danger,
            confidence: 0.99,
            category: 'Tautan Phishing / Penipuan Situs',
            explanation: 'Tautan "${text!.trim()}" terdeteksi berbahaya berdasarkan basis data keamanan VirusTotal / PhishTank. '
                'Situs ini secara aktif diidentifikasi sebagai sarana penipuan (phishing) atau penyebaran malware.',
            tips: [
              'JANGAN klik link tersebut atau memasukkan informasi sensitif apa pun.',
              'Tutup halaman web tersebut segera jika Anda terlanjur membukanya.',
              'Laporkan link ini ke Kominfo (via aduankonten.id) atau cekrekening.id.',
            ],
          );
        } else if (vtResult.level == UrlSafetyLevel.suspicious) {
          return AnalysisResult(
            level: ThreatLevel.suspicious,
            confidence: 0.85,
            category: 'Tautan Mencurigakan',
            explanation: 'Tautan "${text!.trim()}" diidentifikasi mencurigakan oleh pemindai keamanan global. '
                'Domain ini tergolong berisiko tinggi karena ketidakcocokan sertifikat, usia domain baru, atau reputasi buruk.',
            tips: [
              'Berhati-hatilah dan jangan pernah mengisi formulir kata sandi atau OTP di dalam situs.',
              'Verifikasi kredibilitas domain situs secara mandiri.',
              'Jangan bagikan tautan ini ke grup chat atau kerabat Anda.',
            ],
          );
        } else if (vtResult.level == UrlSafetyLevel.safe) {
          preCheckNote = '\n\n== DATA PRE-CHECK URL (Prioritaskan ini) ==\n'
              '${vtResult.summary}\n'
              'Gunakan data ini sebagai sinyal utama.\n';
        }
      } catch (_) {}
    }

    // 2. Check File Hash (VirusTotal)
    if (fileBytes != null) {
      try {
        final vtFileResult = await checker.checkFile(fileBytes);
        if (vtFileResult.level == UrlSafetyLevel.danger) {
          return AnalysisResult(
            level: ThreatLevel.danger,
            confidence: 0.98,
            category: 'Malware / Berbahaya Terdeteksi',
            explanation: 'File "${fileName ?? "Dokumen"}" terdeteksi mengandung ancaman malware berbahaya oleh database keamanan global VirusTotal. '
                'Sebanyak ${vtFileResult.maliciousCount} dari ${vtFileResult.totalEngines} engine antivirus global secara aktif menandai file ini sebagai ancaman.',
            tips: [
              'SANGAT PENTING: Jangan buka, instal, atau jalankan file ini di perangkat Anda.',
              'Hapus file ini segera secara permanen dari penyimpanan perangkat Anda.',
              'Jalankan pemindaian antivirus lokal pada perangkat Anda untuk menjamin kebersihan sistem.',
            ],
          );
        } else if (vtFileResult.level == UrlSafetyLevel.suspicious) {
          return AnalysisResult(
            level: ThreatLevel.suspicious,
            confidence: 0.80,
            category: 'Aplikasi / File Mencurigakan',
            explanation: 'File "${fileName ?? "Dokumen"}" ditandai mencurigakan oleh pemeriksaan VirusTotal. '
                'Terdapat engine keamanan yang mendeteksi indikasi mencurigakan (${vtFileResult.maliciousCount} deteksi antivirus).',
            tips: [
              'Harap waspada dan jangan jalankan file ini jika berasal dari sumber tidak resmi (modded apk).',
              'Jangan berikan izin sensitif (baca SMS/kontak) jika Anda memutuskan menginstal file ini.',
              'Gunakan Google Play Protect untuk perlindungan sistem optimal.',
            ],
          );
        } else if (vtFileResult.level == UrlSafetyLevel.safe) {
          preCheckNote = '\n\n== DATA PRE-CHECK FILE (Sangat Penting) ==\n'
              '${vtFileResult.summary}\n'
              'Jika terdeteksi berbahaya oleh banyak engine, nyatakan sebagai DANGER.\n';
        }
      } catch (_) {}
    }

    // ── Extraction: Dukung semua tipe file (Docx, Text, App/Software, dll) ──
    String extractedText = text ?? "";
    if (fileBytes != null) {
      final sizeKb = (fileBytes.length / 1024).toStringAsFixed(2);
      final isDocx = mimeType?.contains('officedocument.wordprocessingml') ?? false;
      final fName = fileName ?? "file_tanpa_nama";
      
      if (isDocx) {
        try {
          final docxText = _extractTextFromDocx(fileBytes);
          if (docxText.isNotEmpty) {
            extractedText = "[KONTEN DOKUMEN DOCX]\n"
                "Nama File: $fName\n"
                "Ukuran: ${sizeKb} KB\n"
                "Isi Dokumen:\n$docxText";
          }
        } catch (e) {
          extractedText = "[Gagal mengekstrak teks DOCX: $e]";
        }
      } else if (mimeType?.startsWith('text/') ?? false) {
        try {
          final textContent = utf8.decode(fileBytes, allowMalformed: true);
          extractedText = "[KONTEN FILE TEKS]\n"
              "Nama File: $fName\n"
              "Ukuran: ${sizeKb} KB\n"
              "Isi:\n$textContent";
        } catch (_) {}
      } else {
        // Binary/App/Software file (misalnya .exe, .apk, .msi, .zip)
        extractedText = "[KONTEN APLIKASI / FILE SOFTWARE / BINER]\n"
            "Nama File: $fName\n"
            "Tipe Mime: $mimeType\n"
            "Ukuran: ${sizeKb} KB\n"
            "File ini adalah program/aplikasi atau data biner. Lakukan analisis reputasi keamanan "
            "berdasarkan data hasil pra-pemeriksaan VirusTotal di atas.";
      }
    }

    final isLegal = _isLegalDocument(text, type);
    final legalSection = isLegal ? _legalPrompt() : 'Set "legal_analysis": null.\n';

    final prompt = '''
Kamu adalah analis keamanan siber dan hukum untuk pengguna Indonesia.
${_isUrl(text) ? '' : 'Gunakan Google Search untuk verifikasi fakta.'}
$preCheckNote
Tipe input: $type
Input: ${extractedText.isEmpty ? "Tidak ada teks" : extractedText}
${fileBytes != null ? "(File dilampirkan)" : ""}

ATURAN LEVEL:
- DANGER  : klaim salah, phishing/scam terbukti, malware, dokumen palsu
- SUSPICIOUS: tidak bisa diverifikasi, manipulatif, janggal
- SAFE    : fakta benar terverifikasi, pertanyaan netral, dokumen sah

$legalSection
FORMAT — kembalikan HANYA JSON valid:
{
  "level": "safe"|"suspicious"|"danger",
  "confidence": 0.0-1.0,
  "category": "Kategori singkat",
  "explanation": "Penjelasan 2-4 kalimat.",
  "tips": ["Tips 1","Tips 2","Tips 3"],
  "legal_analysis": null
}''';

    final parts = <Map<String, dynamic>>[{"text": prompt}];
    // Lampirkan file aslinya jika itu gambar, PDF, atau video (Gemini native support)
    bool geminiSupports = mimeType != null && (
      mimeType.startsWith('image/') || 
      mimeType.contains('pdf') || 
      mimeType.startsWith('video/')
    );

    if (fileBytes != null && geminiSupports) {
      parts.add({"inlineData": {"mimeType": mimeType, "data": base64Encode(fileBytes)}});
    }

    // Hanya pakai Google Search grounding jika bukan URL (URL sudah pre-check)
    final useSearch = !_isUrl(text) || preCheckNote.isEmpty;

    final body = jsonEncode({
      "contents": [{"parts": parts}],
      if (useSearch) "tools": [{"googleSearch": {}}],
      "generationConfig": {"temperature": 0.1, "topP": 0.85},
    });

    String? lastError;
    bool wasQuotaLimited = false;

    for (final model in _models) {
      try {
        final resp = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 30));

        final body2 = resp.body;
        if (resp.statusCode == 200) {
          final json      = jsonDecode(body2);
          final cands     = json['candidates'] as List?;
          if (cands == null || cands.isEmpty) continue;
          final partsList = cands[0]['content']?['parts'] as List?;
          if (partsList == null || partsList.isEmpty) continue;
          final resText   = partsList[0]['text'] as String?;
          if (resText == null) continue;

          final sourceLinks = <SourceLink>[];
          try {
            final chunks = cands[0]['groundingMetadata']?['groundingChunks'] as List?;
            chunks?.forEach((c) {
              final uri = c['web']?['uri'] as String?;
              if (uri != null && uri.isNotEmpty) {
                sourceLinks.add(SourceLink(
                  title: (c['web']?['title'] as String?)?.trim() ?? 'Sumber',
                  url: uri,
                ));
              }
            });
          } catch (_) {}

          Map<String, dynamic> jsonMap;
          try {
            jsonMap = jsonDecode(resText);
          } catch (_) {
            jsonMap = jsonDecode(
              resText.replaceAll('```json','').replaceAll('```','').trim());
          }

          final result = AnalysisResult.fromJson(jsonMap, sourceLinks: sourceLinks);
          if (fileBytes == null && text != null) {
            if (_cache.length >= _maxCache) _cache.remove(_cache.keys.first);
            _cache[_cacheKey(type, text)] = result;
          }
          return result;
        }

        if (resp.statusCode == 429 || body2.contains('RESOURCE_EXHAUSTED')) {
          wasQuotaLimited = true;
          lastError = 'quota_$model';
          continue;
        }

        if (resp.statusCode == 404 || body2.contains('NOT_FOUND')) {
          lastError = 'Model $model tidak tersedia'; continue;
        }
        
        if (body2.contains('API_KEY_INVALID') ||
            (resp.statusCode == 400 && body2.contains('API key not valid'))) {
          throw Exception('API Key tidak valid.\n✅ Format: "AIza..." dari aistudio.google.com');
        }

        lastError = 'HTTP ${resp.statusCode}';
        if (resp.statusCode >= 500) continue;
        throw Exception(lastError);
      } catch (e) {
        final m = e.toString();
        if (m.contains('tidak valid') || m.contains('ditolak') ||
            m.contains('belum diatur')) rethrow;
        lastError = m; 
        if (m.contains('429') || m.contains('quota')) wasQuotaLimited = true;
        continue;
      }
    }

    if (wasQuotaLimited) {
      throw Exception(
        'Kuota API Gemini (Free Tier) habis atau terlalu cepat.\n\n'
        '👉 Tunggu 60 detik sebelum mencoba lagi.\n'
        '👉 Gunakan API Key baru jika ingin lebih cepat.'
      );
    }
    throw Exception('Semua model Gemini gagal. Terakhir: $lastError');
  }

  /// Ekstraksi teks dari file .docx (XML parsing)
  String _extractTextFromDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final contentFile = archive.findFile('word/document.xml');
      if (contentFile == null) return "";

      final xmlString = utf8.decode(contentFile.content as List<int>);
      final document = XmlDocument.parse(xmlString);
      
      // Ambil semua elemen teks <w:t>
      final textNodes = document.findAllElements('w:t');
      return textNodes.map((node) => node.innerText).join(' ');
    } catch (e) {
      return "Error ekstrasi: $e";
    }
  }

  String _legalPrompt() => '''
== ANALISIS HUKUM ==
Dokumen ini adalah surat/kontrak hukum. Tambahkan field "legal_analysis":
{
  "document_type": "Jenis dokumen",
  "summary": "Ringkasan isi 3-5 kalimat untuk awam",
  "legal_status": "valid"|"invalid"|"perlu_dikaji",
  "impacts": ["Dampak 1","Dampak 2"],
  "benefits": ["Hak 1","Hak 2"],
  "risks": ["Risiko 1","Risiko 2"],
  "relevant_laws": ["Pasal X UU Y"],
  "recommendation": "Apa yang harus dilakukan penerima"
}
''';

  AnalysisResult? _localHeuristicAnalysis({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) {
    final name = (fileName ?? '').toLowerCase().trim();
    final t = (text ?? '').toLowerCase().trim();
    
    // Heuristic 1: Unofficial / Modded dangerous applications (WA GB / WhatsApp GB is famous for spyware/adware)
    if (name.contains('wa gb') || name.contains('wagb') || name.contains('whatsapp gb') || name.contains('gb whatsapp') || name.contains('whatsappgb') ||
        t.contains('wa gb') || t.contains('gb whatsapp') || t.contains('whatsapp gb')) {
      return const AnalysisResult(
        level: ThreatLevel.danger,
        confidence: 0.96,
        category: 'Aplikasi Modifikasi Ilegal (Spyware)',
        explanation: 'Aplikasi "WA GB" (WhatsApp GB) adalah modifikasi pihak ketiga yang ilegal dan melanggar Ketentuan Layanan WhatsApp Resmi. '
            'Aplikasi jenis ini memiliki riwayat keamanan buruk karena sering menyisipkan kode spyware, trojan, atau adware yang diam-diam menyadap SMS, OTP, daftar kontak, dan data perbankan Anda.',
        tips: [
          'SANGAT PENTING: Segera hapus file instalasi ini dan uninstal aplikasi WA GB jika terpasang.',
          'Gunakan hanya aplikasi WhatsApp resmi dari Google Play Store atau Apple App Store.',
          'Lakukan pemindaian antivirus lokal pada perangkat Anda untuk memastikan tidak ada malware aktif.',
        ],
      );
    }

    // Heuristic 2: Shopee / BRI / DANA Scam text patterns
    if (type == 'News' || type == 'Link') {
      if ((t.contains('dana kaget') && (t.contains('klik') || t.contains('link') || t.contains('klaim'))) ||
          (t.contains('undian') && t.contains('shopee') && (t.contains('menang') || t.contains('selamat'))) ||
          (t.contains('bri') && t.contains('biaya transaksi') && t.contains('150.000'))) {
        return const AnalysisResult(
          level: ThreatLevel.danger,
          confidence: 0.94,
          category: 'Rekayasa Sosial / Penipuan (Scam)',
          explanation: 'Pesan atau tautan ini mengandung indikasi kuat rekayasa sosial penipuan undian palsu Shopee, perubahan tarif bank BRI palsu, atau klaim tautan DANA Kaget palsu. '
              'Tujuannya adalah mengarahkan korban ke situs web phishing untuk mencuri kredensial perbankan, kata sandi akun, atau kode OTP.',
          tips: [
            'JANGAN mengklik tautan yang dikirimkan atau mengisi data sensitif apa pun.',
            'Ingat: Pihak bank resmi atau e-commerce besar tidak pernah meminta PIN, kata sandi, atau kode OTP Anda.',
            'Hapus pesan tersebut dan blokir nomor pengirim tidak dikenal tersebut agar tidak mengulangi penipuan.',
          ],
        );
      }
    }

    return null; // Passthrough to VirusTotal / Gemini
  }
}
