import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/trending_threat.dart';
import '../../core/constants/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  final Severity severity;
  final String label;
  const SeverityBadge({super.key, required this.severity, required this.label});

  Color get _c {
    switch (severity) {
      case Severity.high:   return AppColors.danger;   // vermillion
      case Severity.medium: return AppColors.warning;  // gold
      case Severity.low:    return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _c.withOpacity(0.14),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _c.withOpacity(0.4)),
    ),
    child: Text(label.toUpperCase(),
      style: GoogleFonts.dmMono(  // DM Mono — bukan Plus Jakarta Sans
        fontSize: 8, fontWeight: FontWeight.w700,
        color: _c, letterSpacing: 0.9,
      )),
  );
}
