import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../app/theme.dart';
import '../models/now_playing_model.dart';

class NowPlayingCard extends StatefulWidget {
  final NowPlayingModel model;
  final bool canReact;
  final Function(String emoji)? onReact;
  final bool isOwn;

  const NowPlayingCard({super.key, required this.model, this.canReact = true, this.onReact, this.isOwn = false});

  @override
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard> with SingleTickerProviderStateMixin {
  bool _showReactions = false;
  String? _sentEmoji;

  static const _emojis = ['🔥', '❤️', '😮', '🎉', '👏', '💜'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), _buildMediaInfo(), if (!widget.isOwn && widget.canReact) _buildReactionBar()],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
            child: widget.model.userPhoto != null
                ? ClipOval(
                    child: CachedNetworkImage(imageUrl: widget.model.userPhoto!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      (widget.model.userName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOwn ? 'You' : (widget.model.userName ?? 'Friend'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.online),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'listening now',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.online.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Source badge
          _SourceBadge(source: widget.model.source),
        ],
      ),
    );
  }

  Widget _buildMediaInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Album art
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceHigh,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: widget.model.albumArt != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.model.albumArt!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _albumArtPlaceholder(),
                      errorWidget: (_, _, _) => _albumArtPlaceholder(),
                    ),
                  )
                : _albumArtPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.model.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.model.artist,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                AudioWave(isPlaying: widget.model.isPlaying),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _showReactions ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildReactButton(),
        secondChild: _buildEmojiPicker(),
      ),
    );
  }

  Widget _buildReactButton() {
    return GestureDetector(
      onTap: () => setState(() => _showReactions = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (_sentEmoji != null) ...[
              Text(_sentEmoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Reacted',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              const Icon(Icons.add_reaction_outlined, color: AppColors.textTertiary, size: 18),
              const SizedBox(width: 6),
              const Text(
                'React',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ..._emojis.map(
            (emoji) => GestureDetector(
              onTap: () {
                setState(() {
                  _sentEmoji = emoji;
                  _showReactions = false;
                });
                widget.onReact?.call(emoji);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(10)),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ).animate().scale(duration: 200.ms, curve: Curves.elasticOut),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showReactions = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.close, color: AppColors.textTertiary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _albumArtPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.surfaceHigh, AppColors.primary.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.textTertiary, size: 28),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final MediaSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        source.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }

  Color get _color => switch (source) {
    MediaSource.spotify => const Color(0xFF1DB954),
    MediaSource.youtube => const Color(0xFFFF0000),
    MediaSource.appleMusic => const Color(0xFFFC3C44),
    MediaSource.other => AppColors.primary,
    MediaSource.youtubeMusic => const Color(0xFFFF0000),
  };
}

class AudioWave extends StatefulWidget {
  final bool isPlaying;

  const AudioWave({super.key, required this.isPlaying});

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 120),
      );
    });
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant AudioWave oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPlaying != widget.isPlaying) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isPlaying) {
      for (final c in _controllers) {
        c.repeat(reverse: true);
      }
    } else {
      for (final c in _controllers) {
        c.stop();
        c.value = 0.2;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        children: List.generate(_controllers.length, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, _) {
              return Container(
                width: 3,
                height: 4 + _controllers[i].value * 12,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(2)),
              );
            },
          );
        }),
      ),
    );
  }
}
// ── Shimmer loading card ──────────────────────────────────────────────────────

class NowPlayingCardSkeleton extends StatelessWidget {
  const NowPlayingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceHigh,
        highlightColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(36, 36, radius: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(100, 12), const SizedBox(height: 5), _box(70, 10)],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _box(72, 72, radius: 12),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(150, 14), const SizedBox(height: 6), _box(100, 12)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
  );
}
