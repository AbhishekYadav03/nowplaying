import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/now_playing_model.dart';
import 'dart:convert';
import 'dart:typed_data';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final service = MediaService(ref.read(firestoreServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

final currentMediaProvider = StreamProvider<NowPlayingModel?>((ref) {
  return ref.watch(mediaServiceProvider).mediaStream;
});

class MediaInfo {
  final String title;
  final String artist;
  final String? albumArt;
  final String source;
  final String? packageName;
  final bool isPlaying;

  const MediaInfo({
    required this.title,
    required this.artist,
    this.albumArt,
    required this.source,
    this.isPlaying = false,
    this.packageName,
  });

  factory MediaInfo.fromMap(Map<dynamic, dynamic> map) {
    return MediaInfo(
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown',
      albumArt: map['albumArt'],
      packageName: map['packageName'],
      source: map['source'] ?? 'Other',
      isPlaying: map['isPlaying'] ?? false,
    );
  }
}

class MediaService {
  static const _eventChannel = EventChannel('com.nowplaying/media_events');
  static const _methodChannel = MethodChannel('com.nowplaying/media');

  final FirestoreService _firestoreService;
  final _controller = StreamController<NowPlayingModel?>.broadcast();
  StreamSubscription? _platformSub;
  Timer? _presenceTimer;
  Timer? _debounce;

  MediaService(this._firestoreService) {
    _startListening();
    _startPresenceTimer();
  }

  Stream<NowPlayingModel?> get mediaStream => _controller.stream;

  void reconnect() {
    _platformSub?.cancel();
    _startListening();
    _startPresenceTimer();
  }

  void _startPresenceTimer() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateLastSeen();
    });
    _updateLastSeen();
  }

  void _updateLastSeen() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _firestoreService.updateLastSeen(uid);
    }
  }

  void _startListening() {
    try {
      _platformSub = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event == null) {
            _handleMediaStopped();
            return;
          }
          final info = MediaInfo.fromMap(event as Map);
          _handleMediaChange(info);
        },
        onError: (e) {
          _controller.add(null);
        },
      );
    } catch (_) {
      _controller.add(null);
    }
  }

  void _handleMediaChange(MediaInfo info) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final model = NowPlayingModel(
      uid: uid,
      title: info.title,
      artist: info.artist,
      albumArt: info.albumArt,
      source: _parseSource(info.source),
      isActive: true,
      isPlaying: info.isPlaying,
      packageName: info.packageName,
      updatedAt: DateTime.now(),
    );

    _controller.add(model);

    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () async {
      try {
        await _firestoreService.updateNowPlaying(model);
      } catch (_) {}
    });
  }

  void _handleMediaStopped() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _controller.add(null);
    if (uid != null) {
      _firestoreService.clearNowPlaying(uid);
    }
  }

  Future<void> stopSharing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _controller.add(null);
    await _firestoreService.clearNowPlaying(uid);
  }

  static MediaSource _parseSource(String s) {
    switch (s.toLowerCase()) {
      case 'spotify':
        return MediaSource.spotify;
      case 'youtube':
        return MediaSource.youtube;
      case 'youtube music':
        return MediaSource.youtubeMusic;
      case 'apple music':
        return MediaSource.appleMusic;
      default:
        return MediaSource.other;
    }
  }

  static Future<bool> hasAccess() async {
    final result = await _methodChannel.invokeMethod<bool>('hasNotificationAccess');
    return result ?? false;
  }

  static Future<void> openSettings() async {
    await _methodChannel.invokeMethod('openNotificationSettings');
  }

  static Uint8List? albumArtBytes(String? art) {
    if (art == null) return null;
    final cleaned = art.replaceAll(RegExp(r'\s+'), '');
    return base64Decode(cleaned);
  }

  void dispose() {
    _platformSub?.cancel();
    _presenceTimer?.cancel();
    _debounce?.cancel();
    _controller.close();
  }
}
