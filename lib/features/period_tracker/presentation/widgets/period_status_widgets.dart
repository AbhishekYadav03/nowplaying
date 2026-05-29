import 'package:flutter/material.dart';
import 'package:nowplaying/core/theme/theme.dart';

class PeriodPrivacyState extends StatelessWidget {
  const PeriodPrivacyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24.0),
        child: const Text(
          'Privacy Protected.\nYou can only view your own or your partner\'s tracker.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ),
    );
  }
}

class PeriodErrorState extends StatelessWidget {
  final String message;

  const PeriodErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text('Error: $message', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class PeriodEmptyState extends StatelessWidget {
  final bool canEdit;
  final String userName;
  final bool isOwnTracker;
  final VoidCallback onLogPeriod;
  final VoidCallback onConfigureCycle;

  const PeriodEmptyState({
    super.key,
    required this.canEdit,
    required this.userName,
    required this.isOwnTracker,
    required this.onLogPeriod,
    required this.onConfigureCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined, size: 80, color: const Color(0xFFE91E8C).withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          const Text('No data yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              canEdit
                  ? 'Start tracking the cycle to see predictions, fertile windows, and health insights.'
                  : 'No tracking data available for $userName yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogPeriod,
                icon: const Icon(Icons.add_rounded),
                label: Text(isOwnTracker ? 'Log My Last Period' : 'Log Period for $userName'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onConfigureCycle,
              icon: const Icon(Icons.settings_suggest_outlined),
              label: const Text('Configure Cycle Length'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
