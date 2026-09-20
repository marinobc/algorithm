import 'dart:async';

import 'package:flutter/material.dart';

/// Global overlay toast manager ensuring toast messages are always rendered
/// on top of all dialogs, bottom sheets, and full-screen routes via the Root Navigator's Overlay.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? backgroundColor,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // 1. Dismiss existing active toast immediately
    dismiss();

    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.inverseSurface;
    final txtColor = backgroundColor != null
        ? textColor
        : theme.colorScheme.onInverseSurface;
    final mediaQuery = MediaQuery.of(context);

    // 2. Fetch the top-most OverlayState (root navigator overlay ensures top z-index over dialogs)
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    _currentEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: mediaQuery.padding.bottom + 24,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: txtColor, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: txtColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          dismiss();
                          action.onPressed();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          action.label,
                          style: TextStyle(
                            color: theme.colorScheme.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_currentEntry!);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
