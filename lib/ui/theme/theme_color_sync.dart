import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_color_sync_stub.dart'
    if (dart.library.js_interop) 'theme_color_sync_real.dart';

class ThemeColorSync {
  /// Synchronizes the status bar and web PWA browser bar color to blend
  /// seamlessly with the app's top bar (white for light mode, dark for dark mode),
  /// avoiding harsh contrasting lines.
  static void updateThemeColor(bool isDark) {
    // 1. Mobile / Native System Overlay Style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF141218)
            : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    // 2. Web PWA theme-color meta tag
    if (kIsWeb) {
      syncWebThemeColor(isDark);
    }
  }
}
