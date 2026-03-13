import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/gradient_button.dart';

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.read(firestoreServiceProvider).userStream(uid);
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  UserModel? _searchResult;
  String? _searchError;
  bool _addLoading = false;

  Future<void> _search() async {
    final code = _searchCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _searching = true;
      _searchResult = null;
      _searchError = null;
    });
    try {
      final user = await ref.read(firestoreServiceProvider).findUserByCode(code);
      setState(() {
        _searchResult = user;
        if (user == null) _searchError = 'No user found with that code.';
      });
    } catch (e) {
      setState(() => _searchError = e.toString());
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _addFriend(String friendUid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    setState(() => _addLoading = true);
    try {
      await ref.read(firestoreServiceProvider).addFriend(myUid, friendUid);
      _searchCtrl.clear();
      setState(() {
        _searchResult = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend added!'), backgroundColor: AppColors.online));
      }
    } finally {
      if (mounted) setState(() => _addLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final userAsync = ref.watch(userProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: AppColors.background,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Invite code
          _buildInviteCard(uid),
          const SizedBox(height: 24),

          // Add by name
          const Text(
            'Add Friend by Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Enter invite code...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _searching ? null : _search,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
                  child: _searching
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 8),
            Text(_searchError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          if (_searchResult != null) ...[const SizedBox(height: 12), _buildSearchResult(_searchResult!)],
          const SizedBox(height: 28),

          // Friends list
          const Text(
            'Your Friends',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          userAsync.when(
            loading: () => Center(child: const CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (user) {
              if (user == null || user.friends.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No friends yet. Add someone above!',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    ),
                  ),
                );
              }
              return FutureBuilder<List<UserModel>>(
                future: ref.read(firestoreServiceProvider).getFriends(user.friends),
                builder: (context, snap) {
                  if (!snap.hasData) return Center(child: const CircularProgressIndicator());
                  return Column(children: snap.data!.map((f) => _buildFriendTile(f, uid)).toList());
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(String uid) {
    final code = uid.substring(0, 8).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.pink.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 7),
              Text(
                'Your Invite Code',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Code copied!'), backgroundColor: AppColors.primary));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, color: AppColors.primary, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Copy',
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this code with friends so they can add you.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSearchResult(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    user.displayName[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: _addLoading ? null : () => _addFriend(user.uid),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(10)),
              child: _addLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Add',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(UserModel friend, String myUid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: friend.photoURL != null ? NetworkImage(friend.photoURL!) : null,
            child: friend.photoURL == null
                ? Text(
                    friend.displayName[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friend.displayName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Remove Friend', style: TextStyle(color: AppColors.textPrimary)),
                  content: Text(
                    'Remove ${friend.displayName}?',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                      child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(firestoreServiceProvider).removeFriend(myUid, friend.uid);
              }
            },
            child: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
