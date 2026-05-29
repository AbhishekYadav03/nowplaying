import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/cycle_mood_section.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_tracker_model.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';
import 'package:nowplaying/features/period_tracker/domain/period_logic.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_dashboard.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_calendar.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_phases_section.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_insights_section.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_status_widgets.dart';
import 'package:nowplaying/features/period_tracker/presentation/widgets/period_dialogs.dart';

class PeriodTrackerScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const PeriodTrackerScreen({super.key, required this.userId, required this.userName});

  @override
  ConsumerState<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends ConsumerState<PeriodTrackerScreen> {
  DateTime _selectedMonth = DateTime.now();
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get _isOwnTracker => _myUid == widget.userId;

  Future<void> _handleRefresh() async {
    ref.invalidate(userStreamProvider(_myUid));
    ref.invalidate(periodTrackerStreamProvider(widget.userId));
    ref.invalidate(periodLogsStreamProvider(widget.userId));
    await ref.read(periodTrackerStreamProvider(widget.userId).future).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(userStreamProvider(_myUid));
    final trackerAsync = ref.watch(periodTrackerStreamProvider(widget.userId));
    final logsAsync = ref.watch(periodLogsStreamProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnTracker ? 'My Period Tracker' : "${widget.userName}'s Tracker"),
        actions: [
          if (currentUserAsync.value != null)
            _SettingsAction(
              userId: widget.userId,
              isOwnTracker: _isOwnTracker,
              currentUser: currentUserAsync.value!,
              onPressed: () => _showSettingsSheet(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: currentUserAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => PeriodErrorState(message: e.toString()),
          data: (currentUser) {
            final bool isPartner = currentUser?.partnerId == widget.userId;
            final bool canEdit = _isOwnTracker || isPartner;

            if (!_isOwnTracker && !isPartner) {
              return const PeriodPrivacyState();
            }

            return trackerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => PeriodErrorState(message: e.toString()),
              data: (settings) {
                final effectiveSettings = settings ?? const PeriodTrackerModel();
                final info = PeriodLogic.calculateCycleInfo(effectiveSettings);
                final hasData = settings != null && settings.lastPeriodStart != null;
                final currentPhase = info['phase'] as CyclePhase?;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!hasData)
                      PeriodEmptyState(
                        canEdit: canEdit,
                        userName: widget.userName,
                        isOwnTracker: _isOwnTracker,
                        onLogPeriod: () => _showLogPeriodSheet(context),
                        onConfigureCycle: () => _showSettingsSheet(context),
                      )
                    else ...[
                      PeriodDashboard(info: info),
                      const SizedBox(height: 28),
                      PeriodCalendar(
                        settings: effectiveSettings,
                        selectedMonth: _selectedMonth,
                        onMonthChanged: (month) => setState(() => _selectedMonth = month),
                      ),
                      const SizedBox(height: 28),
                      PeriodPhasesSection(currentPhase: currentPhase),
                      const SizedBox(height: 28),
                      PeriodInsightsSection(logs: logsAsync.value ?? []),
                      if (currentPhase != null) ...[
                        CycleMoodSection(phase: currentPhase, isOwner: _isOwnTracker)
                      ]
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: currentUserAsync.value != null && (_isOwnTracker || currentUserAsync.value!.partnerId == widget.userId)
          ? FloatingActionButton.extended(
              onPressed: () => _showLogPeriodSheet(context),
              label: const Text('Log Period'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFFE91E8C),
            )
          : null,
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final tracker = ref.read(periodTrackerStreamProvider(widget.userId)).value ?? const PeriodTrackerModel();
    int cycleLength = tracker.cycleLength;
    int duration = tracker.periodDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tracker Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              PeriodNumberPicker(
                label: 'Average Cycle Length',
                value: cycleLength,
                min: 20,
                max: 45,
                onChanged: (v) => setSheetState(() => cycleLength = v),
              ),
              const SizedBox(height: 20),
              PeriodNumberPicker(
                label: 'Average Period Duration',
                value: duration,
                min: 2,
                max: 10,
                onChanged: (v) => setSheetState(() => duration = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).updatePeriodTracker(
                          widget.userId,
                          tracker.copyWith(cycleLength: cycleLength, periodDuration: duration),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogPeriodSheet(BuildContext context) {
    final settings = ref.read(periodTrackerStreamProvider(widget.userId)).value ?? const PeriodTrackerModel();

    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(Duration(days: settings.periodDuration - 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Period', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              PeriodDatePickerTile(label: 'Start Date', date: start, onPick: (date) => setSheetState(() => start = date)),
              const SizedBox(height: 16),
              PeriodDatePickerTile(label: 'End Date', date: end, onPick: (date) => setSheetState(() => end = date)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E8C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (end.isBefore(start)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('End date cannot be before start date')),
                        );
                      }
                      return;
                    }
                    final log = PeriodLogModel(id: '', startDate: start, endDate: end, createdAt: DateTime.now());
                    await ref.read(firestoreServiceProvider).addPeriodLog(widget.userId, log);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  final String userId;
  final bool isOwnTracker;
  final dynamic currentUser;
  final VoidCallback onPressed;

  const _SettingsAction({
    required this.userId,
    required this.isOwnTracker,
    required this.currentUser,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPartner = currentUser.partnerId == userId;
    if (isOwnTracker || isPartner) {
      return IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: onPressed,
      );
    }
    return const SizedBox.shrink();
  }
}

// Providers
final periodTrackerStreamProvider = StreamProvider.family<PeriodTrackerModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).periodTrackerStream(uid);
});

final periodLogsStreamProvider = StreamProvider.family<List<PeriodLogModel>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).periodLogsStream(uid);
});
