import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../models/relationship_date_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'add_date_screen.dart';
import 'date_detail_screen.dart';

final datesStreamProvider = StreamProvider.family<List<RelationshipDateModel>, (String, String)>((ref, ids) {
  return ref.watch(firestoreServiceProvider).datesStream(ids.$1, ids.$2);
});

class DatesScreen extends ConsumerWidget {
  final UserModel friend;

  const DatesScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final datesAsync = ref.watch(datesStreamProvider((uid, friend.uid)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${friend.displayName}\'s Dates'),
        actions: [IconButton(onPressed: () => _openAddDate(context), icon: const Icon(Icons.add_rounded))],
      ),
      body: datesAsync.when(
        data: (dates) {
          if (dates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No special dates yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddDate(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              return _DateCard(date: date, friend: friend);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: datesAsync.maybeWhen(
        data: (dates) => dates.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _openAddDate(context),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Date',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _openAddDate(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddDateScreen(friendId: friend.uid)));
  }
}

class _DateCard extends StatelessWidget {
  final RelationshipDateModel date;
  final UserModel friend;

  const _DateCard({required this.date, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DateDetailScreen(date: date, friend: friend),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        date.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    if (date.isRecursive) const Icon(Icons.repeat_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM dd, yyyy').format(date.date),
                  style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                _buildCountdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    if (date.isRecursive) {
      final days = date.daysUntilNext;
      final text = days == 0 ? 'Today!' : 'Next in $days days';
      return _Badge(text: text, color: AppColors.primary.withOpacity(0.15), textColor: AppColors.primary);
    } else {
      final days = date.daysPassed;
      return _Badge(text: '$days days ago', color: AppColors.pink.withOpacity(0.15), textColor: AppColors.pink);
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Badge({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
