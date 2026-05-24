import 'dart:typed_data';
import '../models/analysis_result.dart';

abstract class AnalysisService {
  bool get isMock;
  Future<AnalysisResult> analyze({
    required String type,
    String? text,
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  });
}