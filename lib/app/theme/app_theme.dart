import 'package:flutter/material.dart';

abstract final class AuvorynColors {
  static const ink = Color(0xFF0B0D12);
  static const slate = Color(0xFF171A21);
  static const raised = Color(0xFF242832);
  static const ivory = Color(0xFFF4EFE7);
  static const mist = Color(0xFFA8ADB8);
  static const champagne = Color(0xFFD8B78B);
  static const dusk = Color(0xFFA79AC6);
  static const blush = Color(0xFF72535D);
}

abstract final class AuvorynSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AuvorynMotion {
  static const short = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 280);
  static const player = Duration(milliseconds: 380);
  static const atmosphere = Duration(milliseconds: 760);
  static const standardCurve = Curves.easeOutCubic;
}

abstract final class AppTheme {
  static ThemeData get dark {
    const main = AuvorynColors.ivory;
    const muted = AuvorynColors.mist;
    const textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 44, height: 1.08, color: main),
      headlineLarge: TextStyle(fontSize: 30, height: 1.18,
        fontWeight: FontWeight.w600, color: main),
      headlineMedium: TextStyle(fontSize: 26, height: 1.22,
        fontWeight: FontWeight.w600, color: main),
      titleLarge: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w600, color: main),
      titleMedium: TextStyle(fontSize: 16,
        fontWeight: FontWeight.w600, color: main),
      bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: main),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: main),
      bodySmall: TextStyle(fontSize: 13, height: 1.45, color: muted),
      labelLarge: TextStyle(fontSize: 15,
        fontWeight: FontWeight.w600, color: main),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AuvorynColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: AuvorynColors.champagne,
        onPrimary: AuvorynColors.ink,
        secondary: AuvorynColors.dusk,
        surface: AuvorynColors.slate,
        onSurface: AuvorynColors.ivory,
        error: Color(0xFFFF9F9A),
      ),
      // Instrument Serif and Manrope are optional local brand assets.
      // AUVORYN still works without them; Flutter uses system fallbacks.
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AuvorynColors.ivory, size: 22),
      dividerColor: AuvorynColors.raised,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AuvorynColors.ink,
        foregroundColor: AuvorynColors.ivory,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AuvorynColors.slate,
        modalBackgroundColor: AuvorynColors.slate,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AuvorynColors.champagne,
        inactiveTrackColor: AuvorynColors.raised,
        thumbColor: AuvorynColors.ivory,
        overlayColor: Color(0x33D8B78B),
        trackHeight: 3,
      ),
      chipTheme: ChipThemeData(
        selectedColor: AuvorynColors.raised,
        backgroundColor: AuvorynColors.slate,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: BorderSide.none,
        labelStyle: const TextStyle(color: AuvorynColors.ivory),
      ),
      cardTheme: CardThemeData(
        color: AuvorynColors.slate,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // Resilient editorial sizing: never assume a system has a specific font.
  static TextStyle trackHeading({double size = 27}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
    height: 1.16,
    color: AuvorynColors.ivory,
  );

  static TextStyle editorial({double size = 38, Color? color}) => TextStyle(
    fontFamily: 'InstrumentSerif',
    fontFamilyFallback: const ['Georgia', 'serif'],
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.09,
    color: color ?? AuvorynColors.ivory,
  );
}
