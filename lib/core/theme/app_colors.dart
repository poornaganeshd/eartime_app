import 'package:flutter/material.dart';

/// Legacy constant palette (dark). New UI code should use `context.palette` (see [EarPalette])
/// so light mode works; these remain for the developer diagnostics screens, which always render
/// in the dark theme.
class AppColors {
  static const Color obsidianDeep = Color(0xFF0B0B10);
  static const Color background = Color(0xFF111117);
  static const Color surfaceContainerHigh = Color(0xFF22222E);

  static const Color primary = Color(0xFFB8B2FF);
  static const Color secondary = Color(0xFF5BE3A0);
  static const Color warning = Color(0xFFFFC266);
  static const Color error = Color(0xFFFF8A80);

  static const Color editorialWhite = Color(0xFFF2F2F5);
  static const Color onSurfaceVariant = Color(0xFFA4A3B5);

  static const Color glassBgDark = Color.fromRGBO(28, 27, 36, 0.55);
  static const Color glassBgLight = Color.fromRGBO(255, 255, 255, 0.72);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color glassBorderLight = Color.fromRGBO(0, 0, 0, 0.07);
}

/// Semantic design tokens for EarTime, available for both brightnesses via
/// `Theme.of(context).extension<EarPalette>()` or the `context.palette` shortcut.
@immutable
class EarPalette extends ThemeExtension<EarPalette> {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentStrong;
  final Color success;
  final Color warning;
  final Color danger;
  final Color orbA;
  final Color orbB;
  final Color navBackground;

  const EarPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentStrong,
    required this.success,
    required this.warning,
    required this.danger,
    required this.orbA,
    required this.orbB,
    required this.navBackground,
  });

  static const dark = EarPalette(
    background: Color(0xFF0B0B10),
    surface: Color(0xFF15151D),
    surfaceHigh: Color(0xFF20202B),
    border: Color(0x14FFFFFF),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFFA4A3B5),
    textTertiary: Color(0xFF6E6D80),
    accent: Color(0xFFB8B2FF),
    accentStrong: Color(0xFF7C6CFF),
    // Status colours validated (OKLab CVD ΔE ≥ 8, contrast ≥ 3:1 on surface); always paired
    // with a text label/icon, never colour alone.
    success: Color(0xFF1FA56A),
    warning: Color(0xFFC48414),
    danger: Color(0xFFE2476E),
    orbA: Color(0x337C6CFF),
    orbB: Color(0x1F1FA56A),
    navBackground: Color(0xCC15151D),
  );

  static const light = EarPalette(
    background: Color(0xFFF4F4F9),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECECF4),
    border: Color(0x12000000),
    textPrimary: Color(0xFF14141C),
    textSecondary: Color(0xFF5E5D70),
    textTertiary: Color(0xFF8E8DA0),
    accent: Color(0xFF5B4BFF),
    accentStrong: Color(0xFF4332E6),
    success: Color(0xFF0F9D63),
    warning: Color(0xFFD49A0A),
    danger: Color(0xFFB8261F),
    orbA: Color(0x265B4BFF),
    orbB: Color(0x1A0F9D63),
    navBackground: Color(0xE6FFFFFF),
  );

  /// Colour for an estimated sound level: green below 80 dB, amber to 90 dB, red above.
  Color forLevel(double db) {
    if (db >= 90) return danger;
    if (db >= 80) return warning;
    return success;
  }

  /// Text label that must accompany [forLevel] (status is never colour-only).
  static String levelLabel(double db) {
    if (db <= 0) return 'Muted';
    if (db >= 90) return 'Very loud';
    if (db >= 80) return 'Loud';
    return 'Safe';
  }

  @override
  EarPalette copyWith() => this;

  @override
  EarPalette lerp(ThemeExtension<EarPalette>? other, double t) {
    if (other is! EarPalette) return this;
    return EarPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      orbA: Color.lerp(orbA, other.orbA, t)!,
      orbB: Color.lerp(orbB, other.orbB, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
    );
  }
}

extension EarPaletteContext on BuildContext {
  EarPalette get palette => Theme.of(this).extension<EarPalette>() ?? EarPalette.dark;
}
