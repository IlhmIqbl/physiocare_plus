import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiocare/services/notification_service.dart';

class PlanService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _planSubscription;

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

  void startPlanListener(String userId) {
    _planSubscription?.cancel();
    _planSubscription = _db
        .collection('recovery_plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) => _onPlanSnapshot(snapshot, userId));
  }

  void stopPlanListener() {
    _planSubscription?.cancel();
    _planSubscription = null;
  }

  Future<void> _onPlanSnapshot(
      QuerySnapshot snapshot, String userId) async {
    if (snapshot.docs.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastKnownAt = prefs.getInt('last_known_plan_at');

    final data =
        snapshot.docs.first.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];
    final planTimestamp = createdAt is Timestamp
        ? createdAt.millisecondsSinceEpoch
        : 0;

    if (lastKnownAt == null) {
      await prefs.setInt(
          'last_known_plan_at', DateTime.now().millisecondsSinceEpoch);
      return;
    }

    if (planTimestamp <= lastKnownAt) return;

    final userDoc = await _db.collection('users').doc(userId).get();
    final notifPrefs = userDoc.data()?['notificationPrefs'];
    if (notifPrefs?['planUpdates'] ?? true) {
      await NotificationService().showNewPlanNotification();
    }
    await prefs.setInt('last_known_plan_at', planTimestamp);
  }
}
