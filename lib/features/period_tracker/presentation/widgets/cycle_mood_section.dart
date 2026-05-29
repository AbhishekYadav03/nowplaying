import 'package:flutter/material.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/period_tracker/domain/period_logic.dart';

class CycleMoodSection extends StatelessWidget {
  const CycleMoodSection({super.key, required this.phase, this.isOwner = true});

  final CyclePhase phase;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: _MoodContent(phase: phase, key: ValueKey(phase), isOwner: isOwner),
    );
  }
}

class _MoodContent extends StatelessWidget {
  const _MoodContent({super.key, required this.phase, this.isOwner = false});

  final CyclePhase phase;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final moods = phase.moods;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phase.color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mood_rounded, size: 16, color: phase.color),
              const SizedBox(width: 6),
              Text(
                'How you might feel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            phase.moodSummary(isOwner: isOwner),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Mood chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((m) => _MoodChip(mood: m, phase: phase)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.phase});

  final CycleMood mood;
  final CyclePhase phase;

  @override
  Widget build(BuildContext context) {
    // Intensity drives opacity: mild=0.08, moderate=0.13, strong=0.20
    final fillAlpha = switch (mood.intensity) {
      1 => 0.08,
      2 => 0.13,
      _ => 0.20,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: phase.color.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phase.color.withValues(alpha: fillAlpha * 2.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            mood.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: phase.color),
          ),
          // Intensity dots
          const SizedBox(width: 5),
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phase.color.withValues(alpha: i < mood.intensity ? 0.8 : 0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



