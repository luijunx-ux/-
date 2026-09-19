import 'package:flutter/material.dart';

enum LifeThemeMode { forest, obsidian, vitality }

@immutable
class LifeThemeTokens extends ThemeExtension<LifeThemeTokens> {
  const LifeThemeTokens({
    required this.mode,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceStrong,
    required this.outline,
    required this.accent,
    required this.accentSoft,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
  });

  final LifeThemeMode mode;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color surfaceStrong;
  final Color outline;
  final Color accent;
  final Color accentSoft;
  final Color glow;
  final Color textPrimary;
  final Color textSecondary;

  static const LifeThemeTokens forest = LifeThemeTokens(
    mode: LifeThemeMode.forest,
    backgroundTop: Color(0xFFBDD5C3),
    backgroundBottom: Color(0xFF315E48),
    surface: Color(0x3DFFFFFF),
    surfaceStrong: Color(0xDDF4F3E9),
    outline: Color(0x99FFFFFF),
    accent: Color(0xFF23543C),
    accentSoft: Color(0xFF91B89B),
    glow: Color(0xFFC7A65A),
    textPrimary: Color(0xFF143729),
    textSecondary: Color(0xFF496858),
  );

  static const LifeThemeTokens obsidian = LifeThemeTokens(
    mode: LifeThemeMode.obsidian,
    backgroundTop: Color(0xFF171B2B),
    backgroundBottom: Color(0xFF070A11),
    surface: Color(0x292E4265),
    surfaceStrong: Color(0xE6172030),
    outline: Color(0x475F78A4),
    accent: Color(0xFF78A9FF),
    accentSoft: Color(0xFF6B5A91),
    glow: Color(0xFFD6A85B),
    textPrimary: Color(0xFFF2F4FA),
    textSecondary: Color(0xFFB4BED1),
  );

  static const LifeThemeTokens vitality = LifeThemeTokens(
    mode: LifeThemeMode.vitality,
    backgroundTop: Color(0xFFE8F1EB),
    backgroundBottom: Color(0xFFF4F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceStrong: Color(0xFFF0F4F1),
    outline: Color(0xFFDFE7E1),
    accent: Color(0xFF176B4D),
    accentSoft: Color(0xFFE6F2EB),
    glow: Color(0xFFE6AC42),
    textPrimary: Color(0xFF17251F),
    textSecondary: Color(0xFF557064),
  );

  @override
  LifeThemeTokens copyWith({LifeThemeMode? mode}) => this;

  @override
  LifeThemeTokens lerp(covariant LifeThemeTokens? other, double t) {
    if (other == null) return this;
    return LifeThemeTokens(
      mode: t < .5 ? mode : other.mode,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom:
          Color.lerp(backgroundBottom, other.backgroundBottom, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

ThemeData buildLifeTheme(LifeThemeMode mode) {
  final LifeThemeTokens tokens = switch (mode) {
    LifeThemeMode.forest => LifeThemeTokens.forest,
    LifeThemeMode.obsidian => LifeThemeTokens.obsidian,
    LifeThemeMode.vitality => LifeThemeTokens.vitality,
  };
  final bool dark = mode == LifeThemeMode.obsidian;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: tokens.backgroundBottom,
    fontFamilyFallback: const <String>['PingFang SC', 'Microsoft YaHei'],
    textTheme: Typography.material2021().black.apply(
          bodyColor: tokens.textPrimary,
          displayColor: tokens.textPrimary,
        ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.textPrimary,
      titleTextStyle: TextStyle(
        color: tokens.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceStrong.withValues(alpha: dark ? .82 : .94),
      labelStyle: TextStyle(color: tokens.textSecondary),
      helperStyle: TextStyle(color: tokens.textSecondary),
      hintStyle: TextStyle(color: tokens.textSecondary.withValues(alpha: .75)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: tokens.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: tokens.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: tokens.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
            color: dark ? const Color(0xFFD17878) : const Color(0xFFA5534F)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(44, 50),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(44, 50),
        side: BorderSide(color: tokens.outline),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.outline),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}
