import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/now_playing_model.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final service = MediaService(ref.read(firestoreServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});
final currentMediaProvider = StreamProvider<NowPlayingModel?>((ref) {
  return ref.read(mediaServiceProvider).mediaStream;
});

class MediaInfo {
  final String title;
  final String artist;
  final String? albumArt;
  final String source;
  final bool isPlaying;

  const MediaInfo({
    required this.title,
    required this.artist,
    this.albumArt,
    required this.source,
    this.isPlaying = false,
  });

  factory MediaInfo.fromMap(Map<dynamic, dynamic> map) {
    return MediaInfo(
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown',
      albumArt: map['albumArt'],
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

  // Debounce timer to avoid hammering Firestore
  Timer? _debounce;

  MediaService(this._firestoreService) {
    _startListening();
  }

  Stream<NowPlayingModel?> get mediaStream => _controller.stream;

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
          // Platform channel not set up yet (e.g. running in simulator without plugin)
          _controller.add(null);
        },
      );
    } catch (_) {
      // Silently fail on platforms where channel isn't registered
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
    );

    _controller.add(model);

    // Debounce Firestore writes by 5 seconds to reduce writes/cost
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

  /// Manually set now playing (fallback for iOS)
  Future<void> setManualNowPlaying({required String title, required String artist, required MediaSource source}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final model = NowPlayingModel(uid: uid, title: title, artist: artist, source: source, isActive: true);
    _controller.add(model);
    await _firestoreService.updateNowPlaying(model);
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

  void dispose() {
    _platformSub?.cancel();
    _debounce?.cancel();
    _controller.close();
  }
}
