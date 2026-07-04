import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/services/analysis_service.dart';
import '../core/services/gemini_service.dart';
import '../core/services/trending_service.dart';
import '../core/models/analysis_result.dart';
import '../core/models/trending_threat.dart';

enum AnalysisState { idle, loading, success, error }

class AnalysisProvider extends ChangeNotifier {
  AnalysisService _svc;
  AnalysisProvider(this._svc) {
    _loadTrending();
  }

  void updateService(AnalysisService svc) {
    _svc = svc;
    // Refresh trending jika API key berganti
    _loadTrending(force: true);
    notifyListeners();
  }

  AnalysisState _state         = AnalysisState.idle;
  AnalysisResult? _result;
  String? _errorMessage;
  bool _trendingLoading        = false;

  AnalysisState get state      => _state;
  AnalysisResult? get result   => _result;
  String? get errorMessage     => _errorMessage;
  bool get isMockService       => _svc.isMock;
  bool get trendingLoading     => _trendingLoading;

  // ── Trending Threats (diisi dari TrendingThreatService) ─────────────────
  List<TrendingThreat> _threats = [];
  List<TrendingThreat> get trendingThreats => _threats;

  Future<void> _loadTrending({bool force = false}) async {
    if (_trendingLoading && !force) return;
    _trendingLoading = true;

    String apiKey = '';
    if (_svc is GeminiAnalysisService) {
      apiKey = (_svc as GeminiAnalysisService).apiKey;
    }

    final service = TrendingThreatService(apiKey: apiKey);
    try {
      final result = await service.fetch();
      _threats        = result;
      _trendingLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[DesCam] Trending load failed: $e');
      _trendingLoading = false;
      if (_threats.isEmpty) {
        _threats = TrendingThreatService.getFallback();
      }
      notifyListeners();
    }
  }

  /// Paksa refresh trending (panggil dari pull-to-refresh UI)
  Future<void> refreshTrending() => _loadTrending(force: true);

  Future<void> analyze({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async {
    if ((text == null || text.trim().isEmpty) && fileBytes == null) return;
    _state        = AnalysisState.loading;
    _result       = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _result = await _svc.analyze(
        type    : type,
        text    : text,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileName: fileName,
      );
      _state = AnalysisState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state        = AnalysisState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state        = AnalysisState.idle;
    _result       = null;
    _errorMessage = null;
    notifyListeners();
  }
}
