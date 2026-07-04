import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glow_orb.dart';
import '../widgets/grid_painter.dart';
import '../widgets/web_video_background.dart';
import 'home_screen.dart';
import 'scam_news_screen.dart';
import 'about_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _drawerCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 280));
  late final Animation<double> _drawerSlide =
      CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeOutCubic);
  late final Animation<double> _scrimAnim =
      CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeOut);

  // Background orbs animation
  late final AnimationController _bgAnim = AnimationController(
    vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);

  bool get _isDrawerOpen => _drawerCtrl.value > 0;

  void _openDrawer()  { HapticFeedback.lightImpact(); _drawerCtrl.forward(); }
  void _closeDrawer() { _drawerCtrl.reverse(); }
  void _navigate(int i) {
    setState(() => _currentIndex = i);
    _closeDrawer();
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  static const _items = [
    _NavItem(icon: Icons.shield_rounded,      label: 'Menu Utama',  emoji: '🛡️'),
    _NavItem(icon: Icons.newspaper_rounded,   label: 'Scam News',   emoji: '📰'),
    _NavItem(icon: Icons.info_outline_rounded,label: 'Tentang App', emoji: 'ℹ️'),
  ];

  @override
  Widget build(BuildContext ctx) {
    final width = MediaQuery.of(ctx).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Stack(
          children: [
            // ── Animated background ──────────────────────────────────────────────
            _AnimatedBg(anim: _bgAnim),

            // ── Desktop Side-by-Side Layout ──────────────────────────────────────
            Row(
              children: [
                // 1. Static Sidebar Panel on Desktop
                SizedBox(
                  width: 240,
                  child: _DrawerPanel(
                    currentIndex: _currentIndex,
                    items: _items,
                    onNavigate: (i) => setState(() => _currentIndex = i),
                    onClose: () {},
                  ),
                ),
                // 2. Main Content on the right (takes the remaining width)
                Expanded(
                  child: _buildMainContent(showHamburger: false),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── Mobile/Tablet sliding drawer layout ──────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(children: [
        // ── Animated background ──────────────────────────────────────────────
        _AnimatedBg(anim: _bgAnim),

        // ── Main content ──────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _drawerSlide,
          builder: (_, child) => Transform.translate(
            offset: Offset(_drawerSlide.value * 240, 0),
            child: child,
          ),
          child: _buildMainContent(showHamburger: true),
        ),

        // ── Scrim ─────────────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _scrimAnim,
          builder: (_, __) => _scrimAnim.value > 0
            ? GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.55 * _scrimAnim.value),
                ),
              )
            : const SizedBox.shrink(),
        ),

        // ── Drawer panel ─────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _drawerSlide,
          builder: (_, __) => Transform.translate(
            offset: Offset(-240 + (_drawerSlide.value * 240), 0),
            child: _DrawerPanel(
              currentIndex : _currentIndex,
              items        : _items,
              onNavigate   : _navigate,
              onClose      : _closeDrawer,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMainContent({required bool showHamburger}) {
    final screens = [
      const HomeScreen(onOpenDrawer: null),
      const ScamNewsScreen(),
      const AboutScreen(),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Stack(children: [
          // Current screen
          IndexedStack(index: _currentIndex, children: screens),

          // ── Transparent top bar ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  // Hamburger — glass style
                  if (showHamburger) ...[
                    GestureDetector(
                      onTap: () {
                        if (_drawerCtrl.isDismissed) {
                          _openDrawer();
                        } else {
                          _closeDrawer();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _drawerSlide,
                        builder: (_, __) => _HamburgerBtn(open: _drawerSlide.value > 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Title berganti sesuai halaman
                  Expanded(child: Text(
                    _items[_currentIndex].label,
                    textAlign: showHamburger ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary.withOpacity(0.9)),
                  )),
                  // Spacer to balance the hamburger button for perfect centering
                  if (showHamburger) const SizedBox(width: 52),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Animated Background (orbs + grid) ────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController anim;
  const _AnimatedBg({required this.anim});

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) {
      final t = anim.value;
      return Stack(fit: StackFit.expand, children: [
        const WebVideoBackground(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.45),
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.50),
              ],
            ),
          ),
        ),
        Positioned(
          left: -60 + 50 * math.sin(t * math.pi),
          top:  -40 + 40 * math.cos(t * math.pi * 0.7),
          child: GlowOrb(size: 280, color: AppColors.vermillion, opacity: 0.07)),
        Positioned(
          right: -50 + 40 * math.cos(t * math.pi * 0.8),
          bottom: 60 + 50 * math.sin(t * math.pi * 0.6),
          child: GlowOrb(size: 200, color: AppColors.gold, opacity: 0.05)),
        CustomPaint(painter: GridPatternPainter()),
      ]);
    },
  );
}

// ── Hamburger button ─────────────────────────────────────────────────────────
class _HamburgerBtn extends StatelessWidget {
  final bool open;
  const _HamburgerBtn({required this.open});
  @override
  Widget build(BuildContext ctx) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            open ? Icons.close_rounded : Icons.menu_rounded,
            key: ValueKey(open),
            color: AppColors.textPrimary, size: 20),
        ),
      ),
    ),
  );
}

// ── Drawer Panel ──────────────────────────────────────────────────────────────
class _DrawerPanel extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onNavigate;
  final VoidCallback onClose;
  const _DrawerPanel({
    required this.currentIndex, required this.items,
    required this.onNavigate, required this.onClose,
  });

  @override
  Widget build(BuildContext ctx) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        width: 240,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(right: BorderSide(
            color: AppColors.glassBorder, width: 1)),
        ),
        child: SafeArea(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drawer header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [BoxShadow(
                      color: AppColors.vermillion.withOpacity(0.4),
                      blurRadius: 12)],
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_rounded, size: 22, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DesCam AI',
                    style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  Text('Scan · Verify · Protect',
                    style: GoogleFonts.dmMono(
                      fontSize: 9, color: AppColors.textMuted)),
                ]),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Nav items ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                ...items.asMap().entries.map((e) => _DrawerNavItem(
                  item   : e.value,
                  index  : e.key,
                  active : currentIndex == e.key,
                  onTap  : () => onNavigate(e.key),
                )),
              ]),
            ),

            const Spacer(),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                Divider(color: AppColors.glassBorder, height: 1),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.safe, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Powered by Gemini AI',
                    style: GoogleFonts.dmMono(
                      fontSize: 10, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 6),
                Text('github.com/zeydan67',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.textSecondary)),
              ]),
            ),
          ],
        )),
      ),
    ),
  );
}

class _DrawerNavItem extends StatelessWidget {
  final _NavItem item;
  final int index;
  final bool active;
  final VoidCallback onTap;
  const _DrawerNavItem({
    required this.item, required this.index,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? AppColors.vermillion.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppColors.vermillion.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(children: [
        Text(item.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text(item.label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.vermillion : AppColors.textSecondary,
          )),
        if (active) ...[
          const Spacer(),
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppColors.vermillion, shape: BoxShape.circle)),
        ],
      ]),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label, emoji;
  const _NavItem({required this.icon, required this.label, required this.emoji});
}
