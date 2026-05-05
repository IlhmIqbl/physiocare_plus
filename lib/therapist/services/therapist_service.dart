import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';

class TherapistService {
  final _db = FirebaseFirestore.instance;

  // ── Patient list ─────────────────────────────────────────────────────────

  Stream<List<UserModel>> getAssignedPatients(String therapistId) {
    return _db
        .collection('therapist_patients')
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .asyncMap((snapshot) async {
      final patientIds =
          snapshot.docs.map((d) => d['patientId'] as String).toList();
      if (patientIds.isEmpty) return [];
      final futures = patientIds
          .map((id) => _db.collection('users').doc(id).get())
          .toList();
      final docs = await Future.wait(futures);
      return docs
          .where((d) => d.exists)
          .map((d) => UserModel.fromFirestore(d))
          .toList();
    });
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Stream<List<TherapistFeedbackModel>> getPatientFeedback(String patientId) {
    return _db
        .collection('therapist_feedback')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TherapistFeedbackModel.fromFirestore(d))
            .toList());
  }

  Future<void> addSessionFeedback(TherapistFeedbackModel feedback) async {
    await _db.collection('therapist_feedback').add(feedback.toMap());
  }

  Future<void> addProgressNote(TherapistFeedbackModel feedback) async {
    await _db.collection('therapist_feedback').add(feedback.toMap());
  }

  Future<void> markFeedbackRead(String feedbackId) async {
    await _db
        .collection('therapist_feedback')
        .doc(feedbackId)
        .update({'readByPatient': true});
  }

  // ── Therapist plans ───────────────────────────────────────────────────────

  Stream<List<TherapistPlanModel>> getTherapistPlans(String patientId) {
    return _db
        .collection('therapist_plans')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TherapistPlanModel.fromFirestore(d)).toList());
  }

  Future<void> createPlan(TherapistPlanModel plan) async {
    await _db.collection('therapist_plans').add(plan.toMap());
  }

  Future<void> updatePlan(TherapistPlanModel plan) async {
    await _db
        .collection('therapist_plans')
        .doc(plan.id)
        .update(plan.toMap());
  }

  Future<void> deletePlan(String planId) async {
    await _db.collection('therapist_plans').doc(planId).delete();
  }

  // ── Admin operations ──────────────────────────────────────────────────────

  Future<List<UserModel>> getAllTherapists() async {
    final snapshot = await _db
        .collection('users')
        .where('userType', isEqualTo: 'therapist')
        .get();
    return snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  Future<List<UserModel>> getAllPatients() async {
    final snapshot = await _db
        .collection('users')
        .where('userType', isEqualTo: 'patient')
        .get();
    return snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  Future<void> createTherapistAccount(
      String name, String email, String password) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'userType': 'therapist',
      'photoUrl': null,
      'bodyFocusAreas': [],
      'painSeverity': 0,
      'createdAt': Timestamp.now(),
      'therapistId': null,
    });
  }

  Future<void> assignTherapistToPatient(
      String therapistId, String patientId, String adminId) async {
    final batch = _db.batch();

    // Remove any existing assignment for this patient
    final existing = await _db
        .collection('therapist_patients')
        .where('patientId', isEqualTo: patientId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Create new assignment
    final newRef = _db.collection('therapist_patients').doc();
    batch.set(newRef, {
      'therapistId': therapistId,
      'patientId': patientId,
      'assignedAt': Timestamp.now(),
      'assignedBy': adminId,
    });

    // Write therapistId onto patient's user doc
    batch.update(_db.collection('users').doc(patientId),
        {'therapistId': therapistId});

    await batch.commit();
  }

  // ── Notification listeners (used by AuthProvider) ─────────────────────────

  Stream<List<TherapistFeedbackModel>> getUnreadFeedback(String patientId) {
    return _db
        .collection('therapist_feedback')
        .where('patientId', isEqualTo: patientId)
        .where('readByPatient', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TherapistFeedbackModel.fromFirestore(d))
            .toList());
  }

  Stream<List<TherapistPlanModel>> getNewActivePlans(String patientId) {
    return _db
        .collection('therapist_plans')
        .where('patientId', isEqualTo: patientId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TherapistPlanModel.fromFirestore(d)).toList());
  }
}
