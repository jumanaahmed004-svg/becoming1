import 'dart:math';

import 'package:flutter/material.dart';

/// Wrap a form in this and call `key.currentState!.shake()` when input is wrong.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});
  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  void shake() => _c.forward(from: 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value;
          final dx = sin(t * pi * 6) * 12 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}
