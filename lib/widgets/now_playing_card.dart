import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nowplaying/features/friends/friends_screen.dart';
import 'package:nowplaying/services/media_service.dart';
import 'package:nowplaying/services/firestore_service.dart';
import 'package:nowplaying/widgets/media_controls.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nowplaying/app/theme.dart';
import 'package:nowplaying/models/now_playing_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NowPlayingCard extends ConsumerStatefulWidget {
  final NowPlayingModel model;
  final bool canReact;
  final Function(String emoji)? onReact;
  final bool isOwn;
  final String? partnerId;

  const NowPlayingCard({
    super.key,
    required this.model,
    this.canReact = true,
    this.onReact,
    this.isOwn = false,
    this.partnerId,
  });

  @override
  ConsumerState<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends ConsumerState<NowPlayingCard> with SingleTickerProviderStateMixin {
  bool _showReactions = false;
  String? _sentEmoji;
  bool _isDedicating = false;

  String get _statusText {
    if (widget.model.isPlaying) return 'listening now';
    if (widget.model.updatedAt == null) return 'active';

    final diff = DateTime.now().difference(widget.model.updatedAt!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _openMediaApp() async {
    final query = '${widget.model.title} ${widget.model.artist}';
    final encodedQuery = Uri.encodeComponent(query);

    Uri url;
    switch (widget.model.source) {
      case MediaSource.spotify:
        final spotifyUri = Uri.parse('spotify:search:$encodedQuery');
        if (await canLaunchUrl(spotifyUri)) {
          url = spotifyUri;
        } else {
          url = Uri.parse('https://open.spotify.com/search/$encodedQuery');
        }
        break;
      case MediaSource.youtube:
        url = Uri.parse('https://www.youtube.com/results?search_query=$encodedQuery');
        break;
      case MediaSource.youtubeMusic:
        url = Uri.parse('https://music.youtube.com/search?q=$encodedQuery');
        break;
      case MediaSource.appleMusic:
        url = Uri.parse('https://music.apple.com/search?term=$encodedQuery');
        break;
      default:
        url = Uri.parse('https://www.google.com/search?q=$encodedQuery');
    }

    try {
      final success = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!success) {
        await launchUrl(
          Uri.parse('https://www.google.com/search?q=$encodedQuery'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching media app: $e');
    }
  }

  Future<void> _handleDedicate() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _isDedicating = true);

    try {
      final myUser = await ref.read(firestoreServiceProvider).getUser(myUid);
      final partnerId = myUser?.partnerId;

      if (partnerId == null || partnerId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No partner set. Add a partner in Friends Screen to dedicate songs!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await ref.read(firestoreServiceProvider).dedicateSong(myUid, partnerId, widget.model.title);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Song dedicated to your partner! ❤️'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Dedication Error: $e');
    } finally {
      if (mounted) setState(() => _isDedicating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMediaInfo(),
            if (widget.isOwn) _buildDedicateBar() else if (widget.canReact) _buildReactionBar(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: widget.model.userPhoto != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.model.userPhoto!,
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) => Center(
                        child: Text(
                          (widget.model.userName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      (widget.model.userName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOwn ? 'You' : (widget.model.userName ?? 'Friend'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    if (widget.model.isPlaying)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.online),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.model.isPlaying ? AppColors.online.withOpacity(0.9) : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isOwn)
            IconButton(
              onPressed: _openMediaApp,
              icon: Icon(
                widget.model.source == MediaSource.other ? Icons.search_rounded : Icons.open_in_new_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Open in ${widget.model.source.label}',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceHigh.withOpacity(0.5),
                padding: const EdgeInsets.all(8),
              ),
            ),
          const SizedBox(width: 8),
          _SourceBadge(source: widget.model.source),
        ],
      ),
    );
  }

  Widget _buildMediaInfo() {
    return GestureDetector(
      onLongPress: () {
        final text = '${widget.model.title} - ${widget.model.artist}';
        Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $text'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Hero(
              tag: 'art_${widget.model.uid}_${widget.isOwn ? 'own' : 'feed'}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.surfaceHigh,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _buildAlbumArt(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.model.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.model.artist,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AudioWave(isPlaying: widget.model.isPlaying),
                      SizedBox(width: 20),
                      if (widget.isOwn)
                        Builder(
                          builder: (context) {
                            final mediaService = ref.read(mediaServiceProvider);
                            return MediaControls(
                              isPlaying: widget.model.isPlaying,
                              onPrevious: () => mediaService.skipPrevious(),
                              onPause: () => mediaService.pause(),
                              onNext: () => mediaService,
                              onPlay: () => mediaService.play(),
                            );
                          },
                        ),
                      if (widget.model.uid == widget.partnerId)
                        MediaControls(
                          isPlaying: widget.model.isPlaying,
                          onPrevious: () => _controlMedia('skipPrevious'),
                          onPause: () => _controlMedia(widget.model.isPlaying ? 'pause' : 'play'),
                          onNext: () => _controlMedia('skipNext'),
                          onPlay: () => _controlMedia(widget.model.isPlaying ? 'pause' : 'play'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBase64(String value) {
    return value.length > 100 && !value.startsWith("http");
  }

  Widget _buildAlbumArt() {
    final art = widget.model.albumArt;

    if (art == null || art.isEmpty) {
      return _albumArtPlaceholder();
    }

    if (_isBase64(art)) {
      Uint8List? bytes = MediaService.albumArtBytes(art);
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: bytes == null ? _albumArtPlaceholder() : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: art,
        fit: BoxFit.cover,
        placeholder: (_, _) => _albumArtPlaceholder(),
        errorWidget: (_, _, _) => _albumArtPlaceholder(),
      ),
    );
  }

  Widget _buildDedicateBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: InkWell(
        onTap: _isDedicating ? null : _handleDedicate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isDedicating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                const Icon(Icons.favorite_rounded, color: AppColors.pink, size: 20),
              const SizedBox(width: 10),
              Text(
                _isDedicating ? 'Dedicating...' : 'Dedicate this song to Partner',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withOpacity(0.3),
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _showReactions ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildReactButton(),
        secondChild: _buildEmojiPicker(),
        sizeCurve: Curves.easeInOutCubic,
      ),
    );
  }

  Widget _buildReactButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showReactions = true);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (_sentEmoji != null) ...[
              Text(_sentEmoji!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'Reacted',
                style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ] else ...[
              const Icon(Icons.add_reaction_outlined, color: AppColors.textTertiary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'React',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
              ),
            ],
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _controlMedia(String command) async {
    HapticFeedback.mediumImpact();
    final toUser = await ref.read(firestoreServiceProvider).getUser(widget.model.uid);
    if (toUser?.fcmToken != null) {
      await ref.read(firestoreServiceProvider).triggerMediaControl(toUser!.fcmToken!, command);
    }
  }

  Widget _buildEmojiPicker() {
    return StreamBuilder<List<String>>(
      stream: ref.read(firestoreServiceProvider).emojisStream(),
      builder: (context, snapshot) {
        final emojis = snapshot.data ?? ['🔥', '❤️', '😮', '🎉', '👏', '💜'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              // ✅ Scrollable emojis only
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: emojis.map((emoji) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _sentEmoji = emoji;
                              _showReactions = false;
                            });
                            widget.onReact?.call(emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ❌ Not scrollable (fixed)
              IconButton(
                onPressed: () => setState(() => _showReactions = false),
                icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _albumArtPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.surfaceHigh, AppColors.primary.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.textTertiary, size: 32),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final MediaSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        source.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _color, letterSpacing: 0.2),
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
      height: 18,
      child: Row(
        children: List.generate(_controllers.length, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, _) {
              return Container(
                width: 4,
                height: 4 + _controllers[i].value * 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(2)),
              );
            },
          );
        }),
      ),
    );
  }
}

class NowPlayingCardSkeleton extends StatelessWidget {
  const NowPlayingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
                _box(38, 38, radius: 19),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(110, 14), const SizedBox(height: 6), _box(80, 10)],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _box(80, 80, radius: 16),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(160, 16), const SizedBox(height: 8), _box(110, 12)],
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
