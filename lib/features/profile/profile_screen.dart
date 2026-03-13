import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nowplaying/models/user_model.dart';
import 'package:nowplaying/app/theme.dart';
import 'package:nowplaying/services/firestore_service.dart';
import 'package:nowplaying/services/auth_service.dart';

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userStream(uid);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(String uid) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 512);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(firestoreServiceProvider).updateProfilePhoto(uid, File(image.path));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _isUploading ? null : () => _pickAndUploadImage(uid),
                          child: Container(
                            width: 100,
                            height: 100,
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
                            child: _isUploading
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : (user.photoURL != null
                                      ? ClipOval(
                                          child: Image.network(
                                            user.photoURL!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.person, color: Colors.white, size: 50),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            user.displayName[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )),
                          ),
                        ),
                        if (!_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
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
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.25), AppColors.primary.withOpacity(0.05)],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, Colors.pinkAccent, Colors.orangeAccent],
                    ).createShader(bounds),
                    child: const Text(
                      'Made with ❤️ for Musk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).shimmer(duration: 2200.ms, color: Colors.white.withOpacity(0.5)),
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
