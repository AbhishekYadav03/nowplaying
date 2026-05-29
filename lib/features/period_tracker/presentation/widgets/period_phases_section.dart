import 'package:flutter/material.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_logic.dart';

class PeriodPhasesSection extends StatelessWidget {
  final CyclePhase? currentPhase;

  const PeriodPhasesSection({super.key, required this.currentPhase});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cycle Phases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...CyclePhase.values.map((phase) {
          final isCurrent = phase == currentPhase;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent ? phase.backgroundColor : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? phase.color : AppColors.border,
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(phase.icon, color: phase.color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? phase.color : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(phase.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isCurrent) Icon(Icons.check_circle_rounded, color: phase.color, size: 20),
              ],
            ),
          );
        }),
      ],
    );
  }
}
