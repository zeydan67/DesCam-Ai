import 'dart:typed_data';
import '../models/analysis_result.dart';
import 'analysis_service.dart';

class MockAnalysisService implements AnalysisService {
  @override
  bool get isMock => true;

  @override
  Future<AnalysisResult> analyze({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final lo = (text ?? '').toLowerCase();

    // ── Mock: Surat Hukum ──────────────────────────────────────────────
    if (lo.contains('surat peringatan') || lo.contains('somasi') ||
        lo.contains('sp1') || lo.contains('sp2') || lo.contains('kontrak') ||
        lo.contains('perjanjian') || type == 'Letter') {
      return const AnalysisResult(
        level: ThreatLevel.suspicious,
        explanation:
            'Dokumen ini teridentifikasi sebagai surat peringatan hukum. '
            'Perlu dikaji lebih lanjut terkait keabsahan dan dampak hukumnya.',
        confidence: 0.78,
        category: 'Dokumen Hukum',
        tips: [
          'Jangan abaikan surat ini — ada konsekuensi hukum.',
          'Segera konsultasikan ke advokat/LBH terdekat.',
          'Catat tenggat waktu yang tercantum dalam surat.',
        ],
        legalAnalysis: LegalAnalysis(
          documentType  : 'Surat Peringatan (SP)',
          summary       : 'Surat ini merupakan peringatan resmi yang menuntut penerima untuk memenuhi '
                          'kewajiban tertentu dalam batas waktu yang ditentukan. Jika tidak dipenuhi, '
                          'pengirim berhak mengambil langkah hukum lebih lanjut.',
          legalStatus   : 'perlu_dikaji',
          impacts       : [
            'Wajib merespons sebelum tenggat waktu yang ditentukan.',
            'Pengabaian dapat menyebabkan gugatan perdata.',
            'Potensi sita aset jika terbukti wanprestasi.',
          ],
          benefits      : [
            'Dapat mengajukan mediasi sebelum proses pengadilan.',
            'Berhak mendapatkan klarifikasi detail tuntutan dari pengirim.',
          ],
          risks         : [
            'Dikategorikan wanprestasi jika tidak merespons.',
            'Biaya perkara ditanggung pihak yang kalah di pengadilan.',
            'Dapat masuk daftar hitam kredit jika terkait utang.',
          ],
          relevantLaws  : [
            'Pasal 1243 KUH Perdata (Ganti Rugi Akibat Wanprestasi)',
            'Pasal 1365 KUH Perdata (Perbuatan Melawan Hukum)',
            'UU No. 30 Tahun 1999 tentang Arbitrase dan Alternatif Penyelesaian Sengketa',
          ],
          recommendation: 'Segera hubungi advokat atau Lembaga Bantuan Hukum (LBH) terdekat '
                          'dalam 3 hari kerja. Jangan merespons surat tanpa pendampingan hukum.',
        ),
      );
    }

    // ── Mock: Penipuan ──────────────────────────────────────────────────
    if (lo.contains('hadiah') || lo.contains('menang') ||
        lo.contains('klik link') || lo.contains('prize')) {
      return const AnalysisResult(
        level: ThreatLevel.danger,
        explanation:
            'Konten mengandung indikasi penipuan hadiah palsu. '
            'Pola: janji hadiah besar, link tidak dikenal, permintaan data pribadi.',
        confidence: 0.94,
        category: 'Penipuan Hadiah',
        tips: [
          'Jangan klik tautan dari pengirim tidak dikenal.',
          'Verifikasi langsung ke sumber resmi perusahaan.',
          'Laporkan ke Kominfo atau cekrekening.id.',
        ],
      );
    }

    // ── Mock: Hoaks kesehatan ───────────────────────────────────────────
    if (lo.contains('vaksin') || lo.contains('hoaks') || lo.contains('hoax')) {
      return const AnalysisResult(
        level: ThreatLevel.suspicious,
        explanation:
            'Informasi belum terverifikasi. Kemungkinan mengandung klaim '
            'kesehatan yang menyesatkan — cek ke WHO atau Kemenkes RI.',
        confidence: 0.71,
        category: 'Hoaks Kesehatan',
        tips: [
          'Cek fakta di turnbackhoax.id atau cekfakta.com.',
          'Rujuk sumber resmi: Kemenkes, BPOM, atau WHO.',
          'Jangan share sebelum verifikasi.',
        ],
      );
    }

    return const AnalysisResult(
      level: ThreatLevel.safe,
      explanation:
          'Konten tampak aman. Tidak ditemukan pola penipuan atau hoaks yang signifikan.',
      confidence: 0.88,
      category: 'Konten Normal',
      tips: [
        'Tetap waspada meski konten terlihat aman.',
        'Selalu verifikasi informasi penting dari sumber primer.',
      ],
    );
  }
}
