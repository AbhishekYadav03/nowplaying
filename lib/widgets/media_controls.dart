import 'package:flutter/material.dart';

class MediaControls extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final bool isPlaying;
  final Color? color;

  const MediaControls({
    super.key,
    required this.onPrevious,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
    required this.isPlaying,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _controlButton(icon: Icons.skip_previous_rounded, onTap: onPrevious),
        const SizedBox(width: 12),
        _controlButton(
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: isPlaying ? onPause : onPlay,
        ),
        const SizedBox(width: 12),
        _controlButton(icon: Icons.skip_next_rounded, onTap: onNext),
      ],
    );
  }

  Widget _controlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color?.withOpacity(0.1)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
