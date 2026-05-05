import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';

void main() {
  group('TherapistFeedbackModel', () {
    final baseMap = {
      'therapistId': 'tid1',
      'patientId': 'pid1',
      'type': 'session',
      'sessionId': 'sid1',
      'message': 'Great form today!',
      'createdAt': Timestamp.fromDate(DateTime(2026, 5, 5)),
      'readByPatient': false,
    };

    test('fromMap parses all fields correctly', () {
      final model = TherapistFeedbackModel.fromMap(baseMap, 'docId');
      expect(model.id, 'docId');
      expect(model.therapistId, 'tid1');
      expect(model.patientId, 'pid1');
      expect(model.type, 'session');
      expect(model.sessionId, 'sid1');
      expect(model.message, 'Great form today!');
      expect(model.readByPatient, false);
    });

    test('fromMap handles null sessionId for progress type', () {
      final map = {...baseMap, 'type': 'progress', 'sessionId': null};
      final model = TherapistFeedbackModel.fromMap(map, 'docId');
      expect(model.type, 'progress');
      expect(model.sessionId, isNull);
    });

    test('toMap round-trips correctly', () {
      final model = TherapistFeedbackModel.fromMap(baseMap, 'docId');
      final map = model.toMap();
      expect(map['therapistId'], 'tid1');
      expect(map['readByPatient'], false);
    });

    test('copyWith overrides readByPatient', () {
      final model = TherapistFeedbackModel.fromMap(baseMap, 'docId');
      final updated = model.copyWith(readByPatient: true);
      expect(updated.readByPatient, true);
      expect(updated.message, model.message);
    });
  });

  group('TherapistPlanModel', () {
    final baseMap = {
      'therapistId': 'tid1',
      'patientId': 'pid1',
      'title': 'Knee Recovery',
      'description': 'Week 1 plan',
      'exercises': [
        {'exerciseId': 'ex1', 'sets': 3, 'reps': 10, 'durationSecs': 30},
      ],
      'createdAt': Timestamp.fromDate(DateTime(2026, 5, 5)),
      'active': true,
    };

    test('fromMap parses exercises list', () {
      final model = TherapistPlanModel.fromMap(baseMap, 'planId');
      expect(model.exercises.length, 1);
      expect(model.exercises.first.exerciseId, 'ex1');
      expect(model.exercises.first.sets, 3);
    });

    test('toMap serialises exercises list', () {
      final model = TherapistPlanModel.fromMap(baseMap, 'planId');
      final map = model.toMap();
      expect((map['exercises'] as List).first['reps'], 10);
    });
  });
}
