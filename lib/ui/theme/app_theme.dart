import 'package:flutter/material.dart';

/// Semantic Material Design 3 Palette accessor
@immutable
class M3Palette {
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textMuted;
  final Color error;
  final Color canvasGridDots;
  final bool isDark;

  // Compatibility properties for component accessors
  Color get canvasBg => surface;
  Color get primaryAccent => primary;
  Color get secondaryAccent => secondary;
  Color get surfaceBg => surfaceContainer;
  Color get lightShadow => Colors.transparent;
  Color get darkShadow => Colors.transparent;
  Color get alertColor => error;
  Color get successColor => const Color(0xFF00E676);

  const M3Palette({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textMuted,
    required this.error,
    required this.canvasGridDots,
    required this.isDark,
  });

  static M3Palette of(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return M3Palette(
      surface: cs.surface,
      surfaceContainer: cs.surfaceContainer,
      surfaceContainerHigh: cs.surfaceContainerHigh,
      primary: cs.primary,
      secondary: cs.secondary,
      textPrimary: cs.onSurface,
      textMuted: cs.onSurfaceVariant,
      error: cs.error,
      canvasGridDots: cs.onSurfaceVariant.withValues(alpha: isDark ? 0.18 : 0.28),
      isDark: isDark,
    );
  }

  static const light = M3Palette(
    surface: Color(0xFFFEF7FF),
    surfaceContainer: Color(0xFFF7F2FA),
    surfaceContainerHigh: Color(0xFFECE6F0),
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFF00BFA5),
    textPrimary: Color(0xFF1D1B20),
    textMuted: Color(0xFF49454F),
    error: Color(0xFFB3261E),
    canvasGridDots: Color(0x3B49454F),
    isDark: false,
  );

  static const dark = M3Palette(
    surface: Color(0xFF141218),
    surfaceContainer: Color(0xFF211F26),
    surfaceContainerHigh: Color(0xFF2B2930),
    primary: Color(0xFFD0BCFF),
    secondary: Color(0xFF64FFDA),
    textPrimary: Color(0xFFE6E0E9),
    textMuted: Color(0xFFCAC4D0),
    error: Color(0xFFF2B8B5),
    canvasGridDots: Color(0x28CAC4D0),
    isDark: true,
  );
}

// Backward compatibility alias
typedef NeumorphicPalette = M3Palette;

class NeumorphicShadows {
  static List<BoxShadow> raised(dynamic palette, {double distance = 6.0, double blur = 12.0}) => const [];
  static List<BoxShadow> pressed(dynamic palette, {double distance = 3.0, double blur = 6.0}) => const [];
  static List<BoxShadow> inset(dynamic palette, {double distance = 3.0, double blur = 6.0}) => const [];
  static List<BoxShadow> dialog(dynamic palette, {double blur = 20.0, double spread = 0.0}) => const [];
}

class AppTheme {
  // Vibrant Electric Violet seed color
  static const Color seedColor = Color(0xFF7C4DFF);

  static const List<Color> presetColors = [
    Color(0xFF7C4DFF), // Electric Violet
    Color(0xFF651FFF), // Deep Indigo
    Color(0xFF00BFA5), // Vivid Emerald Teal
    Color(0xFF00E676), // Bright Neon Mint
    Color(0xFFFF1744), // Bright Crimson Coral
    Color(0xFFFF5252), // Warm Coral
    Color(0xFFFF9100), // Vivid Orange
    Color(0xFFFFC400), // Golden Amber
    Color(0xFFAEEA00), // Vivid Lime
    Color(0xFF00E5FF), // Glowing Cyan
    Color(0xFFD500F9), // Neon Magenta
    Color(0xFFAA00FF), // Deep Violet
  ];

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      secondary: const Color(0xFF00BFA5), // Electric Teal
      tertiary: const Color(0xFFFF5252),  // Coral Accent
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      secondary: const Color(0xFF64FFDA), // Vivid Teal Cyan
      tertiary: const Color(0xFFFF8A80),  // Vivid Rose
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
