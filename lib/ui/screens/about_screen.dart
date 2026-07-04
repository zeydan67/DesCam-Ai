import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glow_orb.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  static const _features = [
    ('🔍', 'Deteksi Hoaks', 'Verifikasi berita & info viral menggunakan Gemini AI + Google Search Grounding'),
    ('🛡️', 'Scan URL Berbahaya', 'Cek link phishing & malware via VirusTotal + PhishTank sebelum mengklik'),
    ('⚖️', 'Analisis Hukum', 'Pahami isi surat hukum, dampak, hak, dan risiko — dalam bahasa yang mudah dimengerti'),
    ('📰', 'Scam News', 'Pantau penipuan terbaru dari Indonesia dan seluruh dunia secara real-time'),
    ('🤖', 'AI Powered', 'Ditenagai Google Gemini 2.5 Flash dengan kemampuan grounding ke sumber terpercaya'),
    ('🔒', 'Privasi Terjaga', 'Tidak ada data pengguna yang disimpan di server — semua diproses lokal & API langsung'),
  ];

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(children: [
      // Background orb
      AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Stack(children: [
          Positioned(
            left: -80 + 50 * math.sin(_anim.value * math.pi),
            top:  100 + 40 * math.cos(_anim.value * math.pi),
            child: GlowOrb(size: 300, color: AppColors.vermillion, opacity: 0.05)),
          Positioned(
            right: -60 + 40 * math.cos(_anim.value * math.pi * 0.7),
            bottom: 80 + 50 * math.sin(_anim.value * math.pi * 0.5),
            child: GlowOrb(size: 240, color: AppColors.gold, opacity: 0.04)),
        ]),
      ),
      SafeArea(child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Column(children: [
              // Logo — besar, centered, tidak gepeng
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.vermillion.withOpacity(0.5),
                      blurRadius: 32, spreadRadius: 4),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.shield_rounded, size: 48, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Text('DesCam AI',
                style: GoogleFonts.outfit(
                  fontSize: 30, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text('Detektor Hoaks, Penipuan & Hukum',
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.vermillion.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.vermillion.withOpacity(0.25)),
                ),
                child: Text('v1.0.0 · Dibuat untuk JuaraVibeCoding 2026',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.vermillion)),
              ),
            ]),
          )),

          // ── Deskripsi ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: _glassBox(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('🎯 Tentang Aplikasi'),
                const SizedBox(height: 10),
                Text(
                  'DesCam AI adalah tools berbasis kecerdasan buatan yang membantu '
                  'masyarakat Indonesia mengenali hoaks, penipuan digital, dan memahami '
                  'dokumen hukum dengan bahasa yang mudah dimengerti.\n\n'
                  'Di era informasi yang serba cepat, banyak orang tertipu oleh berita '
                  'palsu, link berbahaya, dan surat hukum yang tidak dipahami. '
                  'DesCam AI hadir sebagai "teman cerdas" yang siap memverifikasi '
                  'konten apapun secara instan.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5, color: AppColors.textSecondary,
                    height: 1.7),
                ),
              ]),
            )),
          )),

          // ── Fitur ────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _glassBox(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('⚡ Fitur Utama'),
                const SizedBox(height: 14),
                ..._features.map((f) => _FeatureRow(
                  emoji: f.$1, title: f.$2, desc: f.$3)),
              ]),
            )),
          )),

          // ── Tech Stack ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _glassBox(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('🛠️ Tech Stack'),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _techChip('Flutter', AppColors.vermillion),
                  _techChip('Gemini 2.5 Flash', AppColors.gold),
                  _techChip('Google Search Grounding', AppColors.gold),
                  _techChip('VirusTotal API', AppColors.safe),
                  _techChip('PhishTank', AppColors.safe),
                  _techChip('RSS Feed', AppColors.textSecondary),
                  _techChip('Provider', AppColors.textSecondary),
                  _techChip('SharedPreferences', AppColors.textSecondary),
                ]),
              ]),
            )),
          )),

          // ── Developer ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _glassBox(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientAccent,
                      borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                      child: Text('👨‍💻', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Developer',
                      style: GoogleFonts.dmMono(
                        fontSize: 10, color: AppColors.textMuted,
                        letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text('zeydan67',
                      style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                  ])),
                ]),
                const SizedBox(height: 14),
                // GitHub Button
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/zeydan67'),
                    mode: LaunchMode.externalApplication),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1618401471353-b98aedd07871?auto=format&fit=crop&w=48&h=48',
                          width: 18, height: 18,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.code_rounded, size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('github.com/zeydan67',
                        style: GoogleFonts.dmMono(
                          fontSize: 13, color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_new_rounded,
                        size: 14, color: AppColors.textSecondary),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Dibuat dengan ❤️ untuk masyarakat Indonesia',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted),
                  textAlign: TextAlign.center),
              ]),
            )),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      )),
    ]),
  );

  Widget _glassBox({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.navyLight.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: child,
  );

  Widget _sectionTitle(String t) => Text(t,
    style: GoogleFonts.outfit(
      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

  Widget _techChip(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.withOpacity(0.2)),
    ),
    child: Text(label,
      style: GoogleFonts.dmMono(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
  );
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, desc;
  const _FeatureRow({required this.emoji, required this.title, required this.desc});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 3),
        Text(desc, style: GoogleFonts.dmSans(
          fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
      ])),
    ]),
  );
}
