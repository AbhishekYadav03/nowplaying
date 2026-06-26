import 'package:flutter/material.dart';

import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_tracker_model.dart';

class PeriodInsightsSection extends StatelessWidget {
  final List<PeriodLogModel> logs;

  const PeriodInsightsSection({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    double avgLength = 28;
    if (logs.length >= 2) {
      int totalDays = 0;
      for (int i = 0; i < logs.length - 1; i++) {
        totalDays += logs[i].startDate.difference(logs[i + 1].startDate).inDays;
      }
      avgLength = totalDays / (logs.length - 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _InsightRow(label: 'Previous cycles', value: logs.length.toString()),
              const Divider(height: 24),
              _InsightRow(label: 'Average cycle length', value: '${avgLength.toStringAsFixed(1)} days'),
              const Divider(height: 24),
              _InsightRow(label: 'Cycle consistency', value: logs.length < 3 ? 'Calculating...' : 'Moderate'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;

  const _InsightRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

