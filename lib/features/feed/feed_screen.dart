import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nowplaying/models/now_playing_model.dart';
import 'package:nowplaying/app/theme.dart';
import 'package:nowplaying/services/firestore_service.dart';
import 'package:nowplaying/services/media_service.dart';
import 'package:nowplaying/models/user_model.dart';
import 'package:nowplaying/widgets/now_playing_card.dart';

final friendsFeedProvider = StreamProvider.family<List<NowPlayingModel>, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).friendsFeedStream(uid);
});

final currentUserStreamProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userStream(uid);
});

// Provider to check if notification access is granted
final notificationAccessProvider = FutureProvider<bool>((ref) async {
  return await MediaService.hasAccess();
});

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission status when user returns from settings
      ref.invalidate(notificationAccessProvider);
      // Force reconnect to platform channel after permission change
      ref.read(mediaServiceProvider).reconnect();
    }
  }

  Future<void> _checkPermission() async {
    final hasAccess = await MediaService.hasAccess();

    if (!hasAccess && mounted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enable Music Detection"),
            content: const Text("Allow notification access so the app can detect the song you are playing."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await MediaService.openSettings();
                },
                child: const Text("Enable"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final feedAsync = ref.watch(friendsFeedProvider(uid));
    final currentUserAsync = ref.watch(currentUserStreamProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: currentUserAsync.when(
              data: (user) => _buildMyStatusBar(context, ref, uid, user),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _buildMyStatusBar(context, ref, uid, null),
            ),
          ),
          SliverToBoxAdapter(child: _buildSectionLabel('Friends')),

          feedAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate((_, i) => const NowPlayingCardSkeleton(), childCount: 3),
            ),

            error: (e, _) => SliverToBoxAdapter(child: _buildError(e.toString())),

            data: (items) {
              if (items.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => NowPlayingCard(
                    model: items[i],
                    onReact: (emoji) => ref.read(firestoreServiceProvider).sendReaction(items[i].uid, emoji),
                  ),
                  childCount: items.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      expandedHeight: 0,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
            child: const Text(
              'SoftSync',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: AppColors.border),
      ),
    );
  }

  Widget _buildMyStatusBar(BuildContext context, WidgetRef ref, String uid, UserModel? currentUser) {
    final accessAsync = ref.watch(notificationAccessProvider);

    return ref
        .watch(currentMediaProvider)
        .when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (media) {
            return accessAsync.when(
              data: (hasAccess) {
                // If we don't have access, show the "Permission Required" banner
                if (!hasAccess) {
                  return _buildPermissionRequiredBanner(context);
                }

                // If we have access but nothing is playing, show the "Not playing" banner
                if (media == null || !media.isActive) {
                  return _buildNotPlayingBanner(context);
                }

                // Otherwise, show the now playing card
                final enrichedMedia = NowPlayingModel(
                  uid: media.uid,
                  title: media.title,
                  artist: media.artist,
                  albumArt: media.albumArt,
                  source: media.source,
                  updatedAt: media.updatedAt,
                  isActive: media.isActive,
                  isPlaying: media.isPlaying,
                  packageName: media.packageName,
                  userName: currentUser?.displayName ?? 'You',
                  userPhoto: currentUser?.photoURL,
                );

                return NowPlayingCard(model: enrichedMedia, isOwn: true, canReact: false);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _buildPermissionRequiredBanner(context),
            );
          },
        );
  }

  Widget _buildPermissionRequiredBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => MediaService.openSettings(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_paused_rounded, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Detection Disabled',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Tap to enable notification access',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildNotPlayingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.music_off_rounded, color: AppColors.textTertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Not listening to anything',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  'Play music on Spotify, YouTube, or Apple Music',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.brandGradient.createShader(b),
            child: const Icon(Icons.group_add_rounded, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'No friends yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add friends to see what they\'re listening to in real time.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Error: $msg', style: const TextStyle(color: AppColors.error)),
    );
  }
}
