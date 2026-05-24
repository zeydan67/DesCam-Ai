import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<Color>? gradientBorder;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key, required this.child,
    this.padding, this.radius = 16,
    this.gradientBorder, this.width, this.height, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Performance Optimization: BackdropFilter is extremely expensive on Flutter Web (CanvasKit).
    // We disable it on web or keep it very light to ensure 60fps stability.
    final blurSigma = kIsWeb ? 0.0 : 10.0;
    
    Widget inner = ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width:  gradientBorder != null ? null : width,
          height: gradientBorder != null ? null : height,
          decoration: BoxDecoration(
            color: gradientBorder != null
                ? AppColors.navyLight.withOpacity(kIsWeb ? 0.85 : 0.45)
                : AppColors.glassBg.withOpacity(kIsWeb ? 0.40 : 0.20),
            borderRadius: BorderRadius.circular(radius - 1.5),
            border: gradientBorder == null
                ? Border(
                    top: BorderSide(color: Colors.white.withOpacity(kIsWeb ? 0.25 : 0.15), width: 1),
                    left: BorderSide(color: Colors.white.withOpacity(kIsWeb ? 0.25 : 0.15), width: 1),
                    right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                  )
                : null,
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (gradientBorder != null) {
      inner = Container(
        width: width, height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientBorder!,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(padding: const EdgeInsets.all(1.5), child: inner),
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: inner)
        : inner;
  }
}
