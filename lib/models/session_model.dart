import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseTitle;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final bool completed;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.completed,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      userId: map['userId'] as String,
      exerciseId: map['exerciseId'] as String,
      exerciseTitle: map['exerciseTitle'] as String,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      durationSeconds: map['durationSeconds'] as int,
      completed: map['completed'] as bool,
    );
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    return SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseTitle': exerciseTitle,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'durationSeconds': durationSeconds,
      'completed': completed,
    };
  }

  SessionModel copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseTitle,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    bool? completed,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }
}
