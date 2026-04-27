import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String id;
  final String title;
  final String description;
  final String bodyArea;
  final String difficulty;
  final int duration;
  final String videoUrl;
  final String thumbnailUrl;
  final List<String> targetPainTypes;
  final List<String> steps;
  final bool isActive;
  final DateTime createdAt;

  const ExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.bodyArea,
    required this.difficulty,
    required this.duration,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.targetPainTypes,
    required this.steps,
    required this.isActive,
    required this.createdAt,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExerciseModel(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      bodyArea: map['bodyArea'] as String,
      difficulty: map['difficulty'] as String,
      duration: map['duration'] as int,
      videoUrl: map['videoUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
      targetPainTypes: List<String>.from(map['targetPainTypes'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      isActive: map['isActive'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    return ExerciseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'bodyArea': bodyArea,
      'difficulty': difficulty,
      'duration': duration,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'targetPainTypes': targetPainTypes,
      'steps': steps,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExerciseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? bodyArea,
    String? difficulty,
    int? duration,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? targetPainTypes,
    List<String>? steps,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bodyArea: bodyArea ?? this.bodyArea,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      targetPainTypes: targetPainTypes ?? this.targetPainTypes,
      steps: steps ?? this.steps,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
