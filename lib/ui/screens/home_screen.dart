import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/trending_threats_list.dart';
import '../widgets/result_card.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const HomeScreen({super.key, this.onOpenDrawer});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedMimeType;

  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _pulseAnim = Tween<double>(begin: 0.98, end: 1.02)
      .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  late final AnimationController _bgAnim = AnimationController(
    vsync: this, duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  late final AnimationController _entryAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _entryFade =
      CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
  late final Animation<Offset> _entrySlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut));

  @override
  void dispose() {
    _ctrl.dispose();
    _pulse.dispose();
    _bgAnim.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  String _detectType(String text) {
    if (_selectedFileBytes != null) {
      final name = (_selectedFileName ?? '').toLowerCase();
      if (name.endsWith('.exe') || name.endsWith('.apk') || name.endsWith('.dmg') ||
          name.endsWith('.msi') || name.endsWith('.zip') || name.endsWith('.rar') ||
          name.endsWith('.bin') || name.endsWith('.app')) {
        return 'Application';
      }
      return 'Letter';
    }
    final t = text.trim().toLowerCase();
    if (t.startsWith('http') || t.contains('www.') || t.contains('://')) return 'Link';
    return 'News';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      final mime = lookupMimeType(f.path, headerBytes: bytes) ?? 'image/jpeg';
      setState(() { _selectedFileBytes = bytes; _selectedFileName = f.name; _selectedMimeType = mime; });
    }
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (r != null && r.files.isNotEmpty) {
      final file = r.files.first;
      if (file.bytes != null) {
        final mime = lookupMimeType(file.name, headerBytes: file.bytes) ?? 'application/octet-stream';
        setState(() { _selectedFileBytes = file.bytes; _selectedFileName = file.name; _selectedMimeType = mime; });
      }
    }
  }

  void _clearFile() => setState(() {
    _selectedFileBytes = null; _selectedFileName = null; _selectedMimeType = null;
  });

  void _analyze() {
    FocusScope.of(context).unfocus();
    context.read<AnalysisProvider>().analyze(
      type: _detectType(_ctrl.text),
      text: _ctrl.text,
      fileBytes: _selectedFileBytes,
      mimeType: _selectedMimeType,
      fileName: _selectedFileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang   = context.watch<LanguageProvider>().lang;
    final state  = context.watch<AnalysisProvider>().state;
    final isMock = context.read<AnalysisProvider>().isMockService;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(children: [
                        _Header(lang: lang, isMock: isMock),
                        const SizedBox(height: 24),
                        _InputPanel(
                          ctrl: _ctrl,
                          lang: lang,
                          state: state,
                          pulseAnim: _pulseAnim,
                          selectedFileName: _selectedFileName,
                          selectedFileBytes: _selectedFileBytes,
                          onPickImage: _pickImage,
                          onPickFile: _pickFile,
                          onClearFile: _clearFile,
                          onAnalyze: _analyze,
                          onTextChanged: () => setState(() {}),
                          onClear: () {
                            _ctrl.clear();
                            _clearFile();
                            context.read<AnalysisProvider>().reset();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: TrendingThreatsList()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _ResultSection(lang: lang, state: state),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VIDEO BACKGROUND — looping video + dark overlay
// ════════════════════════════════════════════════════════════════════════════
class _PremiumBackground extends StatefulWidget {
  final AnimationController anim;
  const _PremiumBackground({required this.anim});
  @override
  State<_PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<_PremiumBackground> {
  // Untuk Flutter Web: gunakan HtmlElementView via VideoPlayerWeb
  // Kita pakai pendekatan web-native via HtmlWidget
  bool _videoError = false;

  @override
  Widget build(BuildContext ctx) => Stack(fit: StackFit.expand, children: [
    // ── Video background (Flutter Web via HTML video element) ──────────────
    if (!_videoError)
      _WebVideoBackground(onError: () => setState(() => _videoError = true))
    else
      // Fallback jika video error
      Container(decoration: const BoxDecoration(gradient: AppColors.gradientBackground)),

    // ── Dark overlay — biar konten tetap terbaca ───────────────────────────
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.72),
            Colors.black.withOpacity(0.65),
            Colors.black.withOpacity(0.78),
          ],
        ),
      ),
    ),

    // ── Orb accent di atas overlay — tetap ada untuk depth ────────────────
    AnimatedBuilder(
      animation: widget.anim,
      builder: (_, __) {
        final t = widget.anim.value;
        return Stack(children: [
          Positioned(
            left: -60 + (40 * math.sin(t * math.pi)),
            top:  -40 + (30 * math.cos(t * math.pi * 0.7)),
            child: _GlowOrb(size: 280, color: AppColors.vermillion, opacity: 0.06),
          ),
          Positioned(
            right: -60 + (40 * math.cos(t * math.pi * 0.8)),
            bottom: 60 + (40 * math.sin(t * math.pi * 0.6)),
            child: _GlowOrb(size: 200, color: AppColors.gold, opacity: 0.04),
          ),
          Positioned.fill(child: _GridPattern()),
        ]);
      },
    ),
  ]);
}

// ── Flutter Web video via HtmlElementView ─────────────────────────────────
class _WebVideoBackground extends StatelessWidget {
  final VoidCallback onError;
  const _WebVideoBackground({required this.onError});

  @override
  Widget build(BuildContext ctx) {
    // Inject video element via HTML interop (Flutter Web only)
    // ignore: undefined_prefixed_name
    try {
      if (kIsWeb) {
        return HtmlElementView(viewType: 'waspada-bg-video');
      }
    } catch (_) {}
    return Container(color: AppColors.deepNavy);
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext ctx) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        color.withOpacity(opacity),
        color.withOpacity(opacity * 0.3),
        Colors.transparent,
      ], stops: const [0.0, 0.5, 1.0]),
    ),
  );
}

class _GridPattern extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => CustomPaint(
    painter: _GridPainter(),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FAF8F5)
      ..strokeWidth = 0.5;
    const spacing = 44.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER — nama app + logo + toggle bahasa
// ════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String lang;
  final bool isMock;
  const _Header({required this.lang, required this.isMock});

  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      const SizedBox(height: 24),
      // Logo centered, tidak gepeng
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.gradientAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.vermillion.withOpacity(0.45),
            blurRadius: 14, spreadRadius: 1)],
        ),
        child: const Center(
          child: Icon(Icons.shield_rounded, size: 28, color: Colors.white)),
      ),
      const SizedBox(height: 16),

      // Title & subtitle
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.get('appTitle', lang),
            style: GoogleFonts.outfit(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (isMock) ...[
            const SizedBox(width: 8),
            _StatusPill(AppStrings.get('mockBadge', lang), AppColors.warning),
          ],
        ],
      ),
      const SizedBox(height: 4),
      Text(
        AppStrings.get('subtitle', lang),
        style: GoogleFonts.dmSans(
          fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.1,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),

      // Controls
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LangToggle(lang: lang),
          const SizedBox(width: 8),
          _SettingsBtn(),
        ],
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill(this.label, this.color);

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
      style: GoogleFonts.dmMono(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );
}

class _LangToggle extends StatelessWidget {
  final String lang;
  const _LangToggle({required this.lang});

  @override
  Widget build(BuildContext ctx) {
    final isId = lang == 'id';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ctx.read<LanguageProvider>().toggle();
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _LangTab('ID', isId),
          const SizedBox(width: 2),
          _LangTab('EN', !isId),
        ]),
      ),
    );
  }
}

class _LangTab extends StatelessWidget {
  final String label;
  final bool active;
  const _LangTab(this.label, this.active);

  @override
  Widget build(BuildContext ctx) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? AppColors.vermillion : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
      style: GoogleFonts.dmMono(
        fontSize: 11,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        color: active ? Colors.white : AppColors.textSecondary,
      )),
  );
}

class _SettingsBtn extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      showDialog(context: ctx, builder: (_) => const _SettingsDialog());
    },
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// INPUT PANEL — redesign total
// ════════════════════════════════════════════════════════════════════════════
class _InputPanel extends StatelessWidget {
  final TextEditingController ctrl;
  final String lang;
  final AnalysisState state;
  final Animation<double> pulseAnim;
  final String? selectedFileName;
  final Uint8List? selectedFileBytes;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;
  final VoidCallback onAnalyze;
  final VoidCallback onTextChanged;
  final VoidCallback onClear;

  const _InputPanel({
    required this.ctrl, required this.lang, required this.state,
    required this.pulseAnim, required this.selectedFileName,
    required this.selectedFileBytes, required this.onPickImage,
    required this.onPickFile, required this.onClearFile,
    required this.onAnalyze, required this.onTextChanged, required this.onClear,
  });

  // Deteksi tipe input
  _InputMode _detectMode() {
    if (selectedFileBytes != null) return _InputMode.document;
    final t = ctrl.text.trim().toLowerCase();
    if (t.startsWith('http') || t.contains('www.') || t.contains('://')) return _InputMode.link;
    return _InputMode.text;
  }

  @override
  Widget build(BuildContext ctx) {
    final mode = _detectMode();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBg.withOpacity(0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Row(children: [
              _ModeChip(mode: mode),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mode == _InputMode.document
                      ? 'Dokumen siap dianalisis'
                      : 'Tempel teks, link, atau unggah file',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),

          // ── File chip (jika ada) ────────────────────────────────────────
          if (selectedFileName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _FileChip(name: selectedFileName!, onRemove: onClearFile),
            ),

          // ── Text field ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: TextField(
              controller: ctrl,
              maxLines: 5, minLines: 3,
              onChanged: (_) => onTextChanged(),
              style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textPrimary, height: 1.7),
              decoration: InputDecoration(
                hintText: AppStrings.get('inputHint', lang),
                hintStyle: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // ── Action bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [
              // Utility buttons — minimal, icon saja
              _UtilBtn(
                icon: Icons.content_paste_outlined,
                tooltip: 'Tempel',
                onTap: () async {
                  final d = await Clipboard.getData('text/plain');
                  if (d?.text != null) { ctrl.text = d!.text!; onTextChanged(); }
                },
              ),
              const SizedBox(width: 4),
              _UtilBtn(icon: Icons.image_outlined, tooltip: 'Gambar', onTap: onPickImage),
              const SizedBox(width: 4),
              _UtilBtn(icon: Icons.attach_file_rounded, tooltip: 'File', onTap: onPickFile),
              const SizedBox(width: 4),
              _UtilBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Hapus',
                onTap: onClear,
              ),
              const Spacer(),

              // Analyze button — vermillion, tegas
              ScaleTransition(
                scale: state == AnalysisState.loading
                    ? pulseAnim
                    : const AlwaysStoppedAnimation(1.0),
                child: _AnalyzeButton(
                  loading: state == AnalysisState.loading,
                  onTap: onAnalyze,
                  label: state == AnalysisState.loading
                      ? AppStrings.get('analyzing', lang)
                      : AppStrings.get('analyzeBtn', lang),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

enum _InputMode { text, link, document }

class _ModeChip extends StatelessWidget {
  final _InputMode mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext ctx) {
    final (icon, label, color) = switch (mode) {
      _InputMode.document => (Icons.description_outlined, 'Dokumen', AppColors.gold),
      _InputMode.link     => (Icons.link_rounded, 'Tautan', AppColors.vermillion),
      _InputMode.text     => (Icons.short_text_rounded, 'Teks / Berita', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(label,
          style: GoogleFonts.dmMono(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _UtilBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _UtilBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    ),
  );
}

class _FileChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _FileChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: AppColors.gold.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.gold.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.insert_drive_file_rounded, size: 14, color: AppColors.gold),
      const SizedBox(width: 8),
      Expanded(child: Text(name,
        style: GoogleFonts.dmSans(
          fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
      ),
    ]),
  );
}

class _AnalyzeButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;
  const _AnalyzeButton({required this.loading, required this.onTap, required this.label});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        gradient: loading ? null : AppColors.gradientAccent,
        color: loading ? AppColors.surfaceHigh : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: loading ? [] : [
          BoxShadow(
            color: AppColors.vermillion.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (loading)
          const SizedBox(width: 13, height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
        else
          const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
        const SizedBox(width: 7),
        Text(label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700, fontSize: 13,
            color: loading ? AppColors.textSecondary : Colors.white,
            letterSpacing: 0.2,
          )),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// RESULT SECTION
// ════════════════════════════════════════════════════════════════════════════
class _ResultSection extends StatelessWidget {
  final String lang;
  final AnalysisState state;
  const _ResultSection({required this.lang, required this.state});

  @override
  Widget build(BuildContext ctx) {
    switch (state) {
      case AnalysisState.idle:
        return const SizedBox.shrink();

      case AnalysisState.loading:
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(child: Column(children: [
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                color: AppColors.vermillion,
                strokeWidth: 2,
                backgroundColor: AppColors.vermillion.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.get('analyzing', lang),
              style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Gemini AI + Google Search Grounding',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted)),
          ])),
        );

      case AnalysisState.success:
        final res = ctx.read<AnalysisProvider>().result;
        return res != null ? ResultCard(result: res) : const SizedBox.shrink();

      case AnalysisState.error:
        return _ErrorPanel(message: ctx.read<AnalysisProvider>().errorMessage ?? '');
    }
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.danger.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.danger.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error_outline_rounded,
          color: AppColors.danger, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Terjadi Kesalahan',
          style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
        const SizedBox(height: 4),
        Text(message,
          style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textSecondary, height: 1.55)),
      ])),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS DIALOG
// ════════════════════════════════════════════════════════════════════════════
class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();
  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late TextEditingController _keyCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: context.read<SettingsProvider>().customKey);
    _keyCtrl.addListener(_save);
  }

  void _save() {
    final prov = context.read<SettingsProvider>();
    if (!prov.useDefault) prov.setCustomKey(_keyCtrl.text);
  }

  @override
  void dispose() { _keyCtrl.removeListener(_save); _keyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();
    return AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.vermillion.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.vpn_key_rounded, color: AppColors.vermillion, size: 16),
        ),
        const SizedBox(width: 10),
        Text('API Key',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RadioOpt(
            label: 'Gunakan API Key Bawaan',
            value: true, group: prov.useDefault,
            onChanged: (v) { if (v != null) prov.setUseDefault(v); },
          ),
          _RadioOpt(
            label: 'Gunakan API Key Sendiri',
            value: false, group: prov.useDefault,
            onChanged: (v) { if (v != null) prov.setUseDefault(v); },
          ),
          if (!prov.useDefault) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              style: GoogleFonts.dmMono(color: AppColors.textPrimary, fontSize: 13),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'AIza...',
                hintStyle: GoogleFonts.dmMono(
                  color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.glassBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.vermillion.withOpacity(0.5))),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_rounded, color: AppColors.safe, size: 18),
                  onPressed: () {
                    final key = _keyCtrl.text.trim();
                    prov.setCustomKey(key);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(key.startsWith('AIza') ? '✅ Tersimpan' : '⚠️ Format tidak valid'),
                      backgroundColor: key.startsWith('AIza') ? AppColors.safe : AppColors.warning,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('aistudio.google.com → Get API Key',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!context.read<SettingsProvider>().useDefault && _keyCtrl.text.trim().isNotEmpty) {
              context.read<SettingsProvider>().setCustomKey(_keyCtrl.text.trim());
            }
            Navigator.pop(context);
          },
          child: Text('Tutup',
            style: GoogleFonts.outfit(
              color: AppColors.vermillion, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }
}

class _RadioOpt extends StatelessWidget {
  final String label;
  final bool value, group;
  final ValueChanged<bool?> onChanged;
  const _RadioOpt({required this.label, required this.value,
    required this.group, required this.onChanged});

  @override
  Widget build(BuildContext ctx) => RadioListTile<bool>(
    title: Text(label,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13)),
    value: value, groupValue: group,
    onChanged: onChanged,
    activeColor: AppColors.vermillion,
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}
