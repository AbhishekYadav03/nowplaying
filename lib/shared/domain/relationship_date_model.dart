import 'package:cloud_firestore/cloud_firestore.dart';

class RelationshipDateModel {
  final String id;
  final String friendId;
  final String title;
  final String description;
  final DateTime date;
  final bool isRecursive;
  final DateTime createdAt;

  const RelationshipDateModel({
    required this.id,
    required this.friendId,
    required this.title,
    required this.description,
    required this.date,
    required this.isRecursive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'isRecursive': isRecursive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RelationshipDateModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return RelationshipDateModel(
      id: doc.id,
      friendId: map['friendId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isRecursive: map['isRecursive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  int get daysUntilNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDate = DateTime(today.year, date.month, date.day);
    if (nextDate.isBefore(today)) {
      return DateTime(today.year + 1, date.month, date.day).difference(today).inDays;
    }
    return nextDate.difference(today).inDays;
  }

  int get daysPassed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return today.difference(eventDate).inDays;
  }
}

