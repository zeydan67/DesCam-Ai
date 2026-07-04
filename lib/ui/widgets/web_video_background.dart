import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/app_colors.dart';

class WebVideoBackground extends StatefulWidget {
  final VoidCallback? onError;
  const WebVideoBackground({super.key, this.onError});
  @override
  State<WebVideoBackground> createState() => _WebVideoBackgroundState();
}

class _WebVideoBackgroundState extends State<WebVideoBackground> {
  bool _error = false;
  @override
  Widget build(BuildContext context) {
    if (_error) return Container(color: AppColors.deepNavy);
    try {
      if (kIsWeb) {
        return HtmlElementView(viewType: 'waspada-bg-video');
      }
    } catch (_) {
      _error = true;
      widget.onError?.call();
    }
    return Container(color: AppColors.deepNavy);
  }
}
