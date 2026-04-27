import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/models/exercise_model.dart';

class PlanService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _difficultyForSeverity(int severity) {
    if (severity >= 7) return 'easy';
    if (severity >= 4) return 'medium';
    return 'hard';
  }

  Future<RecoveryPlanModel> generatePlan(
      String userId, String bodyArea, int painSeverity) async {
    final difficulty = _difficultyForSeverity(painSeverity);

    final snapshot = await _db
        .collection('exercises')
        .where('isActive', isEqualTo: true)
        .where('bodyArea', isEqualTo: bodyArea)
        .where('difficulty', isEqualTo: difficulty)
        .get();

    final exercises =
        snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList();
    final exerciseIds = exercises.map((e) => e.id).toList();

    final now = DateTime.now();
    final docRef = _db.collection('recovery_plans').doc();

    final plan = RecoveryPlanModel(
      id: docRef.id,
      userId: userId,
      title: '$bodyArea Recovery Plan',
      bodyArea: bodyArea,
      painSeverity: painSeverity,
      exerciseIds: exerciseIds,
      createdAt: now,
      isPersonalized: true,
    );

    await docRef.set(plan.toMap());
    return plan;
  }

  Future<List<RecoveryPlanModel>> getUserPlans(String userId) async {
    final snapshot = await _db
        .collection('recovery_plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => RecoveryPlanModel.fromFirestore(doc))
        .toList();
  }

  Future<RecoveryPlanModel?> getActivePlan(String userId) async {
    final snapshot = await _db
        .collection('recovery_plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return RecoveryPlanModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> deletePlan(String planId) async {
    await _db.collection('recovery_plans').doc(planId).delete();
  }
}
