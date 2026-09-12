import 'package:flutter/material.dart';
import 'package:werkly/ui/theme/app_spacing.dart';
import 'package:werkly/ui/theme/brand_colors.dart';

/// Werkly Material 3 theme — Primary #0F766E locked (logo TBD).
abstract final class AppTheme {
  /// Locked seed: BrandColors.primary (#0F766E).
  static const seed = BrandColors.primary;

  static TextTheme _textTheme(Brightness brightness) {
    final base = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final scheme = brightness == Brightness.light
        ? base.black
        : base.white;
    return scheme.copyWith(
      titleLarge: scheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: scheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      bodyMedium: scheme.bodyMedium?.copyWith(
        fontSize: 14,
        letterSpacing: 0.25,
      ),
      bodySmall: scheme.bodySmall?.copyWith(
        fontSize: 12,
        letterSpacing: 0.4,
      ),
      labelLarge: scheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  static FilledButtonThemeData _primaryButton(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, AppSpacing.touchMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(Brightness.light),
      filledButtonTheme: _primaryButton(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme(Brightness.light).titleMedium?.copyWith(
              color: scheme.onSurface,
            ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          _textTheme(Brightness.light).labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(Brightness.dark),
      filledButtonTheme: _primaryButton(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
