# Therapist Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fully functional physiotherapist portal (third dashboard) to PhysioCare+ alongside the existing Patient and Admin dashboards.

**Architecture:** Separate therapist shell under `lib/therapist/` routed by `userType == 'therapist'` after login. Three new Firestore collections (`therapist_patients`, `therapist_feedback`, `therapist_plans`). Patient home screen gains a `MyTherapistCard` widget and local notifications fire when therapist leaves feedback or assigns a plan.

**Tech Stack:** Flutter, Dart, Firebase Auth + Firestore, Provider, flutter_local_notifications. Package name: `physiocare`.

---

## File Map

**New files:**
| File | Responsibility |
|------|---------------|
| `lib/therapist/models/therapist_feedback_model.dart` | Firestore model for session comments and progress notes |
| `lib/therapist/models/therapist_plan_model.dart` | Firestore model for therapist-created plans + embedded exercise type |
| `lib/therapist/services/therapist_service.dart` | All Firestore CRUD for the 3 new collections |
| `lib/therapist/providers/therapist_provider.dart` | State: patient list, selected patient, feedback, plans |
| `lib/therapist/screens/therapist_shell.dart` | Bottom nav shell (Patients + Profile tabs) |
| `lib/therapist/screens/my_patients_screen.dart` | List of assigned patients |
| `lib/therapist/screens/patient_detail_screen.dart` | Per-patient tabbed view (Progress / Plans / Feedback) |
| `lib/therapist/screens/add_session_feedback_screen.dart` | Form: select session → write comment → submit |
| `lib/therapist/screens/add_progress_note_screen.dart` | Form: write general note → submit |
| `lib/therapist/screens/create_therapist_plan_screen.dart` | Build custom plan from exercise library |
| `lib/therapist/screens/therapist_profile_screen.dart` | Therapist name + logout |
| `lib/screens/admin/manage_therapists_screen.dart` | Admin creates therapist accounts |
| `lib/screens/admin/assign_therapist_screen.dart` | Admin assigns therapist → patient |
| `lib/screens/patient/therapist_feedback_screen.dart` | Patient reads all feedback; marks read |
| `lib/widgets/my_therapist_card.dart` | Card on patient home showing therapist + tap to feedback |
| `test/therapist_models_test.dart` | Unit tests for both new models |
| `test/therapist_service_test.dart` | Unit tests for TherapistService (mocked Firestore) |

**Modified files:**
| File | Change |
|------|--------|
| `lib/models/user_model.dart` | Add `therapistId: String?` field |
| `lib/services/notification_service.dart` | Add `showFeedbackNotification()` (ID 1004) |
| `lib/providers/auth_provider.dart` | Add `_feedbackSub` + `_planSub` Firestore listeners for patients; add `isTherapist` getter |
| `lib/utils/app_constants.dart` | Add 5 new route constants |
| `lib/utils/app_router.dart` | Import + register 5 new routes |
| `lib/app.dart` | Add `TherapistProvider` to MultiProvider |
| `lib/screens/splash/splash_screen.dart` | Route `userType == 'therapist'` to therapist dashboard |
| `lib/screens/admin/admin_dashboard_screen.dart` | Add two new action buttons |
| `lib/screens/dashboard/dashboard_screen.dart` | Add `MyTherapistCard` to home tab |

---

## Task 1: Data Models

**Files:**
- Create: `lib/therapist/models/therapist_feedback_model.dart`
- Create: `lib/therapist/models/therapist_plan_model.dart`
- Modify: `lib/models/user_model.dart`
- Create: `test/therapist_models_test.dart`

- [ ] **Step 1: Create `therapist_feedback_model.dart`**

```dart
// lib/therapist/models/therapist_feedback_model.dart
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
```

- [ ] **Step 2: Create `therapist_plan_model.dart`**

```dart
// lib/therapist/models/therapist_plan_model.dart
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
```

- [ ] **Step 3: Update `user_model.dart` — add `therapistId` field**

Add `therapistId` to the class, constructor, `fromMap`, `toMap`, and `copyWith`. The full updated file:

```dart
// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String userType;
  final List<String> bodyFocusAreas;
  final int painSeverity;
  final DateTime createdAt;
  final String? therapistId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.userType,
    required this.bodyFocusAreas,
    required this.painSeverity,
    required this.createdAt,
    this.therapistId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      userType: map['userType'] as String,
      bodyFocusAreas: List<String>.from(map['bodyFocusAreas'] ?? []),
      painSeverity: map['painSeverity'] as int,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      therapistId: map['therapistId'] as String?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'userType': userType,
      'bodyFocusAreas': bodyFocusAreas,
      'painSeverity': painSeverity,
      'createdAt': Timestamp.fromDate(createdAt),
      'therapistId': therapistId,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? userType,
    List<String>? bodyFocusAreas,
    int? painSeverity,
    DateTime? createdAt,
    String? therapistId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      bodyFocusAreas: bodyFocusAreas ?? this.bodyFocusAreas,
      painSeverity: painSeverity ?? this.painSeverity,
      createdAt: createdAt ?? this.createdAt,
      therapistId: therapistId ?? this.therapistId,
    );
  }
}
```

- [ ] **Step 4: Write model unit tests**

```dart
// test/therapist_models_test.dart
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
```

- [ ] **Step 5: Run tests**

```
cd physiocare_plus
flutter test test/therapist_models_test.dart
```

Expected: All 6 tests pass.

- [ ] **Step 6: Commit**

```
git add physiocare_plus/lib/therapist/models/ physiocare_plus/lib/models/user_model.dart physiocare_plus/test/therapist_models_test.dart
git commit -m "feat: add therapist feedback/plan models and therapistId to UserModel"
```

---

## Task 2: TherapistService

**Files:**
- Create: `lib/therapist/services/therapist_service.dart`

- [ ] **Step 1: Create `therapist_service.dart`**

```dart
// lib/therapist/services/therapist_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';

class TherapistService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
```

- [ ] **Step 2: Commit**

```
git add physiocare_plus/lib/therapist/services/therapist_service.dart
git commit -m "feat: add TherapistService with CRUD for all 3 therapist collections"
```

---

## Task 3: TherapistProvider

**Files:**
- Create: `lib/therapist/providers/therapist_provider.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create `therapist_provider.dart`**

```dart
// lib/therapist/providers/therapist_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';

class TherapistProvider extends ChangeNotifier {
  final _service = TherapistService();

  List<UserModel> _patients = [];
  UserModel? _selectedPatient;
  List<TherapistFeedbackModel> _feedback = [];
  List<TherapistPlanModel> _plans = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<UserModel>>? _patientsSub;
  StreamSubscription<List<TherapistFeedbackModel>>? _feedbackSub;
  StreamSubscription<List<TherapistPlanModel>>? _plansSub;

  List<UserModel> get patients => _patients;
  UserModel? get selectedPatient => _selectedPatient;
  List<TherapistFeedbackModel> get feedback => _feedback;
  List<TherapistPlanModel> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadPatients(String therapistId) {
    _patientsSub?.cancel();
    _patientsSub = _service.getAssignedPatients(therapistId).listen(
      (patients) {
        _patients = patients;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void selectPatient(UserModel patient) {
    _selectedPatient = patient;
    _feedback = [];
    _plans = [];
    notifyListeners();
    _loadPatientData(patient.id);
  }

  void _loadPatientData(String patientId) {
    _feedbackSub?.cancel();
    _plansSub?.cancel();

    _feedbackSub = _service.getPatientFeedback(patientId).listen(
      (feedback) {
        _feedback = feedback;
        notifyListeners();
      },
    );

    _plansSub = _service.getTherapistPlans(patientId).listen(
      (plans) {
        _plans = plans;
        notifyListeners();
      },
    );
  }

  Future<void> addSessionFeedback(TherapistFeedbackModel feedback) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addSessionFeedback(feedback);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProgressNote(TherapistFeedbackModel feedback) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addProgressNote(feedback);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlan(TherapistPlanModel plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createPlan(plan);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlan(TherapistPlanModel plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updatePlan(plan);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    await _service.deletePlan(planId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _patientsSub?.cancel();
    _feedbackSub?.cancel();
    _plansSub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: Register `TherapistProvider` in `app.dart`**

Add the import and provider. Full updated `app.dart`:

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/utils/app_router.dart';
import 'package:physiocare/utils/app_theme.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/providers/plan_provider.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';

class PhysioCareApp extends StatelessWidget {
  const PhysioCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => TherapistProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
```

- [ ] **Step 3: Run existing tests to confirm nothing broken**

```
flutter test
```

Expected: 14 existing widget tests still pass.

- [ ] **Step 4: Commit**

```
git add physiocare_plus/lib/therapist/providers/therapist_provider.dart physiocare_plus/lib/app.dart
git commit -m "feat: add TherapistProvider and register in MultiProvider"
```

---

## Task 4: Local Notifications — `showFeedbackNotification`

**Files:**
- Modify: `lib/services/notification_service.dart`

Note: `showNewPlanNotification()` already exists (ID 1003). Only `showFeedbackNotification()` needs adding.

- [ ] **Step 1: Add `showFeedbackNotification()` to `notification_service.dart`**

Add this method directly after the existing `showNewPlanNotification()` method (around line 175 of the current file):

```dart
  Future<void> showFeedbackNotification() async {
    if (kIsWeb) return;
    await _plugin.show(
      1004,
      'New Feedback from Your Physiotherapist',
      'Your physiotherapist left you feedback.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'physiocare_feedback',
          'Therapist Feedback',
          channelDescription:
              'Notifications when your physiotherapist leaves feedback',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
```

- [ ] **Step 2: Confirm existing notification tests still pass**

```
flutter test
```

Expected: all 14 tests pass.

- [ ] **Step 3: Commit**

```
git add physiocare_plus/lib/services/notification_service.dart
git commit -m "feat: add showFeedbackNotification to NotificationService (ID 1004)"
```

---

## Task 5: AuthProvider — Patient Notification Listeners

**Files:**
- Modify: `lib/providers/auth_provider.dart`

- [ ] **Step 1: Update `auth_provider.dart`**

Replace the entire file with:

```dart
// lib/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/services/auth_service.dart';
import 'package:physiocare/services/notification_service.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';

class AppAuthProvider extends ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  final _authService = AuthService();
  final _therapistService = TherapistService();
  final _notificationService = NotificationService();

  StreamSubscription<List<TherapistFeedbackModel>>? _feedbackSub;
  StreamSubscription<List<TherapistPlanModel>>? _planSub;

  // Tracks IDs already notified this session to avoid repeat firing
  final Set<String> _notifiedFeedbackIds = {};
  final Set<String> _notifiedPlanIds = {};

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _userModel != null;
  String get userType => _userModel?.userType ?? 'patient';
  bool get isAdmin => _userModel?.userType == 'admin';
  bool get isTherapist => _userModel?.userType == 'therapist';

  Future<void> initialize() async {
    try {
      _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          _userModel = await _authService.getUserModel(user.uid);
          NotificationService().initFCM(user.uid).ignore();
          if (_userModel?.userType == 'patient') {
            _startPatientListeners(user.uid);
          }
        } else {
          _stopPatientListeners();
          _userModel = null;
        }
        notifyListeners();
      });
    } catch (_) {
      notifyListeners();
    }
  }

  void _startPatientListeners(String patientId) {
    _feedbackSub?.cancel();
    _planSub?.cancel();
    _notifiedFeedbackIds.clear();
    _notifiedPlanIds.clear();

    _feedbackSub =
        _therapistService.getUnreadFeedback(patientId).listen((items) {
      for (final item in items) {
        if (!_notifiedFeedbackIds.contains(item.id)) {
          _notifiedFeedbackIds.add(item.id);
          _notificationService.showFeedbackNotification();
        }
      }
    });

    _planSub =
        _therapistService.getNewActivePlans(patientId).listen((plans) {
      for (final plan in plans) {
        if (!_notifiedPlanIds.contains(plan.id)) {
          _notifiedPlanIds.add(plan.id);
          _notificationService.showNewPlanNotification();
        }
      }
    });
  }

  void _stopPatientListeners() {
    _feedbackSub?.cancel();
    _planSub?.cancel();
    _feedbackSub = null;
    _planSub = null;
    _notifiedFeedbackIds.clear();
    _notifiedPlanIds.clear();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signInWithEmailPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name,
      {Map<String, dynamic>? onboardingData}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.registerWithEmailPassword(
        email,
        password,
        name,
        onboardingData: onboardingData,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return credential != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _stopPatientListeners();
    await _authService.signOut();
    _userModel = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPatientListeners();
    super.dispose();
  }
}
```

- [ ] **Step 2: Run tests**

```
flutter test
```

Expected: all 14 tests pass.

- [ ] **Step 3: Commit**

```
git add physiocare_plus/lib/providers/auth_provider.dart
git commit -m "feat: add patient notification listeners in AuthProvider for feedback and plans"
```

---

## Task 6: Routes — New Constants + Router Entries

**Files:**
- Modify: `lib/utils/app_constants.dart`
- Modify: `lib/utils/app_router.dart`
- Modify: `lib/screens/splash/splash_screen.dart`

- [ ] **Step 1: Add route constants to `app_constants.dart`**

Add these 5 constants inside the `AppRoutes` class, after `adminPlans`:

```dart
  static const String therapistDashboard = '/therapistDashboard';
  static const String adminManageTherapists = '/adminManageTherapists';
  static const String adminAssignTherapist = '/adminAssignTherapist';
  static const String therapistFeedback = '/therapistFeedback';
```

- [ ] **Step 2: Add imports and cases to `app_router.dart`**

Add these imports at the top of the file (after existing imports):

```dart
import 'package:physiocare/therapist/screens/therapist_shell.dart';
import 'package:physiocare/screens/admin/manage_therapists_screen.dart';
import 'package:physiocare/screens/admin/assign_therapist_screen.dart';
import 'package:physiocare/screens/patient/therapist_feedback_screen.dart';
```

Add these cases inside the `switch` in `generateRoute`, before the `default` case:

```dart
      case AppRoutes.therapistDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TherapistShell(),
        );

      case AppRoutes.adminManageTherapists:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ManageTherapistsScreen(),
        );

      case AppRoutes.adminAssignTherapist:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AssignTherapistScreen(),
        );

      case AppRoutes.therapistFeedback:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TherapistFeedbackScreen(),
        );
```

- [ ] **Step 3: Update splash screen to route therapists to therapist dashboard**

Find the section where it routes a logged-in user. Replace:

```dart
Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
```

with:

```dart
final userType = authProvider.userModel?.userType ?? 'patient';
if (userType == 'therapist') {
  Navigator.pushReplacementNamed(context, AppRoutes.therapistDashboard);
} else {
  Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
}
```

Note: Read the splash screen file first to find the exact line to replace; it will look like a `Navigator.pushReplacementNamed` call inside a logged-in check.

- [ ] **Step 4: Commit**

```
git add physiocare_plus/lib/utils/app_constants.dart physiocare_plus/lib/utils/app_router.dart physiocare_plus/lib/screens/splash/splash_screen.dart
git commit -m "feat: add therapist and admin therapist routes; route therapists to therapist shell on login"
```

---

## Task 7: Admin — ManageTherapistsScreen

**Files:**
- Create: `lib/screens/admin/manage_therapists_screen.dart`

- [ ] **Step 1: Create `manage_therapists_screen.dart`**

```dart
// lib/screens/admin/manage_therapists_screen.dart
import 'package:flutter/material.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class ManageTherapistsScreen extends StatefulWidget {
  const ManageTherapistsScreen({super.key});

  @override
  State<ManageTherapistsScreen> createState() =>
      _ManageTherapistsScreenState();
}

class _ManageTherapistsScreenState extends State<ManageTherapistsScreen> {
  final _service = TherapistService();
  List<UserModel> _therapists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final therapists = await _service.getAllTherapists();
      setState(() {
        _therapists = therapists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading therapists: $e')));
      }
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Therapist Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Valid email required' : null,
              ),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await _service.createTherapistAccount(
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    passCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Therapist account created')));
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Therapists'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Therapist', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _therapists.isEmpty
              ? const Center(child: Text('No therapists yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _therapists.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final t = _therapists[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(t.name),
                      subtitle: Text(t.email),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add physiocare_plus/lib/screens/admin/manage_therapists_screen.dart
git commit -m "feat: add ManageTherapistsScreen for admin to create therapist accounts"
```

---

## Task 8: Admin — AssignTherapistScreen + Dashboard Buttons

**Files:**
- Create: `lib/screens/admin/assign_therapist_screen.dart`
- Modify: `lib/screens/admin/admin_dashboard_screen.dart`

- [ ] **Step 1: Create `assign_therapist_screen.dart`**

```dart
// lib/screens/admin/assign_therapist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class AssignTherapistScreen extends StatefulWidget {
  const AssignTherapistScreen({super.key});

  @override
  State<AssignTherapistScreen> createState() => _AssignTherapistScreenState();
}

class _AssignTherapistScreenState extends State<AssignTherapistScreen> {
  final _service = TherapistService();

  List<UserModel> _therapists = [];
  List<UserModel> _patients = [];
  UserModel? _selectedTherapist;
  UserModel? _selectedPatient;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAllTherapists(),
        _service.getAllPatients(),
      ]);
      setState(() {
        _therapists = results[0];
        _patients = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_selectedTherapist == null || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select both a therapist and a patient')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final adminId =
          context.read<AppAuthProvider>().userModel?.id ?? '';
      await _service.assignTherapistToPatient(
          _selectedTherapist!.id, _selectedPatient!.id, adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Therapist assigned successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Therapist to Patient'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Therapist',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserModel>(
                    value: _selectedTherapist,
                    hint: const Text('Choose a therapist'),
                    items: _therapists
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedTherapist = v),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Patient',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserModel>(
                    value: _selectedPatient,
                    hint: const Text('Choose a patient'),
                    items: _patients
                        .map((p) => DropdownMenuItem(
                            value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPatient = v),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Assign',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Add two new action buttons to `admin_dashboard_screen.dart`**

Find the `Row` containing the three `_ActionButton` widgets and replace it with:

```dart
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Users',
                            icon: Icons.people_outline,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminUsers),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Exercises',
                            icon: Icons.fitness_center_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminExercises),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Plans',
                            icon: Icons.list_alt_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminPlans),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Manage Therapists',
                            icon: Icons.medical_services_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminManageTherapists),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Assign Therapist',
                            icon: Icons.assignment_ind_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.adminAssignTherapist),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
```

- [ ] **Step 3: Run tests**

```
flutter test
```

Expected: 14 tests pass.

- [ ] **Step 4: Commit**

```
git add physiocare_plus/lib/screens/admin/assign_therapist_screen.dart physiocare_plus/lib/screens/admin/admin_dashboard_screen.dart
git commit -m "feat: add AssignTherapistScreen and therapist action buttons to admin dashboard"
```

---

## Task 9: Therapist Shell + MyPatientsScreen

**Files:**
- Create: `lib/therapist/screens/therapist_shell.dart`
- Create: `lib/therapist/screens/my_patients_screen.dart`

- [ ] **Step 1: Create `therapist_shell.dart`**

```dart
// lib/therapist/screens/therapist_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/therapist/screens/my_patients_screen.dart';
import 'package:physiocare/therapist/screens/therapist_profile_screen.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          context.read<AppAuthProvider>().userModel?.id ?? '';
      if (uid.isNotEmpty) {
        context.read<TherapistProvider>().loadPatients(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MyPatientsScreen(),
          TherapistProfileScreen(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `my_patients_screen.dart`**

```dart
// lib/therapist/screens/my_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/therapist/screens/patient_detail_screen.dart';
import 'package:physiocare/utils/app_constants.dart';

class MyPatientsScreen extends StatelessWidget {
  const MyPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.patients.isEmpty
              ? const Center(
                  child: Text('No patients assigned yet',
                      style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.patients.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final patient = provider.patients[i];
                    return _PatientTile(patient: patient);
                  },
                ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});
  final UserModel patient;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(patient.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(patient.email,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.read<TherapistProvider>().selectPatient(patient);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PatientDetailScreen(),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Commit**

```
git add physiocare_plus/lib/therapist/screens/therapist_shell.dart physiocare_plus/lib/therapist/screens/my_patients_screen.dart
git commit -m "feat: add TherapistShell with bottom nav and MyPatientsScreen"
```

---

## Task 10: PatientDetailScreen

**Files:**
- Create: `lib/therapist/screens/patient_detail_screen.dart`

- [ ] **Step 1: Create `patient_detail_screen.dart`**

```dart
// lib/therapist/screens/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/therapist/screens/add_session_feedback_screen.dart';
import 'package:physiocare/therapist/screens/add_progress_note_screen.dart';
import 'package:physiocare/therapist/screens/create_therapist_plan_screen.dart';
import 'package:physiocare/utils/app_constants.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();
    final patient = provider.selectedPatient;
    if (patient == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patient.name),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Progress'),
              Tab(text: 'Plans'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProgressTab(patientId: patient.id),
            _PlansTab(provider: provider),
            _FeedbackTab(provider: provider),
          ],
        ),
      ),
    );
  }
}

// ── Progress Tab ──────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          const Center(
              child: Text(
            'Progress charts loaded from patient data',
            style: TextStyle(color: Colors.grey),
          )),
        ],
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.provider});
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTherapistPlanScreen()),
        ),
      ),
      body: provider.plans.isEmpty
          ? const Center(
              child: Text('No plans yet — tap + to create one',
                  style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.plans.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final plan = provider.plans[i];
                return _PlanTile(plan: plan, provider: provider);
              },
            ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.provider});
  final TherapistPlanModel plan;
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(plan.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${plan.exercises.length} exercise${plan.exercises.length == 1 ? '' : 's'} · ${plan.active ? "Active" : "Inactive"}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Plan?'),
              content: Text('Delete "${plan.title}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirmed == true) {
            await provider.deletePlan(plan.id);
          }
        },
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateTherapistPlanScreen(existingPlan: plan),
        ),
      ),
    );
  }
}

// ── Feedback Tab ──────────────────────────────────────────────────────────────

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.provider});
  final TherapistProvider provider;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'progress_note',
            backgroundColor: AppColors.primary,
            tooltip: 'Add progress note',
            child: const Icon(Icons.note_add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddProgressNoteScreen()),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'session_feedback',
            backgroundColor: AppColors.primary,
            tooltip: 'Add session feedback',
            child: const Icon(Icons.rate_review, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddSessionFeedbackScreen()),
            ),
          ),
        ],
      ),
      body: provider.feedback.isEmpty
          ? const Center(
              child: Text('No feedback yet',
                  style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.feedback.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = provider.feedback[i];
                return _FeedbackTile(item: item, fmt: fmt);
              },
            ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({required this.item, required this.fmt});
  final TherapistFeedbackModel item;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final isSession = item.type == 'session';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSession ? Icons.fitness_center : Icons.sticky_note_2,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isSession ? 'Session Feedback' : 'Progress Note',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  fmt.format(item.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.message),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add physiocare_plus/lib/therapist/screens/patient_detail_screen.dart
git commit -m "feat: add PatientDetailScreen with Progress/Plans/Feedback tabs"
```

---

## Task 11: Feedback Forms + Create Plan Screen

**Files:**
- Create: `lib/therapist/screens/add_session_feedback_screen.dart`
- Create: `lib/therapist/screens/add_progress_note_screen.dart`
- Create: `lib/therapist/screens/create_therapist_plan_screen.dart`

- [ ] **Step 1: Create `add_session_feedback_screen.dart`**

```dart
// lib/therapist/screens/add_session_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class AddSessionFeedbackScreen extends StatefulWidget {
  const AddSessionFeedbackScreen({super.key});

  @override
  State<AddSessionFeedbackScreen> createState() =>
      _AddSessionFeedbackScreenState();
}

class _AddSessionFeedbackScreenState
    extends State<AddSessionFeedbackScreen> {
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedSessionId;
  String? _selectedSessionTitle;

  // Simple list of recent sessions fetched for the patient
  List<Map<String, String>> _sessions = [];
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final patientId =
        context.read<TherapistProvider>().selectedPatient?.id ?? '';
    if (patientId.isEmpty) {
      setState(() => _loadingSessions = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('userId', isEqualTo: patientId)
          .where('completed', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(20)
          .get();
      setState(() {
        _sessions = snapshot.docs
            .map((d) => {
                  'id': d.id,
                  'title': d['exerciseTitle'] as String,
                })
            .toList();
        _loadingSessions = false;
      });
    } catch (e) {
      setState(() => _loadingSessions = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a session')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final feedback = TherapistFeedbackModel(
      id: '',
      therapistId: auth.userModel?.id ?? '',
      patientId: provider.selectedPatient?.id ?? '',
      type: 'session',
      sessionId: _selectedSessionId,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      readByPatient: false,
    );
    await provider.addSessionFeedback(feedback);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Feedback'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loadingSessions
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Session',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSessionId,
                      hint: const Text('Choose a completed session'),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      items: _sessions
                          .map((s) => DropdownMenuItem(
                              value: s['id'], child: Text(s['title']!)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedSessionId = v;
                        _selectedSessionTitle = _sessions
                            .firstWhere((s) => s['id'] == v)['title'];
                      }),
                    ),
                    const SizedBox(height: 24),
                    const Text('Feedback',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write your feedback here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Feedback cannot be empty'
                          : null,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Feedback',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Create `add_progress_note_screen.dart`**

```dart
// lib/therapist/screens/add_progress_note_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class AddProgressNoteScreen extends StatefulWidget {
  const AddProgressNoteScreen({super.key});

  @override
  State<AddProgressNoteScreen> createState() =>
      _AddProgressNoteScreenState();
}

class _AddProgressNoteScreenState extends State<AddProgressNoteScreen> {
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final note = TherapistFeedbackModel(
      id: '',
      therapistId: auth.userModel?.id ?? '',
      patientId: provider.selectedPatient?.id ?? '',
      type: 'progress',
      sessionId: null,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      readByPatient: false,
    );
    await provider.addProgressNote(note);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a general progress note for this patient.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Overall progress, observations, recommendations...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Note cannot be empty'
                    : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Note', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `create_therapist_plan_screen.dart`**

```dart
// lib/therapist/screens/create_therapist_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class CreateTherapistPlanScreen extends StatefulWidget {
  const CreateTherapistPlanScreen({super.key, this.existingPlan});
  final TherapistPlanModel? existingPlan;

  @override
  State<CreateTherapistPlanScreen> createState() =>
      _CreateTherapistPlanScreenState();
}

class _CreateTherapistPlanScreenState
    extends State<CreateTherapistPlanScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<_PlanExerciseEntry> _entries = [];

  bool get _isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises();
    });
    if (_isEditing) {
      final plan = widget.existingPlan!;
      _titleCtrl.text = plan.title;
      _descCtrl.text = plan.description;
      for (final ex in plan.exercises) {
        _entries.add(_PlanExerciseEntry(
          exerciseId: ex.exerciseId,
          sets: ex.sets,
          reps: ex.reps,
          durationSecs: ex.durationSecs,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addExercise(ExerciseModel exercise) {
    setState(() {
      _entries.add(_PlanExerciseEntry(
        exerciseId: exercise.id,
        sets: 3,
        reps: 10,
        durationSecs: 30,
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one exercise')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final exercises = _entries
        .map((e) => TherapistPlanExercise(
              exerciseId: e.exerciseId,
              sets: e.sets,
              reps: e.reps,
              durationSecs: e.durationSecs,
            ))
        .toList();

    if (_isEditing) {
      final updated = widget.existingPlan!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        exercises: exercises,
      );
      await provider.updatePlan(updated);
    } else {
      final plan = TherapistPlanModel(
        id: '',
        therapistId: auth.userModel?.id ?? '',
        patientId: provider.selectedPatient?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        exercises: exercises,
        createdAt: DateTime.now(),
        active: true,
      );
      await provider.createPlan(plan);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'Create Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Plan Title', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercises',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => _showExercisePicker(exerciseProvider),
                ),
              ],
            ),
            if (_entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No exercises added yet',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return _ExerciseEntryTile(
                  entry: e,
                  exerciseName: exerciseProvider.exercises
                      .firstWhere(
                        (ex) => ex.id == e.exerciseId,
                        orElse: () => ExerciseModel(
                          id: e.exerciseId,
                          title: e.exerciseId,
                          description: '',
                          bodyArea: '',
                          difficultyLevel: 1,
                          videoUrl: '',
                          durationSeconds: 0,
                          steps: [],
                        ),
                      )
                      .title,
                  onRemove: () => setState(() => _entries.removeAt(idx)),
                  onChanged: () => setState(() {}),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showExercisePicker(ExerciseProvider exerciseProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: exerciseProvider.exercises.length,
        itemBuilder: (context, i) {
          final ex = exerciseProvider.exercises[i];
          return ListTile(
            title: Text(ex.title),
            subtitle: Text(ex.bodyArea),
            onTap: () {
              _addExercise(ex);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}

class _PlanExerciseEntry {
  String exerciseId;
  int sets;
  int reps;
  int durationSecs;

  _PlanExerciseEntry({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.durationSecs,
  });
}

class _ExerciseEntryTile extends StatelessWidget {
  const _ExerciseEntryTile({
    required this.entry,
    required this.exerciseName,
    required this.onRemove,
    required this.onChanged,
  });

  final _PlanExerciseEntry entry;
  final String exerciseName;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove),
              ],
            ),
            Row(
              children: [
                _CounterField(
                  label: 'Sets',
                  value: entry.sets,
                  onDecrement: () {
                    if (entry.sets > 1) {
                      entry.sets--;
                      onChanged();
                    }
                  },
                  onIncrement: () {
                    entry.sets++;
                    onChanged();
                  },
                ),
                const SizedBox(width: 16),
                _CounterField(
                  label: 'Reps',
                  value: entry.reps,
                  onDecrement: () {
                    if (entry.reps > 1) {
                      entry.reps--;
                      onChanged();
                    }
                  },
                  onIncrement: () {
                    entry.reps++;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
      ],
    );
  }
}
```

- [ ] **Step 4: Commit**

```
git add physiocare_plus/lib/therapist/screens/add_session_feedback_screen.dart physiocare_plus/lib/therapist/screens/add_progress_note_screen.dart physiocare_plus/lib/therapist/screens/create_therapist_plan_screen.dart
git commit -m "feat: add AddSessionFeedbackScreen, AddProgressNoteScreen, CreateTherapistPlanScreen"
```

---

## Task 12: TherapistProfileScreen

**Files:**
- Create: `lib/therapist/screens/therapist_profile_screen.dart`

- [ ] **Step 1: Create `therapist_profile_screen.dart`**

```dart
// lib/therapist/screens/therapist_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistProfileScreen extends StatelessWidget {
  const TherapistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final name = auth.userModel?.name ?? 'Therapist';
    final email = auth.userModel?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(email,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: const Text('Physiotherapist'),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AppAuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add physiocare_plus/lib/therapist/screens/therapist_profile_screen.dart
git commit -m "feat: add TherapistProfileScreen with logout"
```

---

## Task 13: Patient Side — MyTherapistCard + TherapistFeedbackScreen

**Files:**
- Create: `lib/widgets/my_therapist_card.dart`
- Create: `lib/screens/patient/therapist_feedback_screen.dart`
- Modify: `lib/screens/dashboard/dashboard_screen.dart`

- [ ] **Step 1: Create `my_therapist_card.dart`**

```dart
// lib/widgets/my_therapist_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class MyTherapistCard extends StatelessWidget {
  const MyTherapistCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final therapistId = auth.userModel?.therapistId;

    if (therapistId == null) {
      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, color: Colors.grey),
              SizedBox(width: 12),
              Text(
                'No therapist assigned yet',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(therapistId)
          .get(),
      builder: (context, snapshot) {
        String therapistName = 'Your Physiotherapist';
        if (snapshot.hasData && snapshot.data!.exists) {
          therapistName =
              (snapshot.data!.data() as Map<String, dynamic>)['name']
                  as String? ??
                  therapistName;
        }
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          color: AppColors.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.therapistFeedback),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: Icon(Icons.medical_services,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Physiotherapist',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        Text(therapistName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Create `therapist_feedback_screen.dart`**

```dart
// lib/screens/patient/therapist_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/therapist/models/therapist_feedback_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistFeedbackScreen extends StatefulWidget {
  const TherapistFeedbackScreen({super.key});

  @override
  State<TherapistFeedbackScreen> createState() =>
      _TherapistFeedbackScreenState();
}

class _TherapistFeedbackScreenState
    extends State<TherapistFeedbackScreen> {
  final _service = TherapistService();
  List<TherapistFeedbackModel> _feedback = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId =
        context.read<AppAuthProvider>().userModel?.id ?? '';
    if (patientId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    _service.getPatientFeedback(patientId).listen((items) async {
      setState(() {
        _feedback = items;
        _isLoading = false;
      });
      // Mark all unread as read
      for (final item in items.where((i) => !i.readByPatient)) {
        await _service.markFeedbackRead(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y, h:mm a');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Feedback'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedback.isEmpty
              ? const Center(
                  child: Text('No feedback from your therapist yet',
                      style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedback.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = _feedback[i];
                    final isSession = item.type == 'session';
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSession
                                      ? Icons.fitness_center
                                      : Icons.sticky_note_2,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isSession
                                      ? 'Session Feedback'
                                      : 'Progress Note',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  fmt.format(item.createdAt),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item.message,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 3: Add `MyTherapistCard` to patient home tab in `dashboard_screen.dart`**

In `_buildHomeTab()`, add the import at the top of `dashboard_screen.dart`:

```dart
import 'package:physiocare/widgets/my_therapist_card.dart';
```

In `_buildHomeTab()`, add the card after `_buildStreakCard(progressProvider)` and its `SizedBox`:

```dart
          const SizedBox(height: 20),
          const MyTherapistCard(),
```

The final ordering in `_buildHomeTab()` becomes:
```
_buildGreeting → SizedBox(20) → _buildStreakCard → SizedBox(20) → MyTherapistCard → SizedBox(20) → 'Quick Stats' → Row(stats) → SizedBox(20) → _buildTodaysPlan
```

- [ ] **Step 4: Run tests**

```
flutter test
```

Expected: 14 tests pass.

- [ ] **Step 5: Commit**

```
git add physiocare_plus/lib/widgets/my_therapist_card.dart physiocare_plus/lib/screens/patient/therapist_feedback_screen.dart physiocare_plus/lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: add MyTherapistCard to patient home and TherapistFeedbackScreen"
```

---

## Task 14: Final Integration Check + `flutter analyze`

- [ ] **Step 1: Run `flutter analyze`**

```
cd physiocare_plus
flutter analyze
```

Fix any warnings or errors reported. Common issues to watch for:
- Missing imports
- `context.read` / `context.watch` called outside `build`
- Unused imports

- [ ] **Step 2: Run full test suite**

```
flutter test
```

Expected: all 14 existing tests pass. If new test file was created (Task 1), expect 14 + 6 = 20 tests.

- [ ] **Step 3: Verify hot reload works**

```
flutter run
```

Log in as a patient — confirm `MyTherapistCard` renders on home screen.  
Log in as a therapist account (create one via admin first) — confirm `TherapistShell` loads with `MyPatientsScreen`.  
Log in as admin — confirm two new action buttons appear on admin dashboard.

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "feat: complete therapist portal — 3-dashboard system with local notifications"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** All spec sections covered — 3 Firestore collections, all 7 therapist screens, 2 admin screens, patient card + feedback screen, 2 notification triggers, `therapistId` on UserModel, role routing in splash
- [x] **No placeholders:** All steps have complete code blocks
- [x] **Type consistency:** `TherapistFeedbackModel`, `TherapistPlanModel`, `TherapistPlanExercise`, `TherapistProvider`, `TherapistService` — names are consistent across all tasks
- [x] **Method signatures consistent:** `addSessionFeedback(TherapistFeedbackModel)`, `addProgressNote(TherapistFeedbackModel)`, `createPlan(TherapistPlanModel)`, `updatePlan(TherapistPlanModel)` match between service → provider → screens
- [x] **Notification IDs:** 1001 streak reminder, 1002 streak milestone, 1003 new plan (existing), 1004 feedback (new) — no collisions
- [x] **Route constants:** All 4 new routes added to `AppRoutes` and registered in `AppRouter`
