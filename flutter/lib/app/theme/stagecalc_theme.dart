import 'package:flutter/material.dart';

import 'greencrew_colors.dart';

class StageCalcTheme {
  const StageCalcTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: GreenCrewColors.primary,
      onPrimary: Colors.black,
      secondary: GreenCrewColors.primaryLight,
      surface: GreenCrewColors.surface,
      error: GreenCrewColors.error,
      onError: Colors.black,
      onSurface: GreenCrewColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: GreenCrewColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: GreenCrewColors.background,
        foregroundColor: GreenCrewColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: GreenCrewColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GreenCrewColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GreenCrewColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GreenCrewColors.textPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: GreenCrewColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GreenCrewColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GreenCrewColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GreenCrewColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GreenCrewColors.primary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: GreenCrewColors.surface,
        indicatorColor: GreenCrewColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? GreenCrewColors.primary
                : GreenCrewColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: GreenCrewColors.surface,
        selectedIconTheme: IconThemeData(color: GreenCrewColors.primary),
        selectedLabelTextStyle: TextStyle(color: GreenCrewColors.primary),
        unselectedIconTheme: IconThemeData(
          color: GreenCrewColors.textSecondary,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: GreenCrewColors.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GreenCrewColors.border,
        thickness: 1,
      ),
    );
  }
}
