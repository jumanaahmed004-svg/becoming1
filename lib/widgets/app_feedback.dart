import 'package:flutter/material.dart';

import '../theme.dart';

/// Floating SnackBar with an icon. Pass the messenger captured before any `await`.
void showAppSnack(
  ScaffoldMessengerState messenger,
  String message, {
  bool error = false,
  SnackBarAction? action,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      action: action,
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? AppColors.danger : AppColors.mint,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Styled AlertDialog that returns true when the user confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
  bool danger = false,
}) async {
  final color = danger ? AppColors.danger : AppColors.lilac;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(title, textAlign: TextAlign.center, style: AppText.display(22)),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.bgDeep,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  return result ?? false;
}
