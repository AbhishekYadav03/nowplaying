import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nowplaying/app/theme.dart';
import 'package:nowplaying/services/firestore_service.dart';
import 'package:nowplaying/models/user_model.dart';

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).userStream(uid);
});

final friendsStatusProvider = StreamProvider.family<List<UserModel>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).friendsStatusStream(uid);
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
  final Set<String> _removingUids = {};

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

  Future<void> _removeFriend(String myUid, String friendUid) async {
    setState(() => _removingUids.add(friendUid));
    try {
      await ref.read(firestoreServiceProvider).removeFriend(myUid, friendUid);
      ref.invalidate(friendsStatusProvider(myUid));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _removingUids.remove(friendUid));
    }
  }

  Future<void> _setPartner(String myUid, String friendUid, String name) async {
    try {
      await ref.read(firestoreServiceProvider).setPartner(myUid, friendUid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name is now your partner ❤️'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final friendsAsync = ref.watch(friendsStatusProvider(uid));
    final currentUserAsync = ref.watch(userProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInviteCard(uid),
          const SizedBox(height: 24),
          const Text(
            'Add Friend by Invite code',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
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
          const Text(
            'Your Friends',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          friendsAsync.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
            ),
            data: (friends) {
              if (friends.isEmpty) {
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
              final currentUser = currentUserAsync.value;
              return Column(
                children: friends
                    .map((f) => _buildFriendTile(f, uid, currentUser?.partnerId, key: ValueKey(f.uid)))
                    .toList(),
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
          Row(
            children: const [
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
                  child: Row(
                    children: const [
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
            backgroundImage: user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
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

  Widget _buildFriendTile(UserModel friend, String myUid, String? partnerId, {Key? key}) {
    final statusText = friend.isOnline ? 'Active Now' : _formatLastSeen(friend.lastSeen);
    final isRemoving = _removingUids.contains(friend.uid);
    final isPartner = partnerId == friend.uid;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPartner ? AppColors.pink.withOpacity(0.5) : AppColors.border,
          width: isPartner ? 1.5 : 0.5,
        ),
      ),
      child: Opacity(
        opacity: isRemoving ? 0.5 : 1.0,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: friend.photoURL != null ? CachedNetworkImageProvider(friend.photoURL!) : null,
                  child: friend.photoURL == null
                      ? Text(
                          friend.displayName[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (isPartner) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite_rounded, color: AppColors.pink, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 11, color: friend.isOnline ? AppColors.online : AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (isRemoving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              GestureDetector(
                onTap: () => _showFriendActions(friend, myUid, isPartner),
                child: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }

  void _showFriendActions(UserModel friend, String myUid, bool isPartner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(isPartner ? Icons.favorite_border_rounded : Icons.favorite_rounded, color: AppColors.pink),
              title: Text(
                isPartner ? 'Remove as Partner' : 'Set as Partner',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isPartner ? 'No longer dedicate songs instantly' : 'Dedicate songs instantly with one tap',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _setPartner(myUid, isPartner ? "" : friend.uid, friend.displayName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: AppColors.error),
              title: const Text(
                'Remove Friend',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);

                Navigator.of(context).pop();

                if (!mounted) return;

                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false, // safer for destructive action
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Remove Friend', style: TextStyle(color: AppColors.textPrimary)),
                      content: Text(
                        'Remove ${friend.displayName ?? "this friend"}?',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true && mounted) {
                  try {
                    await _removeFriend(myUid, friend.uid);

                    if (!mounted) return;

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Friend removed successfully'), behavior: SnackBarBehavior.floating),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to remove friend: $e'), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }
}
