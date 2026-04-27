import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressModel {
  final String id;
  final String userId;
  final String sessionId;
  final int painLevelBefore;
  final int painLevelAfter;
  final String? notes;
  final DateTime recordedAt;

  const ProgressModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.painLevelBefore,
    required this.painLevelAfter,
    this.notes,
    required this.recordedAt,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgressModel(
      id: id,
      userId: map['userId'] as String,
      sessionId: map['sessionId'] as String,
      painLevelBefore: map['painLevelBefore'] as int,
      painLevelAfter: map['painLevelAfter'] as int,
      notes: map['notes'] as String?,
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
    );
  }

  factory ProgressModel.fromFirestore(DocumentSnapshot doc) {
    return ProgressModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'painLevelBefore': painLevelBefore,
      'painLevelAfter': painLevelAfter,
      'notes': notes,
      'recordedAt': Timestamp.fromDate(recordedAt),
    };
  }

  ProgressModel copyWith({
    String? id,
    String? userId,
    String? sessionId,
    int? painLevelBefore,
    int? painLevelAfter,
    String? notes,
    DateTime? recordedAt,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      painLevelBefore: painLevelBefore ?? this.painLevelBefore,
      painLevelAfter: painLevelAfter ?? this.painLevelAfter,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
