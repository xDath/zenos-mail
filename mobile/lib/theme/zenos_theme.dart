import 'package:flutter/material.dart';

abstract final class ZenosColors {
  static const ground = Color(0xFF0A0C0E);
  static const secondaryGround = Color(0xFF101317);
  static const raised = Color(0xFF15191E);
  static const ink = Color(0xFFEDE7DC);
  static const secondaryInk = Color(0xFF9EA5A8);
  static const muted = Color(0xFF6C7378);
  static const amber = Color(0xFFE8913C);
  static const teal = Color(0xFF2E6B72);
  static const tealBright = Color(0xFF74AAB0);
  static const hairline = Color(0x21EDE7DC);
}

ThemeData buildZenosTheme() {
  const textTheme = TextTheme(
    displaySmall: TextStyle(
      color: ZenosColors.ink,
      fontSize: 32,
      height: 1.08,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
    ),
    headlineSmall: TextStyle(
      color: ZenosColors.ink,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.35,
    ),
    titleLarge: TextStyle(
      color: ZenosColors.ink,
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
    ),
    titleMedium: TextStyle(
      color: ZenosColors.ink,
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: ZenosColors.ink,
      fontSize: 16,
      height: 1.55,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      color: ZenosColors.secondaryInk,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      color: ZenosColors.muted,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      color: ZenosColors.ink,
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: ZenosColors.secondaryInk,
      fontSize: 12,
      height: 1.25,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: ZenosColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: ZenosColors.amber,
      secondary: ZenosColors.tealBright,
      surface: ZenosColors.secondaryGround,
      onSurface: ZenosColors.ink,
      error: Color(0xFFE06C75),
    ),
    textTheme: textTheme,
    dividerColor: ZenosColors.hairline,
    dividerTheme: const DividerThemeData(
      color: ZenosColors.hairline,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ZenosColors.secondaryGround,
      hintStyle: textTheme.bodyMedium?.copyWith(color: ZenosColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ZenosColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ZenosColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ZenosColors.amber),
      ),
    ),
  );
}
