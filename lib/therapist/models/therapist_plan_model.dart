import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistPlanExercise {
  final String exerciseId;
  final int sets;
  final int reps;
  final int durationSecs;

  const TherapistPlanExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.durationSecs,
  });

  factory TherapistPlanExercise.fromMap(Map<String, dynamic> map) {
    return TherapistPlanExercise(
      exerciseId: map['exerciseId'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      durationSecs: map['durationSecs'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'durationSecs': durationSecs,
    };
  }
}

class TherapistPlanModel {
  final String id;
  final String therapistId;
  final String patientId;
  final String title;
  final String description;
  final List<TherapistPlanExercise> exercises;
  final DateTime createdAt;
  final bool active;

  const TherapistPlanModel({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.title,
    required this.description,
    required this.exercises,
    required this.createdAt,
    required this.active,
  });

  factory TherapistPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapistPlanModel(
      id: id,
      therapistId: map['therapistId'] as String,
      patientId: map['patientId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) =>
              TherapistPlanExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      active: map['active'] as bool,
    );
  }

  factory TherapistPlanModel.fromFirestore(DocumentSnapshot doc) {
    return TherapistPlanModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      'title': title,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'active': active,
    };
  }

  TherapistPlanModel copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    String? title,
    String? description,
    List<TherapistPlanExercise>? exercises,
    DateTime? createdAt,
    bool? active,
  }) {
    return TherapistPlanModel(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }
}
