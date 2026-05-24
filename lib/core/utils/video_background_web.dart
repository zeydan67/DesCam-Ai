// lib/core/utils/video_background_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

void registerVideoBackground() {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory('waspada-bg-video', (int viewId) {
    final video = html.VideoElement()
      ..src = 'assets/assets/bg_video.mp4'
      ..loop = true
      ..muted = true
      ..setAttribute('autoplay', 'true')
      ..setAttribute('playsinline', 'true')
      ..style.width       = '100%'
      ..style.height      = '100%'
      ..style.objectFit   = 'cover'
      ..style.position    = 'absolute'
      ..style.top         = '0'
      ..style.left        = '0'
      ..style.pointerEvents = 'none';

    // ✅ FIX: catch AbortError dari Chrome autoplay policy
    video.play().catchError((_) {
      // Autoplay diblokir browser — background fallback akan aktif otomatis
    });

    return video;
  });
}
