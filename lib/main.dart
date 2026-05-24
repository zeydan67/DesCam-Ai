import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/analysis_service.dart';
import 'core/services/mock_service.dart';
import 'core/services/gemini_service.dart';
import 'providers/language_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/app_shell.dart';

// ignore: avoid_web_libraries_in_flutter
import 'core/utils/video_background_web.dart'
    if (dart.library.io) 'core/utils/video_background_stub.dart';

// ──────────────────────────────────────────────
// ✅ TOGGLE: true = local mock, false = production
const bool kUseMock = false;
// ──────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registrasi video background (Flutter Web only)
  if (kIsWeb) {
    registerVideoBackground();
  }

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ProxyProvider<SettingsProvider, AnalysisService>(
          update: (_, settings, __) => kUseMock
              ? MockAnalysisService()
              : GeminiAnalysisService(apiKey: settings.activeApiKey, vtApiKey: settings.vtApiKey),
        ),
        ChangeNotifierProxyProvider<AnalysisService, AnalysisProvider>(
          create: (ctx) => AnalysisProvider(ctx.read<AnalysisService>()),
          update: (ctx, svc, prev) {
            prev?.updateService(svc);
            return prev ?? AnalysisProvider(svc);
          },
        ),
      ],
      child: const _App(),
    ),
  );
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext ctx) => MaterialApp(
    title: 'DesCam AI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const AppShell(),
  );
}
