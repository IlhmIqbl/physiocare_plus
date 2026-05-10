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
  final int stepsCompleted;
  final int totalSteps;
  final String status;
  final int? painLevel;
  final String? painNote;
  final double completionPercent;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.completed,
    this.stepsCompleted = 0,
    this.totalSteps = 0,
    this.status = 'in_progress',
    this.painLevel,
    this.painNote,
    this.completionPercent = 0.0,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseTitle: map['exerciseTitle'] as String? ?? '',
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
      stepsCompleted: map['stepsCompleted'] as int? ?? 0,
      totalSteps: map['totalSteps'] as int? ?? 0,
      status: map['status'] as String? ?? 'in_progress',
      painLevel: map['painLevel'] as int?,
      painNote: map['painNote'] as String?,
      completionPercent:
          (map['completionPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) =>
      SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'exerciseId': exerciseId,
        'exerciseTitle': exerciseTitle,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'durationSeconds': durationSeconds,
        'completed': completed,
        'stepsCompleted': stepsCompleted,
        'totalSteps': totalSteps,
        'status': status,
        'painLevel': painLevel,
        'painNote': painNote,
        'completionPercent': completionPercent,
      };

  SessionModel copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseTitle,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    bool? completed,
    int? stepsCompleted,
    int? totalSteps,
    String? status,
    int? painLevel,
    String? painNote,
    double? completionPercent,
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
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      totalSteps: totalSteps ?? this.totalSteps,
      status: status ?? this.status,
      painLevel: painLevel ?? this.painLevel,
      painNote: painNote ?? this.painNote,
      completionPercent: completionPercent ?? this.completionPercent,
    );
  }
}
