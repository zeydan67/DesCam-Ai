import 'package:flutter/material.dart';

class GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(opacity * 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
}
