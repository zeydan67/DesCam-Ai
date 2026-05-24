import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/trending_threat.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../providers/analysis_provider.dart';
import 'severity_badge.dart';

class TrendingThreatsList extends StatelessWidget {
  const TrendingThreatsList({super.key});

  @override
  Widget build(BuildContext ctx) {
    final lang    = ctx.watch<LanguageProvider>().lang;
    final prov    = ctx.watch<AnalysisProvider>();
    final threats = prov.trendingThreats;
    final loading = prov.trendingLoading;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Text(AppStrings.get('trendingTitle', lang),
              style: Theme.of(ctx).textTheme.headlineMedium),
          const Spacer(),
          // Refresh button
          if (!loading)
            GestureDetector(
              onTap: () => ctx.read<AnalysisProvider>().refreshTrending(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 14, color: AppColors.textSecondary),
              ),
            ),
          if (!loading) const SizedBox(width: 8),
          // Badge count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: loading
                ? const SizedBox(width: 40, height: 12,
                    child: LinearProgressIndicator(
                      color: AppColors.danger, backgroundColor: Colors.transparent))
                : Text('${threats.length} berita',
                    style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.danger)),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      // Subtitle: update info
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(AppStrings.get('trendingRefresh', lang),
          style: GoogleFonts.dmSans(
            fontSize: 10, color: AppColors.textSecondary,
            fontStyle: FontStyle.italic)),
      ),
      const SizedBox(height: 10),
      if (loading && threats.isEmpty)
        SizedBox(
          height: 240,
          child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.danger, strokeWidth: 2)),
              const SizedBox(height: 12),
              Text(AppStrings.get('trendingLoading', lang),
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary)),
            ],
          )),
        )
      else
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: threats.length,
            itemBuilder: (_, i) => _ThreatCard(t: threats[i], lang: lang),
          ),
        ),
    ]);
  }
}

class _ThreatCard extends StatefulWidget {
  final TrendingThreat t;
  final String lang;
  const _ThreatCard({required this.t, required this.lang});
  @override
  State<_ThreatCard> createState() => _ThreatCardState();
}

class _ThreatCardState extends State<_ThreatCard> {
  bool _pressing = false;

  Color get _borderColor {
    switch (widget.t.severity) {
      case Severity.high:   return AppColors.danger;
      case Severity.medium: return AppColors.warning;
      case Severity.low:    return AppColors.emerald;
    }
  }

  String _sev() {
    switch (widget.t.severity) {
      case Severity.high:   return AppStrings.get('sevHigh',   widget.lang);
      case Severity.medium: return AppStrings.get('sevMedium', widget.lang);
      case Severity.low:    return AppStrings.get('sevLow',    widget.lang);
    }
  }

  Future<void> _openArticle() async {
    if (widget.t.articleUrl == null) return;
    final uri = Uri.tryParse(widget.t.articleUrl!);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: GestureDetector(
      onTap: widget.t.articleUrl != null ? _openArticle : null,
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp:   (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 210, height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_borderColor, _borderColor.withOpacity(0.25)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: Container(
                color: AppColors.navyLight.withOpacity(0.97),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Thumbnail
                  if (widget.t.imageUrl != null)
                    SizedBox(
                      height: 95, width: double.infinity,
                      child: Stack(fit: StackFit.expand, children: [
                        Image.network(
                          widget.t.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.glassBg,
                            child: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.textSecondary, size: 32)),
                          loadingBuilder: (_, child, prog) {
                            if (prog == null) return child;
                            return Container(color: AppColors.glassBg,
                              child: const Center(child: SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.electricBlue))));
                          },
                        ),
                        // Gradient overlay
                        Positioned(bottom: 0, left: 0, right: 0,
                          child: Container(height: 40,
                            decoration: BoxDecoration(gradient: LinearGradient(
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              colors: [AppColors.navyLight.withOpacity(0.97), Colors.transparent])))),
                        Positioned(top: 8, left: 8,
                          child: SeverityBadge(severity: widget.t.severity, label: _sev())),
                        Positioned(top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(6)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.report_outlined, size: 10, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(_fmt(widget.t.reportCount),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10, color: AppColors.textSecondary)),
                            ]))),
                      ]),
                    ),

                  // Text content
                  Expanded(child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (widget.t.imageUrl == null) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          SeverityBadge(severity: widget.t.severity, label: _sev()),
                          Row(children: [
                            const Icon(Icons.report_outlined, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(_fmt(widget.t.reportCount),
                              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
                          ]),
                        ]),
                        const SizedBox(height: 8),
                      ],
                      Text(widget.t.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Expanded(child: Text(widget.t.description,
                        style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary, height: 1.45),
                        maxLines: 3, overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.t.category,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9, color: AppColors.electricBlue, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const Spacer(),
                            if (widget.t.articleUrl != null)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Baca', style: GoogleFonts.dmSans(
                                  fontSize: 9, color: AppColors.electricBlue, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 2),
                                const Icon(Icons.open_in_new_rounded, size: 10, color: AppColors.electricBlue),
                              ]),
                          ]),
                          if (widget.t.articleSource != null) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.newspaper_rounded, size: 9, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(widget.t.articleSource!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9, color: AppColors.textSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ],
                        ],
                      ),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
