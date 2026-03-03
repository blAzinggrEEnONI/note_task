import 'package:flutter/material.dart';

class AppColorScheme {
  AppColorScheme._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5B4FCF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEAE6FF),
    onPrimaryContainer: Color(0xFF16005F),
    secondary: Color(0xFF2D9CDB),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD6EEFF),
    onSecondaryContainer: Color(0xFF001E31),
    tertiary: Color(0xFFF2994A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDEB8),
    onTertiaryContainer: Color(0xFF2C1500),
    error: Color(0xFFEB5757),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF8F7FE),
    onSurface: Color(0xFF1C1B26),
    surfaceContainerLow: Color(0xFFEFEEF9),
    surfaceContainerHigh: Color(0xFFE3E1F5),
    outline: Color(0xFFCAC4D0),
    outlineVariant: Color(0xFFE6E0EC),
    inverseSurface: Color(0xFF313036),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFCBBEFF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF5B4FCF),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCBBEFF),
    onPrimary: Color(0xFF2B0096),
    primaryContainer: Color(0xFF4236B5),
    onPrimaryContainer: Color(0xFFEAE6FF),
    secondary: Color(0xFF93CEFF),
    onSecondary: Color(0xFF00344F),
    secondaryContainer: Color(0xFF004C71),
    onSecondaryContainer: Color(0xFFCCE5FF),
    tertiary: Color(0xFFFFB870),
    onTertiary: Color(0xFF472A00),
    tertiaryContainer: Color(0xFF653F00),
    onTertiaryContainer: Color(0xFFFFDEB8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF131218),
    onSurface: Color(0xFFE5E1E9),
    surfaceContainerLow: Color(0xFF1C1B21),
    surfaceContainerHigh: Color(0xFF27252D),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    inverseSurface: Color(0xFFE6E1E6),
    onInverseSurface: Color(0xFF322F37),
    inversePrimary: Color(0xFF5B4FCF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFFCBBEFF),
  );

  // Semantic priority colors (consistent across themes)
  static const priorityLow = Color(0xFF27AE60);
  static const priorityMedium = Color(0xFFF2C94C);
  static const priorityHigh = Color(0xFFF2994A);
  static const priorityUrgent = Color(0xFFEB5757);
}
