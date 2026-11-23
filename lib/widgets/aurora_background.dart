import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Slowly drifting, glowing color blobs behind the content.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.subtle = false});
  final Widget child;
  final bool subtle;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _AuroraPainter(_c, widget.subtle ? 0.55 : 1)),
            ),
          ),
          widget.child,
        ],
      );
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.anim, this.strength) : super(repaint: anim);
  final Animation<double> anim;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.bg);
    final t = anim.value * 2 * pi;
    final w = size.width, h = size.height, m = max(w, h);

    void blob(Offset center, double radius, Color color, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          color.withOpacity(alpha * strength),
          color.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(Offset(w * (0.15 + 0.12 * sin(t)), h * (0.12 + 0.06 * cos(t))), m * 0.55, AppColors.violet, 0.45);
    blob(Offset(w * (0.9 + 0.08 * cos(t)), h * (0.35 + 0.08 * sin(t * 2))), m * 0.42, AppColors.peach, 0.22);
    blob(Offset(w * (0.4 + 0.15 * sin(t + 2)), h * (0.95 + 0.04 * cos(t))), m * 0.5, AppColors.lilac, 0.2);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.strength != strength;
}
