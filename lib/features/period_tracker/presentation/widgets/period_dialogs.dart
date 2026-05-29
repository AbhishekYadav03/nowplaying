import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/core/theme/theme.dart';

class PeriodDatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final Function(DateTime) onPick;

  const PeriodDatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(date)),
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PeriodNumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Function(int) onChanged;

  const PeriodNumberPicker({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                activeColor: const Color(0xFFE91E8C),
                label: value.toString(),
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }
}
