import 'dart:math' as math;

/// Headphone sound-exposure model — a 1:1 mirror of `ExposureMath.kt` so the UI and the
/// background alerts always agree.
///
/// Based on WHO/ITU-T H.870 "Safe listening devices and systems": the adult reference weekly
/// allowance is 1.6 Pa²h — 80 dB(A) for 40 hours a week — with the equal-energy rule
/// (every +3 dB halves the safe listening time).
///
/// Levels are *estimates*: calibrated maximum output of the headphones (default 100 dB(A)) plus
/// the attenuation of the current volume step on Android's volume curve.
class ExposureMath {
  ExposureMath._();

  static const double referenceDb = 80.0;
  static const double referenceWeeklyHours = 40.0;
  static const double mutedDb = -96.0;
  static const double defaultMaxOutputDb = 100.0;

  /// Levels at/above this are shown as "loud" in the UI.
  static const double cautionDb = 80.0;
  static const double dangerDb = 90.0;

  static double estimatedDb(double maxOutputDb, double? attenuationDb) {
    if (attenuationDb == null || attenuationDb <= mutedDb) return 0;
    return math.max(0, maxOutputDb + attenuationDb);
  }

  static double weeklyAllowanceHours(double db) =>
      referenceWeeklyHours * math.pow(10, (referenceDb - db) / 10).toDouble();

  /// Recommended daily listening time at [db] (a seventh of the weekly allowance).
  static Duration dailyAllowance(double db) {
    if (db <= 0) return const Duration(days: 1);
    final hours = weeklyAllowanceHours(db) / 7;
    return Duration(minutes: math.min(24 * 60, (hours * 60).round()));
  }

  /// Fraction of the weekly allowance used by listening for [duration] at [db].
  static double doseFraction(double db, Duration duration) {
    if (db <= 0 || duration <= Duration.zero) return 0;
    final hours = duration.inMilliseconds / 3600000.0;
    return hours / weeklyAllowanceHours(db);
  }

  /// Sound energy (Pa²h) — used for the time-weighted equivalent level (Leq).
  static double energy(double db, Duration duration) {
    final pressure = 20e-6 * math.pow(10, db / 20);
    return pressure * pressure * duration.inMilliseconds / 3600000.0;
  }

  /// Equivalent continuous level for a total [energyPa2h] spread over [duration].
  static double leq(double energyPa2h, Duration duration) {
    if (energyPa2h <= 0 || duration <= Duration.zero) return 0;
    final hours = duration.inMilliseconds / 3600000.0;
    final meanSquare = energyPa2h / hours;
    return 10 * math.log(meanSquare / (20e-6 * 20e-6)) / math.ln10;
  }
}
