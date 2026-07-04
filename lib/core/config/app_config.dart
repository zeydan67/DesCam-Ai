class AppConfig {
  /// ─────────────────────────────────────────────────────────────────────────
  /// API KEY BAWAAN (Default)
  /// ─────────────────────────────────────────────────────────────────────────
  ///
  /// JANGAN pernah menuliskan API key langsung (hardcode) di file ini. File ini
  /// ikut ter-commit ke repository publik, dan pada Flutter Web key apa pun yang
  /// disematkan akan ikut ter-bundle ke JavaScript sehingga bisa diekstrak siapa
  /// saja.
  ///
  /// Key default (opsional) hanya disuntikkan saat build lewat compile-time
  /// environment variable, contoh:
  ///
  ///   flutter build web --release --dart-define=GEMINI_API_KEY=AIza...
  ///
  /// Jika tidak diisi, aplikasi akan meminta pengguna memasukkan key mereka
  /// sendiri melalui menu ⚙️ Pengaturan.
  /// ─────────────────────────────────────────────────────────────────────────
  static const String defaultGeminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
