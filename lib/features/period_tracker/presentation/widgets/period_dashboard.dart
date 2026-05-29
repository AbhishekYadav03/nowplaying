import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_logic.dart';

class PeriodDashboard extends StatelessWidget {
  final Map<String, dynamic> info;

  const PeriodDashboard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final cycleDay = info['cycleDay'] as int?;
    final phase = info['phase'] as CyclePhase?;
    final daysUntilNext = info['daysUntilNext'] as int?;
    final nextPeriodStart = info['nextPeriodStart'] as DateTime?;

    final themeColor = phase?.color ?? const Color(0xFFE91E8C);
    final themeBg = phase?.backgroundColor ?? themeColor.withValues(alpha: 0.15);

    String periodText;
    if (daysUntilNext == null) {
      periodText = 'Cycle information unavailable';
    } else if (daysUntilNext > 0) {
      periodText = 'Next period in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'}';
    } else if (daysUntilNext == 0) {
      periodText = 'Period expected today';
    } else {
      periodText = 'Period may be delayed';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeBg, AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: phase?.borderColor ?? themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Cycle Day', value: cycleDay?.toString() ?? '--', icon: Icons.calendar_today_rounded, color: themeColor),
              _StatItem(label: 'Phase', value: phase?.name ?? '--', icon: phase?.icon ?? Icons.waves_rounded, color: themeColor),
            ],
          ),
          if (phase != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: phase.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: phase.borderColor, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(phase.icon, color: phase.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      phase.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.event_repeat_rounded, color: themeColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(periodText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (nextPeriodStart != null)
                      Text(
                        'Predicted: ${DateFormat('MMM d').format(nextPeriodStart)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}
