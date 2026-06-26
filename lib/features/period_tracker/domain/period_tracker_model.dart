import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodTrackerModel {
  final DateTime? lastPeriodStart;
  final DateTime? lastPeriodEnd;
  final int cycleLength;
  final int periodDuration;
  final DateTime? updatedAt;

  const PeriodTrackerModel({
    this.lastPeriodStart,
    this.lastPeriodEnd,
    this.cycleLength = 28,
    this.periodDuration = 5,
    this.updatedAt,
  });

  factory PeriodTrackerModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const PeriodTrackerModel();
    final data = doc.data() as Map<String, dynamic>;
    return PeriodTrackerModel(
      lastPeriodStart: (data['lastPeriodStart'] as Timestamp?)?.toDate(),
      lastPeriodEnd: (data['lastPeriodEnd'] as Timestamp?)?.toDate(),
      cycleLength: data['cycleLength'] ?? 28,
      periodDuration: data['periodDuration'] ?? 5,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'lastPeriodStart': lastPeriodStart != null ? Timestamp.fromDate(lastPeriodStart!) : null,
    'lastPeriodEnd': lastPeriodEnd != null ? Timestamp.fromDate(lastPeriodEnd!) : null,
    'cycleLength': cycleLength,
    'periodDuration': periodDuration,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  PeriodTrackerModel copyWith({
    DateTime? lastPeriodStart,
    DateTime? lastPeriodEnd,
    int? cycleLength,
    int? periodDuration,
  }) {
    return PeriodTrackerModel(
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      lastPeriodEnd: lastPeriodEnd ?? this.lastPeriodEnd,
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      updatedAt: DateTime.now(),
    );
  }
}

class PeriodLogModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  PeriodLogModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory PeriodLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PeriodLogModel(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}


