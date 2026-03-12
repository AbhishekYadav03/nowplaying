import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/media_service.dart';
import '../../widgets/now_playing_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final feedAsync = ref.watch(
      StreamProvider((ref) => ref.read(firestoreServiceProvider).friendsFeedStream(uid)),
    );

    final myMedia = ref.watch(currentMediaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildMyStatusBar(context, ref, uid)),
          SliverToBoxAdapter(child: _buildSectionLabel('Friends')),
          feedAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const NowPlayingCardSkeleton(),
                childCount: 3,
              ),
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
                    onReact: (emoji) =>
                        ref.read(firestoreServiceProvider).sendReaction(items[i].uid, emoji),
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
              'NowPlaying',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: AppColors.border),
      ),
    );
  }

  Widget _buildMyStatusBar(BuildContext context, WidgetRef ref, String uid) {
    return ref.watch(currentMediaProvider).when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (media) {
        if (media == null) {
          return _buildNotPlayingBanner(context, ref);
        }
        return NowPlayingCard(
          model: media,
          isOwn: true,
          canReact: false,
        );
      },
    );
  }

  Widget _buildNotPlayingBanner(BuildContext context, WidgetRef ref) {
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
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
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
