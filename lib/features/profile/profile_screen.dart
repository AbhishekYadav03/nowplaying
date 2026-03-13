import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nowplaying/models/user_model.dart';
import '../../app/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/media_service.dart';
import '../../models/now_playing_model.dart';

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userStream(uid);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final userAsync = ref.watch(userProvider(uid));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: user.photoURL != null
                          ? ClipOval(child: Image.network(user.photoURL!, fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                user.displayName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.friends.length} friend${user.friends.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),

              const SizedBox(height: 32),

              // Sharing toggle
              _buildSection(
                title: 'PRIVACY',
                child: _SharingToggle(uid: uid, isSharingEnabled: user.isSharingEnabled),
              ),

              const SizedBox(height: 16),

              // Manual track entry
              // _buildSection(
              //   title: 'MANUAL ENTRY',
              //   child: _ManualTrackEntry(ref: ref),
              // ),
              const SizedBox(height: 16),

              // Settings
              _buildSection(
                title: 'ACCOUNT',
                child: Column(
                  children: [
                    _SettingsTile(icon: Icons.info_outline_rounded, label: 'About NowPlaying', onTap: () {}),
                    const Divider(height: 1, color: AppColors.border),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      color: AppColors.error,
                      onTap: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SharingToggle extends ConsumerWidget {
  final String uid;
  final bool isSharingEnabled;
  const _SharingToggle({required this.uid, required this.isSharingEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSharingEnabled ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSharingEnabled ? Icons.broadcast_on_personal_rounded : Icons.pause_circle_outline_rounded,
              color: isSharingEnabled ? AppColors.primary : AppColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share Now Playing',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  isSharingEnabled ? 'Friends can see your activity' : 'Activity is hidden (Ghost Mode)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isSharingEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              await ref.read(firestoreServiceProvider).updateSharingEnabled(uid, val);
            },
          ),
        ],
      ),
    );
  }
}

class _ManualTrackEntry extends StatefulWidget {
  final WidgetRef ref;
  const _ManualTrackEntry({required this.ref});

  @override
  State<_ManualTrackEntry> createState() => _ManualTrackEntryState();
}

class _ManualTrackEntryState extends State<_ManualTrackEntry> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  MediaSource _source = MediaSource.spotify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manually broadcast what you\'re listening to',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Track title',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _artistCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Artist',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MediaSource>(
            value: _source,
            dropdownColor: AppColors.surfaceHigh,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            items: MediaSource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
            onChanged: (val) => setState(() => _source = val!),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              if (_titleCtrl.text.isEmpty || _artistCtrl.text.isEmpty) return;
              await widget.ref
                  .read(mediaServiceProvider)
                  .setManualNowPlaying(title: _titleCtrl.text.trim(), artist: _artistCtrl.text.trim(), source: _source);
              _titleCtrl.clear();
              _artistCtrl.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Now playing updated!'), backgroundColor: AppColors.primary),
                );
              }
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text(
                  'Broadcast',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c, size: 20),
      title: Text(
        label,
        style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
    );
  }
}
