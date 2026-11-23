import 'package:flutter/material.dart';

import '../theme.dart';

/// An ElevatedButton with a gradient fill, glow, press animation and loading state.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.onPressed != null;
    final clickable = active && !widget.loading;
    final radius = BorderRadius.circular(18);

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && clickable ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (active)
                BoxShadow(
                  color: AppColors.violet.withOpacity(0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: ElevatedButton(
            onPressed: clickable ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: active ? AppColors.brandGradient : AppColors.mutedGradient,
                borderRadius: radius,
              ),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: widget.loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.bgDeep),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  color: AppColors.bgDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (widget.icon != null) ...[
                                const SizedBox(width: 10),
                                Icon(widget.icon, color: AppColors.bgDeep, size: 20),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
