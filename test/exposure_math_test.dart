import 'package:eartime_app/domain/logic/exposure_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExposureMath (WHO/ITU-T H.870)', () {
    test('80 dB for 40 hours is exactly one weekly allowance', () {
      expect(ExposureMath.doseFraction(80, const Duration(hours: 40)), closeTo(1.0, 1e-9));
    });

    test('every +3 dB roughly halves the allowance', () {
      expect(ExposureMath.weeklyAllowanceHours(83), closeTo(20.05, 0.1));
      expect(ExposureMath.weeklyAllowanceHours(86), closeTo(10.05, 0.1));
      expect(ExposureMath.weeklyAllowanceHours(90), closeTo(4.0, 1e-9));
    });

    test('80 dB for 40 h is 1.6 Pa²h of energy', () {
      expect(ExposureMath.energy(80, const Duration(hours: 40)), closeTo(1.6, 1e-9));
    });

    test('Leq of a constant level is that level', () {
      const d = Duration(minutes: 30);
      expect(ExposureMath.leq(ExposureMath.energy(85, d), d), closeTo(85, 1e-6));
    });

    test('Leq of two equal-length halves is energy-weighted, not arithmetic', () {
      const half = Duration(minutes: 30);
      final e = ExposureMath.energy(70, half) + ExposureMath.energy(90, half);
      // Dominated by the louder half: 90 - 10*log10(2) ≈ 87.
      expect(ExposureMath.leq(e, const Duration(hours: 1)), closeTo(87.0, 0.1));
    });

    test('estimated level = calibrated max output + curve attenuation; muted is 0', () {
      expect(ExposureMath.estimatedDb(100, -17), 83);
      expect(ExposureMath.estimatedDb(100, ExposureMath.mutedDb), 0);
      expect(ExposureMath.estimatedDb(100, null), 0);
    });

    test('daily allowance is a seventh of the weekly allowance', () {
      expect(ExposureMath.dailyAllowance(80).inMinutes, (40 * 60 / 7).round());
      expect(ExposureMath.dailyAllowance(0), const Duration(days: 1));
    });

    test('silence contributes no dose', () {
      expect(ExposureMath.doseFraction(0, const Duration(hours: 10)), 0);
    });
  });
}
