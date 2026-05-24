import 'package:flutter/material.dart';

/// WaspadaAI — "Obsidian & Vermillion"
/// Base: warm charcoal (bukan cold navy generik AI)
/// Accent: vermillion merah-oranye + gold
class AppColors {
  AppColors._();

  // ── Base Surface ──────────────────────────────────────────────────────────
  static const deepNavy      = Color(0xFF111214);   // background utama
  static const navyLight     = Color(0xFF1A1C1F);   // surface card
  static const surfaceHigh   = Color(0xFF22252A);   // dialog/modal

  // ── Accent Vermillion (ganti electricBlue generik) ───────────────────────
  static const electricBlue  = Color(0xFFE5451F);   // alias compat
  static const vermillion    = Color(0xFFE5451F);
  static const vermillionSoft= Color(0xFFFF6B47);

  // ── Accent Gold (ganti emerald generik) ─────────────────────────────────
  static const emerald       = Color(0xFFD4A843);   // alias compat
  static const gold          = Color(0xFFD4A843);
  static const goldSoft      = Color(0xFFEDC76A);

  // ── Status ────────────────────────────────────────────────────────────────
  static const danger        = Color(0xFFE5451F);
  static const warning       = Color(0xFFD4A843);
  static const safe          = Color(0xFF2DBF7E);
  static const suspicious    = Color(0xFFE8853A);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFF0EDE8);   // warm white
  static const textSecondary = Color(0xFF8A8680);   // warm grey
  static const textMuted     = Color(0xFF52504D);

  // ── Glass / Border ────────────────────────────────────────────────────────
  static const glassBg       = Color(0x0DFAF8F5);
  static const glassBorder   = Color(0x18FAF8F5);
  static const borderSubtle  = Color(0x0FFAF8F5);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const gradientAccent = LinearGradient(
    colors: [vermillion, vermillionSoft],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientGold = LinearGradient(
    colors: [gold, goldSoft],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientBackground = RadialGradient(
    center: Alignment(-0.3, -0.6), radius: 1.4,
    colors: [Color(0xFF1C1614), Color(0xFF111214)],
  );
}
