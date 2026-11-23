import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Frosted-glass panel.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(24), this.radius = 28});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.stroke),
            ),
            child: child,
          ),
        ),
      );
}
