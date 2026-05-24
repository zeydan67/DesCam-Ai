import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/analysis_result.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/language_provider.dart';
import 'glass_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
class ResultCard extends StatefulWidget {
  final AnalysisResult result;
  const ResultCard({super.key, required this.result});
  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 750),
  )..forward();

  late final Animation<double> _fadeIn =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<double> _barAnim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slideUp = Tween<Offset>(
    begin: const Offset(0, 0.18), end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Color get _color {
    switch (widget.result.level) {
      case ThreatLevel.safe:       return AppColors.emerald;
      case ThreatLevel.danger:     return AppColors.danger;
      case ThreatLevel.suspicious: return AppColors.warning;
    }
  }
  IconData get _icon {
    switch (widget.result.level) {
      case ThreatLevel.safe:       return Icons.verified_rounded;
      case ThreatLevel.danger:     return Icons.gpp_bad_rounded;
      case ThreatLevel.suspicious: return Icons.gpp_maybe_rounded;
    }
  }
  String _label(String lang) {
    switch (widget.result.level) {
      case ThreatLevel.safe:       return AppStrings.get('safe',       lang);
      case ThreatLevel.danger:     return AppStrings.get('danger',     lang);
      case ThreatLevel.suspicious: return AppStrings.get('suspicious', lang);
    }
  }
  String _emoji() {
    switch (widget.result.level) {
      case ThreatLevel.safe:       return '✅';
      case ThreatLevel.danger:     return '🚨';
      case ThreatLevel.suspicious: return '⚠️';
    }
  }

  // ── Share bottom sheet ───────────────────────────────────────────────────
  void _showShare(BuildContext ctx, String lang) {
    final verdict = _label(lang);
    final pct     = (widget.result.confidence * 100).toStringAsFixed(0);
    final shareText =
        '${_emoji()} Info ini *$verdict*, diverifikasi oleh *WaspadaAI*\n'
        '🤖 Tingkat keyakinan AI: *$pct%*\n'
        '📋 Kategori: ${widget.result.category}\n\n'
        '📱 Cek sendiri konten mencurigakan di *WaspadaAI* — '
        'detektor hoaks & penipuan bertenaga Google Gemini AI.';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(text: shareText, color: _color),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final lang = ctx.watch<LanguageProvider>().lang;
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: GlassCard(
          gradientBorder: [_color, _color.withOpacity(0.15)],
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Banner ───────────────────────────────────────────────────
            _Banner(
              color: _color, icon: _icon, emoji: _emoji(),
              label: _label(lang), category: widget.result.category,
              hasLegal: widget.result.legalAnalysis != null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Confidence Bar w/ glow ─────────────────────────────
                _GlowConfidenceBar(
                  confidence : widget.result.confidence,
                  color      : _color,
                  anim       : _barAnim,
                  label      : AppStrings.get('confidence',     lang),
                  note       : AppStrings.get('confidenceNote', lang),
                ),
                const SizedBox(height: 22),

                // ── Smart Explanation ─────────────────────────────────
                _SectionLabel(AppStrings.get('explanation', lang)),
                const SizedBox(height: 10),
                _SmartExplanation(
                  text          : widget.result.explanation,
                  color         : _color,
                  verdictLabel  : _label(lang),
                ),

                // ── Tips ──────────────────────────────────────────────
                if (widget.result.tips.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionLabel(AppStrings.get('tips', lang)),
                  const SizedBox(height: 10),
                  ...widget.result.tips.map((t) => _TipRow(tip: t, color: _color)),
                ],

                // ── Legal Analysis ────────────────────────────────────
                if (widget.result.legalAnalysis != null) ...[
                  const SizedBox(height: 24),
                  _LegalAnalysisSection(
                    legal: widget.result.legalAnalysis!, lang: lang),
                ],

                // ── Premium Source Cards ──────────────────────────────
                if (widget.result.sourceLinks.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionLabel(AppStrings.get('sources', lang)),
                  const SizedBox(height: 10),
                  ...widget.result.sourceLinks.map(
                    (l) => _PremiumSourceCard(link: l)),
                ],

                const SizedBox(height: 24),
              ]),
            ),

            // ── Share Bar ─────────────────────────────────────────────
            _ShareBar(
              color   : _color,
              onShare : () => _showShare(ctx, lang),
              verdict : _label(lang),
              emoji   : _emoji(),
            ),
          ]),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHARE BAR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ShareBar extends StatelessWidget {
  final Color color;
  final VoidCallback onShare;
  final String verdict;
  final String emoji;
  const _ShareBar({
    required this.color, required this.onShare,
    required this.verdict, required this.emoji,
  });

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      border: Border(top: BorderSide(color: color.withOpacity(0.18), width: 1)),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Merasa aman & berdaya? 🛡️',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Bagikan verifikasi ini ke orang-orang terdekatmu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: AppColors.textSecondary)),
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onShare();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.share_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 7),
            Text('Bagikan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    ]),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHARE SHEET (Bottom Modal)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _ShareSheet extends StatelessWidget {
  final String text;
  final Color color;
  const _ShareSheet({required this.text, required this.color});

  Future<void> _openWhatsApp(BuildContext ctx) async {
    final encoded = Uri.encodeComponent(text);
    final uri     = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('WhatsApp tidak terinstall'),
            backgroundColor: AppColors.warning));
      }
    }
  }

  Future<void> _openTelegram(BuildContext ctx) async {
    final encoded = Uri.encodeComponent(text);
    final uri     = Uri.parse('https://t.me/share/url?url=&text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyToClipboard(BuildContext ctx) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('✅ Teks disalin!',
          style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2)));
      Navigator.pop(ctx);
    }
  }

  @override
  Widget build(BuildContext ctx) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.navyLight.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: color.withOpacity(0.3), width: 1.5)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Bagikan Keputusan Keamanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Lindungi orang sekitarmu dari hoaks & penipuan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
          const SizedBox(height: 18),

          // Preview box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.white.withOpacity(0.85), height: 1.6)),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(children: [
            _shareBtn(ctx, '💬', 'WhatsApp', const Color(0xFF25D366),
                () => _openWhatsApp(ctx)),
            const SizedBox(width: 10),
            _shareBtn(ctx, '✈️', 'Telegram', const Color(0xFF2CA5E0),
                () => _openTelegram(ctx)),
            const SizedBox(width: 10),
            _shareBtn(ctx, '📋', 'Salin Teks', AppColors.electricBlue,
                () => _copyToClipboard(ctx)),
          ]),
        ]),
      ),
    ),
  );

  Widget _shareBtn(BuildContext ctx, String emoji, String label, Color c, VoidCallback fn) =>
      Expanded(child: GestureDetector(
        onTap: fn,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.35)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: c)),
          ]),
        ),
      ));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SMART EXPLANATION (Item 3 — Tipografi Cerdas)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SmartExplanation extends StatelessWidget {
  final String text;
  final Color color;
  final String verdictLabel;
  const _SmartExplanation({
    required this.text, required this.color, required this.verdictLabel});

  static const _keywords = [
    // EN
    'SAFE', 'DANGER', 'SUSPICIOUS', 'WARNING', 'SCAM', 'HOAX', 'PHISHING',
    'MALWARE', 'VERIFIED', 'FAKE', 'FRAUD',
    // ID
    'AMAN', 'BAHAYA', 'MENCURIGAKAN', 'PENIPUAN', 'HOAKS', 'PALSU', 'SCAM',
    'BERBAHAYA', 'TIDAK AMAN', 'WASPADA', 'TERVERIFIKASI', 'VALID', 'TIDAK VALID',
  ];

  @override
  Widget build(BuildContext ctx) {
    final spans = <InlineSpan>[];
    final allKw = [..._keywords, verdictLabel.toUpperCase()];

    String remaining = text;
    while (remaining.isNotEmpty) {
      int earliestIdx  = remaining.length;
      String? foundKw;

      for (final kw in allKw) {
        final idx = remaining.toUpperCase().indexOf(kw.toUpperCase());
        if (idx != -1 && idx < earliestIdx) {
          earliestIdx = idx;
          foundKw     = kw;
        }
      }

      if (foundKw == null) {
        // No more keywords
        spans.add(TextSpan(
          text: remaining,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15, color: Colors.white.withOpacity(0.9), height: 1.65),
        ));
        break;
      }

      // Text before keyword
      if (earliestIdx > 0) {
        spans.add(TextSpan(
          text: remaining.substring(0, earliestIdx),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15, color: Colors.white.withOpacity(0.9), height: 1.65),
        ));
      }

      // The keyword itself — highlighted
      final kwInText = remaining.substring(earliestIdx, earliestIdx + foundKw.length);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withOpacity(0.4), width: 0.8),
          ),
          child: Text(kwInText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, fontWeight: FontWeight.w800,
              color: color, height: 1.4)),
        ),
      ));

      remaining = remaining.substring(earliestIdx + foundKw.length);
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BANNER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _Banner extends StatelessWidget {
  final Color color; final IconData icon; final String emoji;
  final String label; final String category; final bool hasLegal;
  const _Banner({required this.color, required this.icon, required this.emoji,
      required this.label, required this.category, required this.hasLegal});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.22), color.withOpacity(0.04)],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: Row(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4,
          shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 12)],
        )),
        const SizedBox(height: 5),
        Row(children: [
          _chip(category, color),
          if (hasLegal) ...[
            const SizedBox(width: 6),
            _chip('⚖️ Hukum', const Color(0xFF818CF8)),
          ],
        ]),
      ])),
    ]),
  );

  Widget _chip(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withOpacity(0.3), width: 1),
    ),
    child: Text(text, style: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w600, color: c)),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GLOW CONFIDENCE BAR (Item 2)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _GlowConfidenceBar extends StatelessWidget {
  final double confidence; final Color color;
  final Animation<double> anim; final String label; final String note;
  const _GlowConfidenceBar({required this.confidence, required this.color,
      required this.anim, required this.label, required this.note});

  String _confidenceLabel(double c) {
    if (c >= 0.90) return 'Sangat Yakin';
    if (c >= 0.75) return 'Cukup Yakin';
    if (c >= 0.55) return 'Agak Yakin';
    return 'Perlu Verifikasi';
  }

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.glassBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, spreadRadius: 2),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 1.1)),
        AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${(confidence * anim.value * 100).toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32, fontWeight: FontWeight.w900, color: color,
                shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 16)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('%', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: color.withOpacity(0.7))),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 4),
      Text(_confidenceLabel(confidence), style: GoogleFonts.plusJakartaSans(
        fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),

      // Bar with glow
      AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          final pct = confidence * anim.value;
          return Stack(children: [
            // Track
            Container(
              height: 10, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Fill + glow
            FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.55),
                      blurRadius: 8, spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ]);
        },
      ),
      const SizedBox(height: 8),
      Text(note, style: GoogleFonts.plusJakartaSans(
        fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
    ]),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PREMIUM SOURCE CARD (Item 1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PremiumSourceCard extends StatefulWidget {
  final SourceLink link;
  const _PremiumSourceCard({required this.link});
  @override
  State<_PremiumSourceCard> createState() => _PremiumSourceCardState();
}

class _PremiumSourceCardState extends State<_PremiumSourceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 180));
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 1.015)
          .animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  late final Animation<double> _glow =
      Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  String _domain(String url) {
    try { return Uri.parse(url).host.replaceFirst('www.', ''); }
    catch (_) { return url.length > 30 ? '${url.substring(0, 28)}…' : url; }
  }

  String _domainEmoji(String domain) {
    if (domain.contains('kominfo') || domain.contains('go.id')) return '🏛️';
    if (domain.contains('ojk'))     return '🏦';
    if (domain.contains('bca') || domain.contains('bank')) return '💳';
    if (domain.contains('polri') || domain.contains('hukum')) return '⚖️';
    if (domain.contains('kompas') || domain.contains('detik') ||
        domain.contains('cnbc')  || domain.contains('tempo'))  return '📰';
    return '🔗';
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.link.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka link'),
          backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final domain = _domain(widget.link.url);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => _hoverCtrl.forward(),
        onExit:  (_) => _hoverCtrl.reverse(),
        child: GestureDetector(
          onTapDown: (_) => _hoverCtrl.forward(),
          onTapUp:   (_) { _hoverCtrl.reverse(); _open(); },
          onTapCancel: () => _hoverCtrl.reverse(),
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    AppColors.glassBg,
                    AppColors.electricBlue.withOpacity(0.06),
                    _glow.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color.lerp(
                      AppColors.glassBorder,
                      AppColors.electricBlue.withOpacity(0.45),
                      _glow.value,
                    )!,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.06 * _glow.value),
                      blurRadius: 12, spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(children: [
                  // Domain icon
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.electricBlue.withOpacity(0.25)),
                    ),
                    child: Center(child: Text(
                      _domainEmoji(domain),
                      style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),

                  // Title + domain
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      widget.link.title.isNotEmpty
                          ? widget.link.title
                          : domain,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: Text(domain,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ])),

                  // Open button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(
                          0.1 + 0.08 * _glow.value),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.electricBlue.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Buka', style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.electricBlue)),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded,
                        size: 12, color: AppColors.electricBlue),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEGAL ANALYSIS SECTION (retained, polished)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _LegalAnalysisSection extends StatefulWidget {
  final LegalAnalysis legal; final String lang;
  const _LegalAnalysisSection({required this.legal, required this.lang});
  @override
  State<_LegalAnalysisSection> createState() => _LegalAnalysisSectionState();
}

class _LegalAnalysisSectionState extends State<_LegalAnalysisSection> {
  bool _expanded = true;
  static const _purple = Color(0xFF818CF8);

  Color get _statusColor {
    switch (widget.legal.legalStatus) {
      case 'valid':   return AppColors.emerald;
      case 'invalid': return AppColors.danger;
      default:        return AppColors.warning;
    }
  }
  String _statusLabel() {
    switch (widget.legal.legalStatus) {
      case 'valid':   return AppStrings.get('legalValid',   widget.lang);
      case 'invalid': return AppStrings.get('legalInvalid', widget.lang);
      default:        return AppStrings.get('legalReview',  widget.lang);
    }
  }
  String _statusEmoji() {
    switch (widget.legal.legalStatus) {
      case 'valid':   return '✅';
      case 'invalid': return '❌';
      default:        return '🔍';
    }
  }

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_purple.withOpacity(0.1), _purple.withOpacity(0.03)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _purple.withOpacity(0.3), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.08),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _expanded ? Radius.zero : const Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10)),
              child: const Text('⚖️', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.get('legalTitle', widget.lang),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: _purple, letterSpacing: 1.1)),
              Text(widget.legal.documentType,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.white.withOpacity(0.65))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor.withOpacity(0.4))),
              child: Text('${_statusEmoji()} ${_statusLabel()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
            ),
            const SizedBox(width: 8),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: _purple, size: 20),
          ]),
        ),
      ),
      if (_expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ls('📋', AppStrings.get('legalSummary', widget.lang),
              Text(widget.legal.summary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.white.withOpacity(0.87), height: 1.65))),
            if (widget.legal.impacts.isNotEmpty)   ...[const SizedBox(height: 14),
              _ls('⚡', AppStrings.get('legalImpact',   widget.lang), _bl(widget.legal.impacts,   AppColors.warning))],
            if (widget.legal.benefits.isNotEmpty)  ...[const SizedBox(height: 14),
              _ls('✅', AppStrings.get('legalBenefits', widget.lang), _bl(widget.legal.benefits,  AppColors.emerald))],
            if (widget.legal.risks.isNotEmpty)     ...[const SizedBox(height: 14),
              _ls('🚨', AppStrings.get('legalRisks',    widget.lang), _bl(widget.legal.risks,     AppColors.danger))],
            if (widget.legal.relevantLaws.isNotEmpty) ...[const SizedBox(height: 14),
              _ls('📚', AppStrings.get('legalLaws', widget.lang),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.legal.relevantLaws.map((law) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(margin: const EdgeInsets.only(top: 6),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(law, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: _purple, fontWeight: FontWeight.w500, height: 1.5))),
                    ]),
                  )).toList()))],
            if (widget.legal.recommendation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _purple.withOpacity(0.3))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppStrings.get('legalAction', widget.lang),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: _purple, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(widget.legal.recommendation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.65)),
                  ])),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder)),
              child: Text(AppStrings.get('legalDisclaimer', widget.lang),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic, height: 1.4)),
            ),
          ]),
        ),
    ]),
  );

  Widget _ls(String icon, String label, Widget child) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: AppColors.textSecondary, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 8),
        child,
      ]);

  Widget _bl(List<String> items, Color c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: c.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(Icons.circle, size: 5, color: c)),
            const SizedBox(width: 10),
            Expanded(child: Text(item, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.55))),
          ]),
        )).toList());
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHARED SMALL WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 1.2));
}

class _TipRow extends StatelessWidget {
  final String tip; final Color color;
  const _TipRow({required this.tip, required this.color});
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 12, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Text(tip, style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5, color: Colors.white.withOpacity(0.87), height: 1.6))),
    ]),
  );
}
