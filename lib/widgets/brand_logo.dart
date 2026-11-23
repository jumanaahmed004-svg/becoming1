import 'package:flutter/material.dart';

import '../theme.dart';

/// The BECOMING mark: rising steps toward a sun, drawn in code.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withOpacity(0.5),
              blurRadius: size * 0.5,
              offset: Offset(0, size * 0.15),
            ),
          ],
        ),
        child: CustomPaint(painter: _StepsPainter()),
      );
}

class _StepsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.95);
    final w = size.width, h = size.height;
    final barW = w * 0.13, gap = w * 0.05, base = h * 0.76, x0 = w * 0.2;
    for (var i = 0; i < 4; i++) {
      final bh = h * (0.14 + i * 0.11);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x0 + i * (barW + gap), base - bh, barW, bh),
          Radius.circular(barW * 0.35),
        ),
        p,
      );
    }
    canvas.drawCircle(Offset(w * 0.3, h * 0.3), w * 0.075, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mark + "BECOMING" wordmark.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: size),
            const SizedBox(width: 14),
            Text('BECOMING', style: AppText.display(size * 0.5).copyWith(letterSpacing: 5)),
          ],
        ),
      );
}
