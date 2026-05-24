class AppStrings {
  AppStrings._();

  static const _data = <String, Map<String, String>>{
    'appTitle'       : {'id': 'DesCam AI',                                'en': 'DesCam AI'},
    'subtitle'       : {'id': 'Detektor Penipuan, Hoaks & Hukum Bertenaga AI', 'en': 'AI-Powered Scam, Hoax & Legal Analyzer'},
    'inputHint'      : {'id': 'Tempel teks, URL, surat hukum, atau nomor...', 'en': 'Paste text, URL, legal letter, or number...'},
    'analyzeBtn'     : {'id': 'Analisis Sekarang',                        'en': 'Analyze Now'},
    'analyzing'      : {'id': 'Sedang menganalisis...',                   'en': 'Analyzing...'},
    'trendingTitle'  : {'id': 'Ancaman Trending',                         'en': 'Trending Threats'},
    'resultTitle'    : {'id': 'Hasil Analisis',                           'en': 'Analysis Result'},
    'safe'           : {'id': 'AMAN',                                     'en': 'SAFE'},
    'danger'         : {'id': 'BAHAYA',                                   'en': 'DANGER'},
    'suspicious'     : {'id': 'MENCURIGAKAN',                             'en': 'SUSPICIOUS'},
    'confidence'     : {'id': 'Tingkat Keyakinan AI',                     'en': 'AI Confidence Level'},
    'explanation'    : {'id': 'PENJELASAN',                               'en': 'EXPLANATION'},
    'tips'           : {'id': 'TIPS KEAMANAN',                            'en': 'SAFETY TIPS'},
    'sources'        : {'id': 'SUMBER REFERENSI',                         'en': 'REFERENCE SOURCES'},
    'sevHigh'        : {'id': 'TINGGI',                                   'en': 'HIGH'},
    'sevMedium'      : {'id': 'SEDANG',                                   'en': 'MEDIUM'},
    'sevLow'         : {'id': 'RENDAH',                                   'en': 'LOW'},
    'mockBadge'      : {'id': 'MODE DEV',                                 'en': 'DEV MODE'},
    'scannerTitle'   : {'id': 'Pilih Jenis Scan',                         'en': 'Select Scan Type'},
    'confidenceNote' : {'id': 'Berdasarkan analisis bukti & pola ancaman','en': 'Based on evidence & threat pattern analysis'},
    // ── Legal Analysis strings ─────────────────────────────────────────
    'legalTitle'     : {'id': 'ANALISIS HUKUM',                          'en': 'LEGAL ANALYSIS'},
    'legalDocType'   : {'id': 'JENIS DOKUMEN',                           'en': 'DOCUMENT TYPE'},
    'legalSummary'   : {'id': 'RINGKASAN ISI',                           'en': 'CONTENT SUMMARY'},
    'legalStatus'    : {'id': 'STATUS HUKUM',                            'en': 'LEGAL STATUS'},
    'legalImpact'    : {'id': 'DAMPAK HUKUM',                            'en': 'LEGAL IMPACT'},
    'legalBenefits'  : {'id': 'HAK & KEUNTUNGAN',                        'en': 'RIGHTS & BENEFITS'},
    'legalRisks'     : {'id': 'RISIKO & ANCAMAN',                        'en': 'RISKS & THREATS'},
    'legalLaws'      : {'id': 'DASAR HUKUM',                             'en': 'LEGAL BASIS'},
    'legalAction'    : {'id': 'REKOMENDASI TINDAKAN',                    'en': 'RECOMMENDED ACTION'},
    'legalValid'     : {'id': 'SAH & VALID',                             'en': 'VALID & LEGAL'},
    'legalInvalid'   : {'id': 'TIDAK SAH',                               'en': 'INVALID'},
    'legalReview'    : {'id': 'PERLU DIKAJI',                            'en': 'NEEDS REVIEW'},
    'legalDisclaimer': {'id': '⚠️ Analisis ini bersifat informatif. Untuk kepastian hukum, konsultasikan dengan advokat/pengacara.',
                        'en': '⚠️ This is informational only. For legal certainty, consult a qualified attorney.'},
    'trendingLoading': {'id': 'Memuat ancaman terbaru...',               'en': 'Loading latest threats...'},
    'trendingRefresh': {'id': 'Diperbarui setiap 24 jam',                'en': 'Updated every 24 hours'},
  };

  static String get(String key, String lang) =>
      _data[key]?[lang] ?? _data[key]?['en'] ?? key;
}
