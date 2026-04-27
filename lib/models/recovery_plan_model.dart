import 'package:cloud_firestore/cloud_firestore.dart';

class RecoveryPlanModel {
  final String id;
  final String userId;
  final String title;
  final String bodyArea;
  final int painSeverity;
  final List<String> exerciseIds;
  final DateTime createdAt;
  final bool isPersonalized;

  const RecoveryPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.bodyArea,
    required this.painSeverity,
    required this.exerciseIds,
    required this.createdAt,
    required this.isPersonalized,
  });

  factory RecoveryPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return RecoveryPlanModel(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      bodyArea: map['bodyArea'] as String,
      painSeverity: map['painSeverity'] as int,
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPersonalized: map['isPersonalized'] as bool,
    );
  }

  factory RecoveryPlanModel.fromFirestore(DocumentSnapshot doc) {
    return RecoveryPlanModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'bodyArea': bodyArea,
      'painSeverity': painSeverity,
      'exerciseIds': exerciseIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPersonalized': isPersonalized,
    };
  }

  RecoveryPlanModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? bodyArea,
    int? painSeverity,
    List<String>? exerciseIds,
    DateTime? createdAt,
    bool? isPersonalized,
  }) {
    return RecoveryPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      bodyArea: bodyArea ?? this.bodyArea,
      painSeverity: painSeverity ?? this.painSeverity,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt ?? this.createdAt,
      isPersonalized: isPersonalized ?? this.isPersonalized,
    );
  }
}
