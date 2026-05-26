import 'package:cloud_firestore/cloud_firestore.dart';

class RelationshipDateModel {
  final String id;
  final String friendId;
  final String title;
  final String description;
  final DateTime date;
  final bool isRecursive;
  final DateTime createdAt;

  RelationshipDateModel({
    required this.id,
    required this.friendId,
    required this.title,
    required this.description,
    required this.date,
    required this.isRecursive,
    required this.createdAt,
  });

  factory RelationshipDateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelationshipDateModel(
      id: doc.id,
      friendId: data['friendId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isRecursive: data['isRecursive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'friendId': friendId,
    'title': title,
    'description': description,
    'date': Timestamp.fromDate(date),
    'isRecursive': isRecursive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  RelationshipDateModel copyWith({String? title, String? description, DateTime? date, bool? isRecursive}) {
    return RelationshipDateModel(
      id: id,
      friendId: friendId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isRecursive: isRecursive ?? this.isRecursive,
      createdAt: createdAt,
    );
  }

  // Logic for calculations
  int get daysPassed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return today.difference(eventDate).inDays;
  }

  DateTime get nextOccurrence {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, date.month, date.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, date.month, date.day);
    }
    return next;
  }

  int get daysUntilNext {
    final next = nextOccurrence;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return next.difference(today).inDays;
  }
}
