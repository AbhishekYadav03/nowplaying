import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? fcmToken;
  final bool isSharingEnabled;
  final List<String> friends;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String? appVersion;
  final String? partnerId;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.fcmToken,
    this.isSharingEnabled = true,
    this.friends = const [],
    this.createdAt,
    this.lastSeen,
    this.appVersion,
    this.partnerId,
  });

  bool get isOnline {
    if (lastSeen == null) return false;
    // Consider online if seen in the last 2 minutes
    return DateTime.now().difference(lastSeen!).inMinutes < 2;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'User',
      photoURL: data['photoURL'],
      fcmToken: data['fcmToken'],
      isSharingEnabled: data['isSharingEnabled'] ?? true,
      friends: List<String>.from(data['friends'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      appVersion: data['appVersion'],
      partnerId: data['partnerId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoURL': photoURL,
    'fcmToken': fcmToken,
    'isSharingEnabled': isSharingEnabled,
    'friends': friends,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
    'appVersion': appVersion,
    'partnerId': partnerId,
  };

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? fcmToken,
    bool? isSharingEnabled,
    List<String>? friends,
    DateTime? lastSeen,
    String? appVersion,
    String? partnerId,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      fcmToken: fcmToken ?? this.fcmToken,
      isSharingEnabled: isSharingEnabled ?? this.isSharingEnabled,
      friends: friends ?? this.friends,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      appVersion: appVersion ?? this.appVersion,
      partnerId: partnerId ?? this.partnerId,
    );
  }
}
