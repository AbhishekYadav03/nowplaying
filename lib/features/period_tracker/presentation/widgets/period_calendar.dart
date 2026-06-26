import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_logic.dart';
import 'package:nowplaying/features/period_tracker/domain/period_tracker_model.dart';

class PeriodCalendar extends StatelessWidget {
  final PeriodTrackerModel settings;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const PeriodCalendar({super.key, required this.settings, required this.selectedMonth, required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(monthLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CalendarGrid(settings: settings, selectedMonth: selectedMonth),
        const SizedBox(height: 16),
        const _CalendarLegend(),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final PeriodTrackerModel settings;
  final DateTime selectedMonth;

  const _CalendarGrid({required this.settings, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday % 7;

    final info = PeriodLogic.calculateCycleInfo(settings);
    final ovulationDate = info['ovulationDate'] as DateTime?;
    final fertileStart = info['fertileStart'] as DateTime?;
    final fertileEnd = info['fertileEnd'] as DateTime?;

    final predictedDays = PeriodLogic.getPredictedPeriodDays(settings, selectedMonth);
    final follicularDays = PeriodLogic.getFollicularDays(settings, selectedMonth);
    final lutealDays = PeriodLogic.getLutealDays(settings, selectedMonth);

    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth + firstDayOfWeek,
      itemBuilder: (context, index) {
        if (index < firstDayOfWeek) return const SizedBox.shrink();

        final day = index - firstDayOfWeek + 1;
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);

        final isToday = DateUtils.isSameDay(date, today);
        final isPredicted = predictedDays.any((d) => DateUtils.isSameDay(d, date));
        final isOvulation = ovulationDate != null && DateUtils.isSameDay(ovulationDate, date);
        final isFertile =
            fertileStart != null &&
            fertileEnd != null &&
            !date.isBefore(fertileStart) &&
            !date.isAfter(fertileEnd) &&
            !isOvulation;
        final isFollicular = follicularDays.any((d) => DateUtils.isSameDay(d, date));
        final isLuteal = lutealDays.any((d) => DateUtils.isSameDay(d, date));

        final phase = CyclePhaseStyle.fromDayState(
          isPredicted: isPredicted,
          isOvulation: isOvulation,
          isFertile: isFertile,
          isFollicular: isFollicular,
          isLuteal: isLuteal,
        );

        Color? bg = phase?.backgroundColor;
        Color border = phase?.borderColor ?? Colors.transparent;
        double borderW = phase == CyclePhase.ovulation ? 1.8 : 1.0;
        Color textCol = phase?.color ?? AppColors.textSecondary;
        FontWeight weight = (isToday || isOvulation) ? FontWeight.w600 : FontWeight.normal;

        if (isToday) {
          bg = AppColors.primary.withValues(alpha: 0.15);
          border = AppColors.primary.withValues(alpha: 0.5);
          textCol = AppColors.textPrimary;
          weight = FontWeight.w600;
        }

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border, width: borderW),
          ),
          alignment: Alignment.center,
          child: Text(
            day.toString(),
            style: TextStyle(fontSize: 13, color: textCol, fontWeight: weight),
          ),
        );
      },
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...CyclePhase.values.map(
            (phase) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _LegendItem(label: phase.name, color: phase.backgroundColor, borderColor: phase.borderColor),
            ),
          ),
          _LegendItem(
            label: 'Today',
            color: AppColors.primary.withValues(alpha: 0.15),
            borderColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Color? borderColor;

  const _LegendItem({
    required this.label,
    required this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }
}

