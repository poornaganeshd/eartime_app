import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale: Manrope for display/headlines, DM Sans for body copy, JetBrains Mono for
/// technical labels and numbers.
class AppTypography {
  AppTypography._();

  /// Tests disable Google Fonts (no network, no bundled font files); the scale stays the same.
  static bool useGoogleFonts = true;

  static TextStyle _manrope(double size, FontWeight weight, {double? height, double? spacing}) =>
      _font(GoogleFonts.manrope, 'Manrope', size, weight, height: height, spacing: spacing);

  static TextStyle _dmSans(double size, FontWeight weight, {double? height, double? spacing}) =>
      _font(GoogleFonts.dmSans, 'DM Sans', size, weight, height: height, spacing: spacing);

  static TextStyle _mono(double size, FontWeight weight, {double? height, double? spacing}) =>
      _font(GoogleFonts.jetBrainsMono, 'JetBrains Mono', size, weight, height: height, spacing: spacing);

  static TextStyle _font(
    TextStyle Function({FontWeight? fontWeight, double? fontSize, double? height, double? letterSpacing}) google,
    String family,
    double size,
    FontWeight weight, {
    double? height,
    double? spacing,
  }) {
    if (useGoogleFonts) {
      return google(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing);
    }
    // Locally-registered family (tests / screenshot tooling load the TTFs themselves).
    return TextStyle(fontFamily: family, fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing);
  }

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: _manrope(56, FontWeight.w700, height: 1.05, spacing: -1.6),
      displayMedium: _manrope(40, FontWeight.w700, height: 1.1, spacing: -1.0),
      displaySmall: _manrope(32, FontWeight.w600, height: 1.15, spacing: -0.6),
      headlineLarge: _manrope(28, FontWeight.w600, height: 1.2, spacing: -0.4),
      headlineMedium: _manrope(22, FontWeight.w600, height: 1.25, spacing: -0.2),
      headlineSmall: _manrope(18, FontWeight.w600, height: 1.3),
      titleLarge: _manrope(18, FontWeight.w600, height: 1.3),
      titleMedium: _dmSans(16, FontWeight.w600, height: 1.35),
      titleSmall: _dmSans(14, FontWeight.w600, height: 1.35),
      bodyLarge: _dmSans(16, FontWeight.w400, height: 1.5),
      bodyMedium: _dmSans(14, FontWeight.w400, height: 1.45),
      bodySmall: _dmSans(12, FontWeight.w400, height: 1.4),
      labelLarge: _mono(13, FontWeight.w500, height: 1.25, spacing: 0.4),
      labelMedium: _mono(11, FontWeight.w500, height: 1.3, spacing: 1.1),
      labelSmall: _mono(10, FontWeight.w500, height: 1.3, spacing: 0.8),
    );
  }
}

/// Monospaced digits so ticking timers don't jitter.
const tabularFigures = [FontFeature.tabularFigures()];
