import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/shared/domain/relationship_date_model.dart';
import 'package:nowplaying/features/auth/domain/user_model.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';
import 'add_date_screen.dart';

class DateDetailScreen extends ConsumerWidget {
  final RelationshipDateModel date;
  final UserModel friend;

  const DateDetailScreen({super.key, required this.date, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.background, Color(0xFF1A1A2E), AppColors.background],
              ),
            ),
          ),

          // Emotional/Minimal Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),

                        const SizedBox(height: 12),

                        Text(
                          DateFormat('MMMM dd, yyyy').format(date.date),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 60),

                        _buildCounter(),

                        const SizedBox(height: 60),

                        if (date.description.isNotEmpty)
                          Text(
                            date.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ),

                _buildFooter(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 28)),
          IconButton(onPressed: () => _editDate(context), icon: const Icon(Icons.edit_note_rounded, size: 28)),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    final int value;
    final String label;
    final Color color;

    if (date.isRecursive) {
      value = date.daysUntilNext;
      label = value == 1 ? 'DAY TO GO' : 'DAYS TO GO';
      color = AppColors.primary;
    } else {
      value = date.daysPassed;
      label = value == 1 ? 'DAY PASSED' : 'DAYS PASSED';
      color = AppColors.pink;
    }

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(seconds: 2),
          curve: Curves.easeOutExpo,
          builder: (context, val, child) {
            return Text(
              '${val.toInt()}',
              style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: color, letterSpacing: -2),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 4, color: color.withValues(alpha: 0.7)),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: TextButton.icon(
        onPressed: () => _confirmDelete(context, ref),
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
        label: const Text('Remove Milestone', style: TextStyle(color: AppColors.error)),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  void _editDate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDateScreen(friendId: friend.uid, initialDate: date),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Delete Milestone?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await ref.read(firestoreServiceProvider).deleteDate(uid, date.id);
        if (context.mounted) {
          Navigator.pop(context); // Close detail screen
        }
      }
    }
  }
}



