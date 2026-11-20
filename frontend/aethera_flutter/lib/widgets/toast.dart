import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text.dart';

enum ToastKind { info, success, error }

/// Top-centre toast (sonner equivalent).
void showToast(BuildContext context, String message,
    {ToastKind kind = ToastKind.info}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  final bg = switch (kind) {
    ToastKind.success => const Color(0xFFE3F7E8),
    ToastKind.error => const Color(0xFFFFE9E5),
    ToastKind.info => AppColors.card
  };
  final fg = switch (kind) {
    ToastKind.success => const Color(0xFF14532D),
    ToastKind.error => const Color(0xFF8A1C10),
    ToastKind.info => AppColors.foreground
  };
  final bd = switch (kind) {
    ToastKind.success => const Color(0xFFB7E4C2),
    ToastKind.error => const Color(0xFFF7C1B8),
    ToastKind.info => AppColors.border
  };
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: MediaQuery.paddingOf(ctx).top + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: bd),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Text(message,
                  style: body(size: 14, w: FontWeight.w500, color: fg)),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}
