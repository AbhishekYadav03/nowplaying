import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaSource { spotify, youtube, youtubeMusic, appleMusic, other }

extension MediaSourceExt on MediaSource {
  String get label {
    switch (this) {
      case MediaSource.spotify:
        return 'Spotify';
      case MediaSource.youtube:
        return 'YouTube';
      case MediaSource.appleMusic:
        return 'Apple Music';
      case MediaSource.other:
        return 'Music';
      case MediaSource.youtubeMusic:
        return 'YouTube Music';
    }
  }

  String get iconAsset {
    switch (this) {
      case MediaSource.spotify:
        return 'assets/images/spotify.png';
      case MediaSource.youtube:
        return 'assets/images/youtube.png';
      case MediaSource.youtubeMusic:
        return 'assets/images/youtube_music.png';
      case MediaSource.appleMusic:
        return 'assets/images/apple_music.png';
      case MediaSource.other:
        return 'assets/images/music.png';
    }
  }
}

class NowPlayingModel {
  final String uid;
  final String title;
  final String artist;
  final String? packageName;
  final String? albumArt;
  final MediaSource source;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isPlaying;
  final String? userName;
  final String? userPhoto;

  const NowPlayingModel({
    required this.uid,
    required this.title,
    required this.artist,
    this.albumArt,
    this.source = MediaSource.other,
    this.updatedAt,
    this.isActive = true,
    this.isPlaying = true,
    this.userName,
    this.userPhoto,
    this.packageName,
  });

  factory NowPlayingModel.fromFirestore(DocumentSnapshot doc, {String? userName, String? userPhoto}) {
    final data = doc.data() as Map<String, dynamic>;
    return NowPlayingModel(
      uid: doc.id,
      title: data['title'] ?? 'Unknown',
      artist: data['artist'] ?? 'Unknown',
      albumArt: data['albumArt'],
      packageName: data['packageName'],
      source: _parseSource(data['source']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      isPlaying: data['isPlaying'] ?? false,
      userName: userName,
      userPhoto: userPhoto,
    );
  }

  static MediaSource _parseSource(String? s) {
    switch (s?.toLowerCase()) {
      case 'spotify':
        return MediaSource.spotify;
      case 'youtube':
        return MediaSource.youtube;
      case 'youtube music':
      case 'youtubemusic':
      case 'com.google.android.apps.youtube.music':
        return MediaSource.youtubeMusic;
      case 'apple music':
      case 'applemusic':
        return MediaSource.appleMusic;
      default:
        return MediaSource.other;
    }
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'title': title,
    'artist': artist,
    'albumArt': albumArt,
    'packageName': packageName,
    'source': source.label,
    'updatedAt': FieldValue.serverTimestamp(),
    'isActive': isActive,
    'isPlaying': isPlaying,
  };
}

class ReactionModel {
  final String id;
  final String fromUid;
  final String emoji;
  final DateTime? createdAt;
  final String? fromUserName;

  const ReactionModel({
    required this.id,
    required this.fromUid,
    required this.emoji,
    this.createdAt,
    this.fromUserName,
  });

  factory ReactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReactionModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      emoji: data['emoji'] ?? '❤️',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
