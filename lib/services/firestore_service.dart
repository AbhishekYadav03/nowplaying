import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/now_playing_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ImgBB API Key
  static const String _imgbbKey = 'c435430f2b8a8675d73ce0f2e9b18915';

  String? _cachedGasUrl;

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<void> upsertUser(User user, {String? displayName, String? appVersion}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    final Map<String, dynamic> data = {
      'lastLogin': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'friendCode': user.uid.substring(0, 8).toUpperCase(),
    };

    if (appVersion != null) {
      data['appVersion'] = appVersion;
    }

    if (!userDoc.exists) {
      data['displayName'] = displayName ?? user.displayName ?? 'User ${user.uid.substring(0, 4).toUpperCase()}';
      data['photoURL'] = user.photoURL;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['friends'] = [];
      data['isSharingEnabled'] = true;
      await userRef.set(data);
    } else {
      final existingData = userDoc.data()!;
      if (existingData['photoURL'] == null && user.photoURL != null) {
        data['photoURL'] = user.photoURL;
      }
      if (existingData['displayName'] == null) {
        data['displayName'] = displayName ?? user.displayName ?? 'User ${user.uid.substring(0, 4).toUpperCase()}';
      }
      await userRef.update(data);
    }
  }

  Future<void> setPartner(String myUid, String partnerUid) async {
    await _db.collection('users').doc(myUid).update({'partnerId': partnerUid});
    await _db.collection('users').doc(partnerUid).update({'partnerId': myUid});
  }

  Future<String?> _getGasUrl() async {
    if (_cachedGasUrl != null) return _cachedGasUrl;
    try {
      final doc = await _db.collection('config').doc('notifications').get();
      _cachedGasUrl = doc.data()?['gasUrl'];
      return _cachedGasUrl;
    } catch (e) {
      debugPrint('Error fetching GAS URL: $e');
      return null;
    }
  }

  Future<void> _triggerGasNotification(Map<String, dynamic> body) async {
    final url = await _getGasUrl();
    if (url == null || url.isEmpty || url.contains('YOUR_GOOGLE')) return;
    try {
      await http.post(Uri.parse(url), body: jsonEncode(body));
    } catch (e) {
      debugPrint('GAS Notification Error: $e');
    }
  }

  Future<void> updateLastSeen(String uid) async {
    await _db.collection('users').doc(uid).update({'lastSeen': FieldValue.serverTimestamp()});
  }

  Future<void> updateFcmToken(String uid, String token) async {
    final userRef = _db.collection('users').doc(uid);
    final doc = await userRef.get();

    final bool isFirstToken = doc.exists && (doc.data() as Map<String, dynamic>)['fcmToken'] == null;

    await userRef.update({'fcmToken': token});

    if (isFirstToken) {
      _triggerGasNotification({
        'action': 'welcomeUser',
        'fcmToken': token,
        'title': '🎵 Welcome to NowPlaying!',
        'body': 'Add friends and start sharing what you\'re listening to.',
      });
    }
  }

  Future<void> updateSharingEnabled(String uid, bool enabled) async {
    await _db.collection('users').doc(uid).update({'isSharingEnabled': enabled});
    if (!enabled) {
      await _db.collection('nowplaying').doc(uid).set({'isActive': false}, SetOptions(merge: true));
    }
  }

  Future<String> updateProfilePhoto(String uid, File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbKey'));
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image to ImgBB');
    }

    final responseData = await response.stream.bytesToString();
    final jsonResponse = jsonDecode(responseData);
    final url = jsonResponse['data']['url'] as String;

    await _db.collection('users').doc(uid).update({'photoURL': url});

    try {
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
    } catch (e) {
      debugPrint('Failed to sync photo URL to Firebase Auth: $e');
    }

    return url;
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  Future<void> addFriend(String myUid, String friendUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'friends': FieldValue.arrayUnion([friendUid]),
    });
    batch.update(_db.collection('users').doc(friendUid), {
      'friends': FieldValue.arrayUnion([myUid]),
    });
    await batch.commit();
  }

  Future<void> removeFriend(String myUid, String friendUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'friends': FieldValue.arrayRemove([friendUid]),
    });
    batch.update(_db.collection('users').doc(friendUid), {
      'friends': FieldValue.arrayRemove([myUid]),
    });
    await batch.commit();
  }

  Stream<List<UserModel>> friendsStatusStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return <String>[];
          final data = snap.data();
          return List<String>.from(data?['friends'] ?? []);
        })
        .distinct((prev, next) => listEquals(prev, next))
        .asyncExpand((friends) {
          if (friends.isEmpty) return Stream.value([]);
          final batch = friends.take(30).toList();
          return _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .snapshots()
              .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
        });
  }

  Future<UserModel?> findUserByCode(String code) async {
    final snap = await _db.collection('users').where('friendCode', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }

  // ── Now Playing ───────────────────────────────────────────────────────────

  Future<void> updateNowPlaying(NowPlayingModel info) async {
    await _db.collection('nowplaying').doc(info.uid).set(info.toMap(), SetOptions(merge: true));
  }

  Future<void> clearNowPlaying(String uid) async {
    await _db.collection('nowplaying').doc(uid).set({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<NowPlayingModel?> myNowPlayingStream(String uid) {
    return _db.collection('nowplaying').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return NowPlayingModel.fromFirestore(snap);
    });
  }

  Stream<List<NowPlayingModel>> friendsFeedStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return <String>[];
          final data = snap.data();
          return List<String>.from(data?['friends'] ?? []);
        })
        .distinct((prev, next) => listEquals(prev, next))
        .asyncExpand((friends) {
          if (friends.isEmpty) return Stream.value([]);
          final batch = friends.take(30).toList();
          return _db
              .collection('nowplaying')
              .where(FieldPath.documentId, whereIn: batch)
              .where('isActive', isEqualTo: true)
              .orderBy('updatedAt', descending: true)
              .snapshots()
              .asyncMap((snap) async {
                if (snap.docs.isEmpty) return [];
                final uids = snap.docs.map((d) => d.id).toList();
                final userDocs = await _db.collection('users').where(FieldPath.documentId, whereIn: uids).get();
                final userMap = {for (final u in userDocs.docs) u.id: u.data()};
                return snap.docs.map((d) {
                  final u = userMap[d.id];
                  return NowPlayingModel.fromFirestore(d, userName: u?['displayName'], userPhoto: u?['photoURL']);
                }).toList();
              });
        });
  }

  // ── Reactions & Remote Control ────────────────────────────────────────────

  Future<void> sendReaction(String toUid, String emoji) async {
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    if (fromUid == null || fromUid == toUid) return;

    await _db.collection('nowplaying').doc(toUid).collection('reactions').add({
      'fromUid': fromUid,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      final toUser = await getUser(toUid);
      final fromUser = await getUser(fromUid);
      final npSnap = await _db.collection('nowplaying').doc(toUid).get();

      if (toUser?.fcmToken != null) {
        final track = npSnap.data()?['title'] ?? 'your track';
        final fromName = fromUser?.displayName ?? 'A friend';
        _triggerGasNotification({
          'action': 'sendReaction',
          'fcmToken': toUser!.fcmToken,
          'title': '$emoji $fromName reacted!',
          'body': '$fromName reacted to your track "$track"',
          'fromUid': fromUid,
        });
      }
    } catch (e) {
      debugPrint('Failed to send reaction notification: $e');
    }
  }

  Future<void> dedicateSong(String fromUid, String toUid, String trackName) async {
    try {
      final toUser = await getUser(toUid);
      final fromUser = await getUser(fromUid);

      if (toUser?.fcmToken != null) {
        final fromName = fromUser?.displayName ?? 'Someone';
        await _triggerGasNotification({
          'action': 'dedicateSong',
          'fcmToken': toUser!.fcmToken,
          'title': 'Song Dedication 🎵',
          'body': '$fromName thinks of you when listening to "$trackName" 🎶',
        });
      }
    } catch (e) {
      debugPrint('Failed to dedicate song: $e');
    }
  }

  Future<void> triggerMediaControl(String fcmToken, String command) async {
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    final fromUser = fromUid != null ? await getUser(fromUid) : null;
    final fromName = fromUser?.displayName ?? 'A friend';

    await _triggerGasNotification({
      'fcmToken': fcmToken,
      'action': 'media_control',
      'command': command,
      'title': 'Remote Control 🎮',
      'body': '$fromName ${_getCommandLabel(command)} your music',
    });
  }

  String _getCommandLabel(String command) {
    switch (command) {
      case 'play':
        return 'resumed';
      case 'pause':
        return 'paused';
      case 'skipNext':
        return 'skipped to next track';
      case 'skipPrevious':
        return 'went to previous track';
      default:
        return 'controlled';
    }
  }

  Stream<List<ReactionModel>> reactionsStream(String uid) {
    return _db
        .collection('nowplaying')
        .doc(uid)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(ReactionModel.fromFirestore).toList());
  }

  // ── Config ────────────────────────────────────────────────────────────────

  Stream<List<String>> emojisStream() {
    return _db.collection('config').doc('emojis').snapshots().map((snap) {
      if (!snap.exists) return ['🔥', '❤️', '😮', '🎉', '👏', '💜'];
      final data = snap.data();
      return List<String>.from(data?['list'] ?? ['🔥', '❤️', '😮', '🎉', '👏', '💜']);
    });
  }
}
