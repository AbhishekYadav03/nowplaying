import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../models/period_tracker_model.dart';
import '../../services/firestore_service.dart';
import 'period_logic.dart';

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
          _buildSettingsAction(currentUserAsync.value),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: currentUserAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (currentUser) {
            final bool isPartner = currentUser?.partnerId == widget.userId;
            final bool canEdit = _isOwnTracker || isPartner;

            if (!_isOwnTracker && !isPartner) {
              return _buildPrivacyState();
            }

            return trackerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e.toString()),
              data: (settings) {
                final info = PeriodLogic.calculateCycleInfo(settings ?? const PeriodTrackerModel());
                final hasData = settings != null && settings.lastPeriodStart != null;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!hasData)
                      _buildEmptyState(canEdit)
                    else ...[
                      _buildDashboard(info),
                      const SizedBox(height: 28),
                      _buildCalendarSection(settings!),
                      const SizedBox(height: 28),
                      _buildPhasesSection(info),
                      const SizedBox(height: 28),
                      _buildInsightsSection(logsAsync.value ?? []),
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
        backgroundColor: const Color(0xFFE91E8C), // Standardized to CyclePhase.menstrual color
      )
          : null,
    );
  }

  Widget _buildSettingsAction(dynamic currentUser) {
    final bool isPartner = currentUser?.partnerId == widget.userId;
    if (_isOwnTracker || isPartner) {
      return IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => _showSettingsSheet(context),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrivacyState() {
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

  Widget _buildErrorState(String message) {
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

  Widget _buildEmptyState(bool canEdit) {
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
                  : 'No tracking data available for ${widget.userName} yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogPeriodSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(_isOwnTracker ? 'Log My Last Period' : 'Log Period for ${widget.userName}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showSettingsSheet(context),
              icon: const Icon(Icons.settings_suggest_outlined),
              label: const Text('Configure Cycle Length'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> info) {
    final cycleDay = info['cycleDay'] as int?;
    final phase = info['phase'] as CyclePhase?;
    final daysUntilNext = info['daysUntilNext'] as int?;
    final nextPeriodStart = info['nextPeriodStart'] as DateTime?;

    // Determine color schemes dynamically according to current phase
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
              _buildStatItem('Cycle Day', cycleDay?.toString() ?? '--', Icons.calendar_today_rounded, themeColor),
              _buildStatItem('Phase', phase?.name ?? '--', phase?.icon ?? Icons.waves_rounded, themeColor),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildCalendarSection(PeriodTrackerModel settings) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

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
                  onPressed: () =>
                      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () =>
                      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCalendarGrid(settings),
        const SizedBox(height: 16),
        _buildCalendarLegend(),
      ],
    );
  }

  Widget _buildCalendarGrid(PeriodTrackerModel settings) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    final info = PeriodLogic.calculateCycleInfo(settings);
    final ovulationDate  = info['ovulationDate']  as DateTime?;
    final fertileStart   = info['fertileStart']   as DateTime?;
    final fertileEnd     = info['fertileEnd']     as DateTime?;

    final predictedDays  = PeriodLogic.getPredictedPeriodDays(settings, _selectedMonth);
    final follicularDays = PeriodLogic.getFollicularDays(settings, _selectedMonth);
    final lutealDays     = PeriodLogic.getLutealDays(settings, _selectedMonth);

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

        final day  = index - firstDayOfWeek + 1;
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);

        final isToday      = DateUtils.isSameDay(date, today);
        final isPredicted  = predictedDays.any((d)  => DateUtils.isSameDay(d, date));
        final isOvulation  = ovulationDate != null   && DateUtils.isSameDay(ovulationDate, date);
        final isFertile    = fertileStart != null
            && fertileEnd != null
            && !date.isBefore(fertileStart)
            && !date.isAfter(fertileEnd)
            && !isOvulation;   // ovulation day takes priority
        final isFollicular = follicularDays.any((d) => DateUtils.isSameDay(d, date));
        final isLuteal     = lutealDays.any((d)     => DateUtils.isSameDay(d, date));

        final phase = CyclePhaseStyle.fromDayState(
          isPredicted:  isPredicted,
          isOvulation:  isOvulation,
          isFertile:    isFertile,
          isFollicular: isFollicular,
          isLuteal:     isLuteal,
        );

        Color? bg         = phase?.backgroundColor;
        Color  border     = phase?.borderColor ?? Colors.transparent;
        double borderW    = phase == CyclePhase.ovulation ? 1.8 : 1.0;
        Color  textCol    = phase?.color ?? AppColors.textSecondary;
        FontWeight weight = (isToday || isOvulation) ? FontWeight.w600 : FontWeight.normal;

        // Today always wins visually
        if (isToday) {
          bg      = AppColors.primary.withValues(alpha: 0.15);
          border  = AppColors.primary.withValues(alpha: 0.5);
          textCol = AppColors.textPrimary;
          weight  = FontWeight.w600;
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
            style: TextStyle(
              fontSize: 13,
              color: textCol,
              fontWeight: weight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...CyclePhase.values.map((phase) => Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _legendItem(
              phase.name,
              phase.backgroundColor,
              borderColor: phase.borderColor,
            ),
          )),
          _legendItem(
            'Today',
            AppColors.primary.withValues(alpha: 0.15),
            borderColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {Color? borderColor, bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDot ? 6 : 12,
          height: isDot ? 6 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildPhasesSection(Map<String, dynamic> info) {
    final currentPhase = info['phase'] as CyclePhase?;

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

  Widget _buildInsightsSection(List<PeriodLogModel> logs) {
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
              _buildInsightRow('Previous cycles', logs.length.toString()),
              const Divider(height: 24),
              _buildInsightRow('Average cycle length', '${avgLength.toStringAsFixed(1)} days'),
              const Divider(height: 24),
              _buildInsightRow('Cycle consistency', logs.length < 3 ? 'Calculating...' : 'Moderate'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
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
              _buildDatePickerTile('Start Date', start, (date) => setSheetState(() => start = date)),
              const SizedBox(height: 16),
              _buildDatePickerTile('End Date', end, (date) => setSheetState(() => end = date)),
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

  Widget _buildDatePickerTile(String label, DateTime date, Function(DateTime) onPick) {
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
              _buildNumberPicker(
                'Average Cycle Length',
                cycleLength,
                20,
                45,
                    (v) => setSheetState(() => cycleLength = v),
              ),
              const SizedBox(height: 20),
              _buildNumberPicker('Average Period Duration', duration, 2, 10, (v) => setSheetState(() => duration = v)),
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

  Widget _buildNumberPicker(String label, int value, int min, int max, Function(int) onChanged) {
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


// Providers
final periodTrackerStreamProvider = StreamProvider.family<PeriodTrackerModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).periodTrackerStream(uid);
});

final periodLogsStreamProvider = StreamProvider.family<List<PeriodLogModel>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).periodLogsStream(uid);
});
