
import 'package:flutter/material.dart';

import 'package:nowplaying/models/period_tracker_model.dart';

enum CyclePhase {
  menstrual(
    'Menstrual',
    'Period phase is active.',
  ),
  follicular(
    'Follicular',
    'Getting ready for ovulation.',
  ),
  fertile(
    'Fertile',
    'Fertility window is active.',
  ),
  ovulation(
    'Ovulation',
    'Peak fertility day.',
  ),
  luteal(
    'Luteal',
    'Preparing for the next cycle.',
  );

  final String name;
  final String description;

  const CyclePhase(this.name, this.description);
}
extension CyclePhaseStyle on CyclePhase {
  Color get color => switch (this) {
    CyclePhase.menstrual  => const Color(0xFFE91E8C),
    CyclePhase.follicular => const Color(0xFF9C27B0),
    CyclePhase.fertile    => const Color(0xFF00BCD4),
    CyclePhase.ovulation  => const Color(0xFF4CAF50),
    CyclePhase.luteal     => const Color(0xFFFF9800),
  };

  Color get backgroundColor => color.withValues(alpha: 0.12);
  Color get borderColor     => color.withValues(alpha: 0.35);

  IconData get icon => switch (this) {
    CyclePhase.menstrual  => Icons.water_drop_rounded,
    CyclePhase.follicular => Icons.eco_rounded,
    CyclePhase.fertile    => Icons.favorite_rounded,
    CyclePhase.ovulation  => Icons.stars_rounded,
    CyclePhase.luteal     => Icons.nightlight_round,
  };

  /// Returns the phase for a given calendar day.
  static CyclePhase? fromDayState({
    required bool isPredicted,
    required bool isOvulation,
    required bool isFertile,
    required bool isFollicular,
    required bool isLuteal,
  }) {
    if (isPredicted)  return CyclePhase.menstrual;
    if (isOvulation)  return CyclePhase.ovulation;
    if (isFertile)    return CyclePhase.fertile;
    if (isFollicular) return CyclePhase.follicular;
    if (isLuteal)     return CyclePhase.luteal;
    return null;
  }
}

class PeriodLogic {
  /// Normalizes a DateTime to midnight (date-only), stripping the time component.
  static DateTime _toDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Returns the start of the cycle that contains [today], based on [lastStart].
  static DateTime _currentCycleStart(
      DateTime lastStart,
      DateTime today,
      int cycleLength,
      ) {
    final diff = today.difference(lastStart).inDays;
    if (diff < 0) return lastStart; // today is before lastStart
    final cyclesPassed = diff ~/ cycleLength;
    return lastStart.add(Duration(days: cyclesPassed * cycleLength));
  }

  static Map<String, dynamic> calculateCycleInfo(
      PeriodTrackerModel settings,
      ) {
    final lastPeriodStart = settings.lastPeriodStart;
    if (lastPeriodStart == null) return {};

    final today = _toDate(DateTime.now());
    final lastStart = _toDate(lastPeriodStart);

    final cycleLength = settings.cycleLength;
    final periodDuration = settings.periodDuration;

    // Current cycle day (1-based)
    final diff = today.difference(lastStart).inDays;
    final cycleDay = (diff % cycleLength) + 1;

    // Current cycle start and next period
    final currentCycleStart =
    _currentCycleStart(lastStart, today, cycleLength);
    final nextPeriodStart =
    currentCycleStart.add(Duration(days: cycleLength));
    final daysUntilNext = nextPeriodStart.difference(today).inDays;

    // Ovulation: 14 days before next period (cycle-day, 1-based)
    final ovulationDay = cycleLength - 14;

    // Ovulation date (Day 1 = currentCycleStart, so offset = ovulationDay - 1)
    final ovulationDate =
    currentCycleStart.add(Duration(days: ovulationDay - 1));

    // Fertile window: 5 days before ovulation through 1 day after (cycle-days)
    final fertileStartDay = ovulationDay - 5;
    final fertileEndDay = ovulationDay + 1;

    // Determine phase — order matters: menstrual → ovulation → fertile → follicular → luteal
    CyclePhase phase;

    if (cycleDay <= periodDuration) {
      phase = CyclePhase.menstrual;
    } else if (cycleDay == ovulationDay) {
      // FIX: ovulation is a single day, not the whole fertile window
      phase = CyclePhase.ovulation;
    } else if (cycleDay >= fertileStartDay && cycleDay <= fertileEndDay) {
      // FIX: days around ovulation are the fertile phase
      phase = CyclePhase.fertile;
    } else if (cycleDay < fertileStartDay) {
      phase = CyclePhase.follicular;
    } else {
      phase = CyclePhase.luteal;
    }

    return {
      'cycleDay': cycleDay,
      'phase': phase,
      'nextPeriodStart': nextPeriodStart,
      'daysUntilNext': daysUntilNext,
      'ovulationDate': ovulationDate,
      'fertileStart': currentCycleStart.add(
        Duration(days: fertileStartDay - 1),
      ),
      'fertileEnd': currentCycleStart.add(
        Duration(days: fertileEndDay - 1),
      ),
    };
  }

  static List<DateTime> getPredictedPeriodDays(
      PeriodTrackerModel settings,
      DateTime month,
      ) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    // FIX: normalize to midnight
    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);

    // FIX: jump to the cycle closest to the target month instead of always
    // starting from cycle 0, so old lastPeriodStart values still work.
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex =
    (daysDiff ~/ settings.cycleLength - 1).clamp(0, double.maxFinite.toInt());

    final Set<DateTime> days = {};

    for (int i = startCycleIndex; i < startCycleIndex + 3; i++) {
      final cycleStart = normalizedStart.add(
        Duration(days: i * settings.cycleLength),
      );

      for (int d = 0; d < settings.periodDuration; d++) {
        final day = cycleStart.add(Duration(days: d));

        if (day.month == month.month && day.year == month.year) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }

  static List<DateTime> getFertileWindow(
      PeriodTrackerModel settings,
      DateTime month,
      ) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    // FIX: normalize to midnight
    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);
    final ovulationOffset = settings.cycleLength - 14;

    // FIX: jump to nearest cycle
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex =
    (daysDiff ~/ settings.cycleLength - 1).clamp(0, double.maxFinite.toInt());

    final Set<DateTime> days = {};

    for (int i = startCycleIndex; i < startCycleIndex + 3; i++) {
      final cycleStart = normalizedStart.add(
        Duration(days: i * settings.cycleLength),
      );

      final ovulationDate = cycleStart.add(
        Duration(days: ovulationOffset - 1),
      );

      for (int d = -5; d <= 1; d++) {
        final day = ovulationDate.add(Duration(days: d));

        if (day.month == month.month && day.year == month.year) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }

  static List<DateTime> getOvulationWindow(
      PeriodTrackerModel settings,
      DateTime month,
      ) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    // FIX: normalize to midnight
    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);
    final ovulationOffset = settings.cycleLength - 14;

    // FIX: jump to nearest cycle
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex =
    (daysDiff ~/ settings.cycleLength - 1).clamp(0, double.maxFinite.toInt());

    final Set<DateTime> days = {};

    for (int i = startCycleIndex; i < startCycleIndex + 3; i++) {
      final cycleStart = normalizedStart.add(
        Duration(days: i * settings.cycleLength),
      );

      final ovulationDate = cycleStart.add(
        Duration(days: ovulationOffset - 1),
      );

      // FIX: symmetric ±1 window (3 days: day before, ovulation day, day after)
      for (int d = -1; d <= 1; d++) {
        final day = ovulationDate.add(Duration(days: d));

        if (day.month == month.month && day.year == month.year) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }
}