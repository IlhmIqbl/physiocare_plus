import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistFeedbackModel {
  final String id;
  final String therapistId;
  final String patientId;
  final String type; // 'session' or 'progress'
  final String? sessionId;
  final String message;
  final DateTime createdAt;
  final bool readByPatient;

  const TherapistFeedbackModel({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.type,
    this.sessionId,
    required this.message,
    required this.createdAt,
    required this.readByPatient,
  });

  factory TherapistFeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapistFeedbackModel(
      id: id,
      therapistId: map['therapistId'] as String,
      patientId: map['patientId'] as String,
      type: map['type'] as String,
      sessionId: map['sessionId'] as String?,
      message: map['message'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readByPatient: map['readByPatient'] as bool,
    );
  }

  factory TherapistFeedbackModel.fromFirestore(DocumentSnapshot doc) {
    return TherapistFeedbackModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      'type': type,
      'sessionId': sessionId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'readByPatient': readByPatient,
    };
  }

  TherapistFeedbackModel copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    String? type,
    String? sessionId,
    String? message,
    DateTime? createdAt,
    bool? readByPatient,
  }) {
    return TherapistFeedbackModel(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      readByPatient: readByPatient ?? this.readByPatient,
    );
  }
}
