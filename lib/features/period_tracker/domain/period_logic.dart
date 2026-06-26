import 'package:flutter/material.dart';

import 'package:nowplaying/features/period_tracker/domain/period_tracker_model.dart';

class CycleMood {
  const CycleMood({
    required this.label,
    required this.emoji,
    required this.intensity, // 1–3: mild, moderate, strong
  });

  final String label;
  final String emoji;
  final int intensity;
}

extension CyclePhaseMoods on CyclePhase {
  List<CycleMood> get moods => switch (this) {
    CyclePhase.menstrual => const [
      CycleMood(label: 'Fatigued',    emoji: '😴', intensity: 3),
      CycleMood(label: 'Crampy',      emoji: '🤕', intensity: 3),
      CycleMood(label: 'Irritable',   emoji: '😤', intensity: 2),
      CycleMood(label: 'Introverted', emoji: '🫂', intensity: 2),
      CycleMood(label: 'Emotional',   emoji: '🥺', intensity: 2),
    ],
    CyclePhase.follicular => const [
      CycleMood(label: 'Energetic',   emoji: '⚡', intensity: 2),
      CycleMood(label: 'Optimistic',  emoji: '🌱', intensity: 2),
      CycleMood(label: 'Creative',    emoji: '🎨', intensity: 2),
      CycleMood(label: 'Social',      emoji: '💬', intensity: 1),
      CycleMood(label: 'Motivated',   emoji: '🚀', intensity: 1),
    ],
    CyclePhase.fertile => const [
      CycleMood(label: 'Confident',   emoji: '✨', intensity: 2),
      CycleMood(label: 'Flirty',      emoji: '💃', intensity: 2),
      CycleMood(label: 'Adventurous', emoji: '🌟', intensity: 2),
      CycleMood(label: 'Talkative',   emoji: '🗣️', intensity: 1),
      CycleMood(label: 'Radiant',     emoji: '☀️', intensity: 1),
    ],
    CyclePhase.ovulation => const [
      CycleMood(label: 'Peak Energy', emoji: '🔥', intensity: 3),
      CycleMood(label: 'Sharp',       emoji: '🎯', intensity: 3),
      CycleMood(label: 'Outgoing',    emoji: '🤝', intensity: 2),
      CycleMood(label: 'Driven',      emoji: '💪', intensity: 2),
      CycleMood(label: 'Joyful',      emoji: '😄', intensity: 2),
    ],
    CyclePhase.luteal => const [
      CycleMood(label: 'Sensitive',   emoji: '💭', intensity: 2),
      CycleMood(label: 'Bloated',     emoji: '🫠', intensity: 2),
      CycleMood(label: 'Anxious',     emoji: '😰', intensity: 2),
      CycleMood(label: 'Craving',     emoji: '🍫', intensity: 3),
      CycleMood(label: 'Reflective',  emoji: '🌙', intensity: 1),
    ],
  };
  String moodSummary({bool isOwner = true}) => isOwner
      ? _ownerSummary
      : _viewerSummary;

  String get _ownerSummary => switch (this) {
    CyclePhase.menstrual  => 'Rest up — your body is working hard.',
    CyclePhase.follicular => 'Great time to start new projects.',
    CyclePhase.fertile    => 'You\'re at your most magnetic.',
    CyclePhase.ovulation  => 'Peak performance window.',
    CyclePhase.luteal     => 'Be gentle with yourself.',
  };

  String get _viewerSummary => switch (this) {
    CyclePhase.menstrual  => 'She may need extra rest and comfort right now.',
    CyclePhase.follicular => 'She\'s feeling refreshed and ready for new things.',
    CyclePhase.fertile    => 'She\'s at her most social and energetic.',
    CyclePhase.ovulation  => 'Her energy and confidence are at their peak.',
    CyclePhase.luteal     => 'She might need a little extra patience and care.',
  };
}
enum CyclePhase {
  menstrual('Menstrual', 'Period phase is active.'),
  follicular('Follicular', 'Getting ready for ovulation.'),
  fertile('Fertile', 'Fertility window is active.'),
  ovulation('Ovulation', 'Peak fertility day.'),
  luteal('Luteal', 'Preparing for the next cycle.');

  final String name;
  final String description;

  const CyclePhase(this.name, this.description);
}

extension CyclePhaseStyle on CyclePhase {
  Color get color => switch (this) {
    CyclePhase.menstrual => const Color(0xFFE91E8C),
    CyclePhase.follicular => const Color(0xFF9C27B0),
    CyclePhase.fertile => const Color(0xFF00BCD4),
    CyclePhase.ovulation => const Color(0xFF4CAF50),
    CyclePhase.luteal => const Color(0xFFFF9800),
  };

  Color get backgroundColor => color.withValues(alpha: 0.12);

  Color get borderColor => color.withValues(alpha: 0.35);

  IconData get icon => switch (this) {
    CyclePhase.menstrual => Icons.water_drop_rounded,
    CyclePhase.follicular => Icons.eco_rounded,
    CyclePhase.fertile => Icons.favorite_rounded,
    CyclePhase.ovulation => Icons.stars_rounded,
    CyclePhase.luteal => Icons.nightlight_round,
  };

  /// Returns the phase for a given calendar day.
  static CyclePhase? fromDayState({
    required bool isPredicted,
    required bool isOvulation,
    required bool isFertile,
    required bool isFollicular,
    required bool isLuteal,
  }) {
    if (isPredicted) return CyclePhase.menstrual;
    if (isOvulation) return CyclePhase.ovulation;
    if (isFertile) return CyclePhase.fertile;
    if (isFollicular) return CyclePhase.follicular;
    if (isLuteal) return CyclePhase.luteal;
    return null;
  }
}

class PeriodLogic {
  /// Normalizes a DateTime to midnight (date-only), stripping the time component.
  static DateTime _toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the start of the current cycle containing [today], based on [lastStart].
  static DateTime _currentCycleStart(DateTime lastStart, DateTime today, int cycleLength) {
    final diff = today.difference(lastStart).inDays;
    if (diff < 0) return lastStart; // today is before lastStart
    final cyclesPassed = diff ~/ cycleLength;
    return lastStart.add(Duration(days: cyclesPassed * cycleLength));
  }

  static Map<String, dynamic> calculateCycleInfo(PeriodTrackerModel settings) {
    final lastPeriodStart = settings.lastPeriodStart;
    if (lastPeriodStart == null) return {};

    final today = _toDate(DateTime.now());
    final lastStart = _toDate(lastPeriodStart);

    final cycleLength = settings.cycleLength;
    final periodDuration = settings.periodDuration;

    // Current cycle day (1-based)
    final currentCycleStart = _currentCycleStart(lastStart, today, cycleLength);
    final cycleDay = today.difference(currentCycleStart).inDays + 1;

    // Next period start
    final nextPeriodStart = currentCycleStart.add(Duration(days: cycleLength));
    final daysUntilNext = nextPeriodStart.difference(today).inDays;

    // Ovulation: typically 14 days before next period
    final ovulationDay = cycleLength - 14;

    // Ovulation date (day 1 = currentCycleStart, so offset = ovulationDay - 1)
    final ovulationDate = currentCycleStart.add(Duration(days: ovulationDay - 1));

    // Fertile window: 5 days before ovulation through 1 day after
    final fertileStartDay = ovulationDay - 5;
    final fertileEndDay = ovulationDay + 1;

    // Determine phase with correct logic
    CyclePhase phase;

    if (cycleDay <= periodDuration) {
      // Menstrual phase: first N days of cycle
      phase = CyclePhase.menstrual;
    } else if (cycleDay == ovulationDay) {
      // Ovulation: single day
      phase = CyclePhase.ovulation;
    } else if (cycleDay >= fertileStartDay && cycleDay <= fertileEndDay) {
      // Fertile window (excluding ovulation day)
      phase = CyclePhase.fertile;
    } else if (cycleDay < fertileStartDay) {
      // Follicular: after period, before fertile window
      phase = CyclePhase.follicular;
    } else {
      // Luteal: after fertile window, before next period
      phase = CyclePhase.luteal;
    }

    return {
      'cycleDay': cycleDay,
      'phase': phase,
      'nextPeriodStart': nextPeriodStart,
      'daysUntilNext': daysUntilNext,
      'ovulationDate': ovulationDate,
      'fertileStart': currentCycleStart.add(Duration(days: fertileStartDay - 1)),
      'fertileEnd': currentCycleStart.add(Duration(days: fertileEndDay - 1)),
    };
  }

  static List<DateTime> getPredictedPeriodDays(PeriodTrackerModel settings, DateTime month) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);

    // Calculate which cycle index to start from based on target month
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex = (daysDiff ~/ settings.cycleLength).clamp(0, 1000);

    final Set<DateTime> days = {};

    // Check multiple cycles around the target month
    for (int i = startCycleIndex - 1; i <= startCycleIndex + 1; i++) {
      if (i < 0) continue;

      final cycleStart = normalizedStart.add(Duration(days: i * settings.cycleLength));

      for (int d = 0; d < settings.periodDuration; d++) {
        final day = cycleStart.add(Duration(days: d));

        if (day.year == month.year && day.month == month.month) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }

  static List<DateTime> getFertileWindow(PeriodTrackerModel settings, DateTime month) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);
    final ovulationOffset = settings.cycleLength - 14;

    // Calculate which cycle index to start from based on target month
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex = (daysDiff ~/ settings.cycleLength).clamp(0, 1000);

    final Set<DateTime> days = {};

    // Check multiple cycles around the target month
    for (int i = startCycleIndex - 1; i <= startCycleIndex + 1; i++) {
      if (i < 0) continue;

      final cycleStart = normalizedStart.add(Duration(days: i * settings.cycleLength));

      final ovulationDate = cycleStart.add(Duration(days: ovulationOffset - 1));

      // Fertile window: 5 days before to 1 day after ovulation
      for (int d = -5; d <= 1; d++) {
        final day = ovulationDate.add(Duration(days: d));

        if (day.year == month.year && day.month == month.month) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }

  static List<DateTime> getOvulationWindow(PeriodTrackerModel settings, DateTime month) {
    final start = settings.lastPeriodStart;
    if (start == null) return [];

    final normalizedStart = _toDate(start);
    final targetMonth = DateTime(month.year, month.month);
    final ovulationOffset = settings.cycleLength - 14;

    // Calculate which cycle index to start from based on target month
    final daysDiff = targetMonth.difference(normalizedStart).inDays;
    final startCycleIndex = (daysDiff ~/ settings.cycleLength).clamp(0, 1000);

    final Set<DateTime> days = {};

    // Check multiple cycles around the target month
    for (int i = startCycleIndex - 1; i <= startCycleIndex + 1; i++) {
      if (i < 0) continue;

      final cycleStart = normalizedStart.add(Duration(days: i * settings.cycleLength));

      final ovulationDate = cycleStart.add(Duration(days: ovulationOffset - 1));

      // Ovulation window: day before, day of, and day after ovulation
      for (int d = -1; d <= 1; d++) {
        final day = ovulationDate.add(Duration(days: d));

        if (day.year == month.year && day.month == month.month) {
          days.add(_toDate(day));
        }
      }
    }

    return days.toList()..sort();
  }

  /// Days between period end and fertile window start
  static List<DateTime> getFollicularDays(PeriodTrackerModel settings, DateTime month) {
    final info = calculateCycleInfo(settings);
    final fertileStart = info['fertileStart'] as DateTime?;
    if (fertileStart == null) return [];

    final periodDays = getPredictedPeriodDays(settings, month);
    if (periodDays.isEmpty) return [];

    // Follicular = day after last period day → day before fertile window
    final periodEnd = periodDays.last;
    final days = <DateTime>[];
    var cursor = periodEnd.add(const Duration(days: 1));

    while (cursor.isBefore(fertileStart)) {
      if (cursor.month == month.month && cursor.year == month.year) {
        days.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  /// Days between ovulation end and next period start
  static List<DateTime> getLutealDays(PeriodTrackerModel settings, DateTime month) {
    final info = calculateCycleInfo(settings);
    final ovulationDate = info['ovulationDate'] as DateTime?;
    final nextPeriodStart = info['nextPeriodStart'] as DateTime?;
    if (ovulationDate == null || nextPeriodStart == null) return [];

    final days = <DateTime>[];
    var cursor = ovulationDate.add(const Duration(days: 1));

    while (cursor.isBefore(nextPeriodStart)) {
      if (cursor.month == month.month && cursor.year == month.year) {
        days.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }
}


