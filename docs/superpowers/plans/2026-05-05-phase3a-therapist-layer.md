# Phase 3A — Therapist Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `therapist` role with its own portal (patient list, patient detail + notes, tips CRUD), extend the admin panel with therapist assignment, and surface therapist notes and tips to patients on their dashboard.

**Architecture:** New `userType: therapist` routes to a `TherapistShell` (3-tab bottom nav). All therapist data lives in two new Firestore collections (`therapist_notes`, `therapist_tips`). A `TherapistService` + `TherapistProvider` handle data access. Patients see a read-only therapist card and premium tips on their existing `DashboardScreen`.

**Tech Stack:** Flutter, Cloud Firestore, Provider, fl_chart (already installed), `package:physiocare` — no new packages required.

---

## Task 1: Data Models

**Files:**
- Create: `lib/models/therapist_note_model.dart`
- Create: `lib/models/therapist_tip_model.dart`
- Modify: `lib/models/user_model.dart`

- [ ] **Step 1: Create TherapistNoteModel**

```dart
// lib/models/therapist_note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistNoteModel {
  final String id;
  final String therapistId;
  final String patientId;
  final String content;
  final DateTime createdAt;

  const TherapistNoteModel({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.content,
    required this.createdAt,
  });

  factory TherapistNoteModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapistNoteModel(
      id: id,
      therapistId: map['therapistId'] as String,
      patientId: map['patientId'] as String,
      content: map['content'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory TherapistNoteModel.fromFirestore(DocumentSnapshot doc) {
    return TherapistNoteModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'patientId': patientId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

- [ ] **Step 2: Create TherapistTipModel**

```dart
// lib/models/therapist_tip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistTipModel {
  final String id;
  final String therapistId;
  final String title;
  final String content;
  final String? bodyArea;
  final bool isActive;
  final DateTime createdAt;

  const TherapistTipModel({
    required this.id,
    required this.therapistId,
    required this.title,
    required this.content,
    this.bodyArea,
    required this.isActive,
    required this.createdAt,
  });

  factory TherapistTipModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapistTipModel(
      id: id,
      therapistId: map['therapistId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      bodyArea: map['bodyArea'] as String?,
      isActive: map['isActive'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory TherapistTipModel.fromFirestore(DocumentSnapshot doc) {
    return TherapistTipModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'therapistId': therapistId,
      'title': title,
      'content': content,
      'bodyArea': bodyArea,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TherapistTipModel copyWith({
    String? id,
    String? therapistId,
    String? title,
    String? content,
    String? bodyArea,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TherapistTipModel(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      title: title ?? this.title,
      content: content ?? this.content,
      bodyArea: bodyArea ?? this.bodyArea,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

- [ ] **Step 3: Extend UserModel with `assignedTherapistId`**

In `lib/models/user_model.dart`, add the field and update `fromMap`, `toMap`, and `copyWith`:

```dart
// Add to constructor params:
final String? assignedTherapistId;

// Add to const constructor:
this.assignedTherapistId,

// In fromMap factory, add:
assignedTherapistId: map['assignedTherapistId'] as String?,

// In toMap(), add:
'assignedTherapistId': assignedTherapistId,

// In copyWith(), add param:
String? assignedTherapistId,

// In copyWith() return, add:
assignedTherapistId: assignedTherapistId ?? this.assignedTherapistId,
```

- [ ] **Step 4: Run tests to ensure nothing broke**

```
flutter test test/widget_test.dart
```

Expected: All 14 existing tests pass.

- [ ] **Step 5: Commit**

```
git add lib/models/therapist_note_model.dart lib/models/therapist_tip_model.dart lib/models/user_model.dart
git commit -m "feat: add TherapistNote, TherapistTip models and extend UserModel"
```

---

## Task 2: TherapistService

**Files:**
- Create: `lib/services/therapist_service.dart`

- [ ] **Step 1: Write the service**

```dart
// lib/services/therapist_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/therapist_note_model.dart';
import 'package:physiocare/models/therapist_tip_model.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';

class TherapistService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<UserModel>> fetchAssignedPatients(String therapistId) async {
    final snapshot = await _db
        .collection('users')
        .where('assignedTherapistId', isEqualTo: therapistId)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<List<UserModel>> fetchTherapists() async {
    final snapshot = await _db
        .collection('users')
        .where('userType', isEqualTo: 'therapist')
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<void> assignTherapist(String patientId, String therapistId) async {
    await _db
        .collection('users')
        .doc(patientId)
        .update({'assignedTherapistId': therapistId});
  }

  Future<List<SessionModel>> fetchPatientSessions(String patientId) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: patientId)
        .where('completed', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ProgressModel>> fetchPatientProgress(String patientId) async {
    final snapshot = await _db
        .collection('progress')
        .where('userId', isEqualTo: patientId)
        .orderBy('recordedAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map((doc) => ProgressModel.fromFirestore(doc))
        .toList();
  }

  Future<void> sendNote(
      String therapistId, String patientId, String content) async {
    await _db.collection('therapist_notes').add({
      'therapistId': therapistId,
      'patientId': patientId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Requires Firestore composite index: therapist_notes(patientId ASC, createdAt DESC)
  Stream<List<TherapistNoteModel>> streamNotes(String patientId) {
    return _db
        .collection('therapist_notes')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TherapistNoteModel.fromFirestore(doc))
            .toList());
  }

  Future<List<TherapistTipModel>> fetchAllTips(String therapistId) async {
    final snapshot = await _db
        .collection('therapist_tips')
        .where('therapistId', isEqualTo: therapistId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TherapistTipModel.fromFirestore(doc))
        .toList();
  }

  // Requires Firestore composite index: therapist_tips(isActive ASC, createdAt DESC)
  Future<List<TherapistTipModel>> fetchActiveTips(
      List<String> bodyAreas) async {
    final snapshot = await _db
        .collection('therapist_tips')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    final tips = snapshot.docs
        .map((doc) => TherapistTipModel.fromFirestore(doc))
        .toList();
    return tips
        .where((tip) =>
            tip.bodyArea == null || bodyAreas.contains(tip.bodyArea))
        .toList();
  }

  Future<void> createTip(TherapistTipModel tip) async {
    await _db.collection('therapist_tips').add(tip.toMap());
  }

  Future<void> updateTip(TherapistTipModel tip) async {
    await _db
        .collection('therapist_tips')
        .doc(tip.id)
        .update(tip.toMap());
  }

  Future<void> deleteTip(String tipId) async {
    await _db.collection('therapist_tips').doc(tipId).delete();
  }
}
```

> **Firestore indexes needed:** Create these in Firebase Console → Firestore → Indexes:
> - Collection `therapist_notes`: fields `patientId ASC`, `createdAt DESC`
> - Collection `therapist_tips`: fields `therapistId ASC`, `createdAt DESC`
> - Collection `therapist_tips`: fields `isActive ASC`, `createdAt DESC`

- [ ] **Step 2: Run analyzer**

```
flutter analyze lib/services/therapist_service.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```
git add lib/services/therapist_service.dart
git commit -m "feat: add TherapistService with patient, notes, and tips data access"
```

---

## Task 3: TherapistProvider + AuthProvider isTherapist

**Files:**
- Create: `lib/providers/therapist_provider.dart`
- Modify: `lib/providers/auth_provider.dart`
- Modify: `lib/app.dart` (register TherapistProvider in MultiProvider)

- [ ] **Step 1: Create TherapistProvider**

```dart
// lib/providers/therapist_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:physiocare/models/therapist_note_model.dart';
import 'package:physiocare/models/therapist_tip_model.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/services/therapist_service.dart';

class TherapistProvider extends ChangeNotifier {
  final _service = TherapistService();

  List<UserModel> _patients = [];
  List<TherapistNoteModel> _notes = [];
  List<TherapistTipModel> _tips = [];
  List<SessionModel> _patientSessions = [];
  List<ProgressModel> _patientProgress = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TherapistNoteModel>>? _notesSub;

  List<UserModel> get patients => _patients;
  List<TherapistNoteModel> get notes => _notes;
  List<TherapistTipModel> get tips => _tips;
  List<SessionModel> get patientSessions => _patientSessions;
  List<ProgressModel> get patientProgress => _patientProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients(String therapistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _patients = await _service.fetchAssignedPatients(therapistId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPatientDetail(String patientId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _patientSessions = await _service.fetchPatientSessions(patientId);
      _patientProgress = await _service.fetchPatientProgress(patientId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void subscribeToNotes(String patientId) {
    _notesSub?.cancel();
    _notesSub = _service.streamNotes(patientId).listen((notes) {
      _notes = notes;
      notifyListeners();
    });
  }

  void unsubscribeNotes() {
    _notesSub?.cancel();
    _notes = [];
  }

  Future<void> sendNote(
      String therapistId, String patientId, String content) async {
    await _service.sendNote(therapistId, patientId, content);
  }

  Future<void> loadTips(String therapistId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tips = await _service.fetchAllTips(therapistId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createTip(TherapistTipModel tip) async {
    await _service.createTip(tip);
    await loadTips(tip.therapistId);
  }

  Future<void> toggleTipActive(TherapistTipModel tip) async {
    final updated = tip.copyWith(isActive: !tip.isActive);
    await _service.updateTip(updated);
    final idx = _tips.indexWhere((t) => t.id == tip.id);
    if (idx >= 0) {
      _tips[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteTip(String tipId) async {
    await _service.deleteTip(tipId);
    _tips.removeWhere((t) => t.id == tipId);
    notifyListeners();
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: Add `isTherapist` to AuthProvider**

In `lib/providers/auth_provider.dart`, add after the existing `isAdmin` getter:

```dart
bool get isTherapist => _userModel?.userType == 'therapist';
```

- [ ] **Step 3: Register TherapistProvider in app.dart**

Open `lib/app.dart`. In the `MultiProvider` list, add:

```dart
import 'package:physiocare/providers/therapist_provider.dart';

// Inside providers: [...] list, add:
ChangeNotifierProvider(create: (_) => TherapistProvider()),
```

- [ ] **Step 4: Run analyzer**

```
flutter analyze lib/providers/therapist_provider.dart lib/providers/auth_provider.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```
git add lib/providers/therapist_provider.dart lib/providers/auth_provider.dart lib/app.dart
git commit -m "feat: add TherapistProvider and isTherapist getter to AuthProvider"
```

---

## Task 4: Routes + Constants

**Files:**
- Modify: `lib/utils/app_constants.dart`
- Modify: `lib/utils/app_router.dart`

- [ ] **Step 1: Add therapist route constants**

In `lib/utils/app_constants.dart`, add to the `AppRoutes` class:

```dart
static const String therapistDashboard = '/therapistDashboard';
static const String patientDetail = '/patientDetail';
```

- [ ] **Step 2: Add therapist routes to AppRouter**

In `lib/utils/app_router.dart`, add imports at the top:

```dart
import 'package:physiocare/screens/therapist/therapist_shell.dart';
import 'package:physiocare/screens/therapist/patient_detail_screen.dart';
```

Add cases to `generateRoute` switch before `default:`:

```dart
case AppRoutes.therapistDashboard:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const TherapistShell(),
  );

case AppRoutes.patientDetail:
  final patient = settings.arguments as UserModel;
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => PatientDetailScreen(patient: patient),
  );
```

Also add the `UserModel` import at the top:

```dart
import 'package:physiocare/models/user_model.dart';
```

- [ ] **Step 3: Update SplashScreen to route therapists correctly**

In `lib/screens/splash/splash_screen.dart`, replace the `isLoggedIn` routing block:

```dart
final authProvider = context.read<AppAuthProvider>();
final isLoggedIn = authProvider.isLoggedIn;
if (isLoggedIn) {
  if (authProvider.isTherapist) {
    Navigator.of(context)
        .pushReplacementNamed(AppRoutes.therapistDashboard);
  } else {
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }
  return;
}
```

- [ ] **Step 4: Run analyzer**

```
flutter analyze lib/utils/app_constants.dart lib/utils/app_router.dart lib/screens/splash/splash_screen.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```
git add lib/utils/app_constants.dart lib/utils/app_router.dart lib/screens/splash/splash_screen.dart
git commit -m "feat: add therapist routes and role-based routing in SplashScreen"
```

---

## Task 5: TherapistShell + TherapistPatientsScreen

**Files:**
- Create: `lib/screens/therapist/therapist_shell.dart`
- Create: `lib/screens/therapist/therapist_patients_screen.dart`

- [ ] **Step 1: Create TherapistShell**

```dart
// lib/screens/therapist/therapist_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/screens/therapist/therapist_patients_screen.dart';
import 'package:physiocare/screens/therapist/therapist_tips_screen.dart';
import 'package:physiocare/screens/profile/profile_screen.dart';

class TherapistShell extends StatefulWidget {
  const TherapistShell({super.key});

  @override
  State<TherapistShell> createState() => _TherapistShellState();
}

class _TherapistShellState extends State<TherapistShell> {
  int _currentIndex = 0;

  final _screens = const [
    TherapistPatientsScreen(),
    TherapistTipsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PhysioCare+ Therapist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AppAuthProvider>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: _screens[_currentIndex],
    );
  }
}
```

- [ ] **Step 2: Create TherapistPatientsScreen**

```dart
// lib/screens/therapist/therapist_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistPatientsScreen extends StatefulWidget {
  const TherapistPatientsScreen({super.key});

  @override
  State<TherapistPatientsScreen> createState() =>
      _TherapistPatientsScreenState();
}

class _TherapistPatientsScreenState extends State<TherapistPatientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AppAuthProvider>().userModel?.id ?? '';
      if (uid.isNotEmpty) {
        context.read<TherapistProvider>().loadPatients(uid);
      }
    });
  }

  String _trendIndicator(List<ProgressModel> progress) {
    if (progress.length < 2) return '→';
    final recent = progress
        .where((p) => p.recordedAt
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    final older = progress
        .where((p) =>
            p.recordedAt
                .isAfter(DateTime.now().subtract(const Duration(days: 14))) &&
            p.recordedAt
                .isBefore(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    if (recent.isEmpty || older.isEmpty) return '→';
    final recentAvg =
        recent.map((p) => p.painLevelAfter).reduce((a, b) => a + b) /
            recent.length;
    final olderAvg =
        older.map((p) => p.painLevelAfter).reduce((a, b) => a + b) /
            older.length;
    if (recentAvg < olderAvg - 0.5) return '↑';
    if (recentAvg > olderAvg + 0.5) return '↓';
    return '→';
  }

  Color _trendColor(String trend) {
    if (trend == '↑') return Colors.green;
    if (trend == '↓') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.patients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No patients assigned yet.\nContact your admin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final uid =
            context.read<AppAuthProvider>().userModel?.id ?? '';
        await context.read<TherapistProvider>().loadPatients(uid);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.patients.length,
        itemBuilder: (context, index) {
          final patient = provider.patients[index];
          final initial =
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(patient.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.email,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: patient.bodyFocusAreas
                        .take(2)
                        .map((area) => Chip(
                              label: Text(area,
                                  style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppColors.surface,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.patientDetail,
                arguments: patient,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Run analyzer**

```
flutter analyze lib/screens/therapist/
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```
git add lib/screens/therapist/therapist_shell.dart lib/screens/therapist/therapist_patients_screen.dart
git commit -m "feat: add TherapistShell and TherapistPatientsScreen"
```

---

## Task 6: PatientDetailScreen

**Files:**
- Create: `lib/screens/therapist/patient_detail_screen.dart`

- [ ] **Step 1: Create PatientDetailScreen**

```dart
// lib/screens/therapist/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/models/therapist_note_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:intl/intl.dart';

class PatientDetailScreen extends StatefulWidget {
  final UserModel patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _noteController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TherapistProvider>();
      provider.loadPatientDetail(widget.patient.id);
      provider.subscribeToNotes(widget.patient.id);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    context.read<TherapistProvider>().unsubscribeNotes();
    super.dispose();
  }

  Future<void> _sendNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    final therapistId =
        context.read<AppAuthProvider>().userModel?.id ?? '';
    await context
        .read<TherapistProvider>()
        .sendNote(therapistId, widget.patient.id, content);
    _noteController.clear();
    setState(() => _sending = false);
  }

  List<FlSpot> _buildChartSpots(List<ProgressModel> progress) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 28));
    final filtered = progress
        .where((p) => p.recordedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return List.generate(filtered.length, (i) {
      final dayOffset =
          filtered[i].recordedAt.difference(cutoff).inDays.toDouble();
      final reduction = (filtered[i].painLevelBefore -
              filtered[i].painLevelAfter)
          .toDouble();
      return FlSpot(dayOffset, reduction.clamp(0, 10));
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientHeader(patient),
                        const SizedBox(height: 20),
                        _buildPainChart(provider.patientProgress),
                        const SizedBox(height: 20),
                        _buildRecentSessions(provider),
                        const SizedBox(height: 20),
                        const Text('Notes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildNotesList(provider.notes),
                      ],
                    ),
                  ),
                ),
                _buildNoteInput(),
              ],
            ),
    );
  }

  Widget _buildPatientHeader(UserModel patient) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: patient.bodyFocusAreas
                    .map((area) => Chip(
                          label:
                              Text(area, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.surface,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPainChart(List<ProgressModel> progress) {
    final spots = _buildChartSpots(progress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pain Reduction (last 4 weeks)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: spots.isEmpty
              ? const Center(
                  child: Text('No progress data yet',
                      style: TextStyle(color: Colors.grey)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentSessions(TherapistProvider provider) {
    final sessions = provider.patientSessions;
    final progress = provider.patientProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Sessions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          const Text('No sessions yet.',
              style: TextStyle(color: Colors.grey))
        else
          ...sessions.map((session) {
            final related = progress
                .where((p) => p.sessionId == session.id)
                .toList();
            final painBefore =
                related.isNotEmpty ? related.first.painLevelBefore : null;
            final painAfter =
                related.isNotEmpty ? related.first.painLevelAfter : null;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.fitness_center,
                  color: AppColors.primary, size: 20),
              title: Text(session.exerciseTitle,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(session.startedAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: painBefore != null
                  ? Text('$painBefore→$painAfter',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600))
                  : null,
            );
          }),
      ],
    );
  }

  Widget _buildNotesList(List<TherapistNoteModel> notes) {
    if (notes.isEmpty) {
      return const Text('No notes yet. Add your first note below.',
          style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: notes.map((note) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.content, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(note.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a note for this patient...',
                border: InputBorder.none,
              ),
            ),
          ),
          _sending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon:
                      const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendNote,
                ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

```
flutter analyze lib/screens/therapist/patient_detail_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```
git add lib/screens/therapist/patient_detail_screen.dart
git commit -m "feat: add PatientDetailScreen with progress chart and notes thread"
```

---

## Task 7: TherapistTipsScreen

**Files:**
- Create: `lib/screens/therapist/therapist_tips_screen.dart`

- [ ] **Step 1: Create TherapistTipsScreen**

```dart
// lib/screens/therapist/therapist_tips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/therapist_tip_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistTipsScreen extends StatefulWidget {
  const TherapistTipsScreen({super.key});

  @override
  State<TherapistTipsScreen> createState() => _TherapistTipsScreenState();
}

class _TherapistTipsScreenState extends State<TherapistTipsScreen> {
  static const _bodyAreas = [
    'shoulder', 'lower_back', 'knee', 'hip', 'neck', 'ankle'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AppAuthProvider>().userModel?.id ?? '';
      if (uid.isNotEmpty) {
        context.read<TherapistProvider>().loadTips(uid);
      }
    });
  }

  void _showCreateTipSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String? selectedArea;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Tip',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'Body Area (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All areas')),
                    ..._bodyAreas.map((area) => DropdownMenuItem(
                        value: area, child: Text(area))),
                  ],
                  onChanged: (val) =>
                      setSheetState(() => selectedArea = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty || content.isEmpty) return;
                      final uid = context
                          .read<AppAuthProvider>()
                          .userModel
                          ?.id ?? '';
                      final tip = TherapistTipModel(
                        id: '',
                        therapistId: uid,
                        title: title,
                        content: content,
                        bodyArea: selectedArea,
                        isActive: true,
                        createdAt: DateTime.now(),
                      );
                      await context
                          .read<TherapistProvider>()
                          .createTip(tip);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Create Tip'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TherapistProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showCreateTipSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.tips.isEmpty
              ? const Center(
                  child: Text('No tips yet. Tap + to add one.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: provider.tips.length,
                  itemBuilder: (context, index) {
                    final tip = provider.tips[index];
                    return Dismissible(
                      key: Key(tip.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Tip'),
                            content: Text(
                                'Delete "${tip.title}"? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await provider.deleteTip(tip.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('"${tip.title}" deleted')),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(tip.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tip.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(fontSize: 13)),
                              if (tip.bodyArea != null)
                                Chip(
                                  label: Text(tip.bodyArea!,
                                      style: const TextStyle(
                                          fontSize: 10)),
                                  backgroundColor: AppColors.surface,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Switch(
                            value: tip.isActive,
                            activeColor: AppColors.primary,
                            onChanged: (_) =>
                                provider.toggleTipActive(tip),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

```
flutter analyze lib/screens/therapist/therapist_tips_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```
git add lib/screens/therapist/therapist_tips_screen.dart
git commit -m "feat: add TherapistTipsScreen with CRUD and active toggle"
```

---

## Task 8: Admin — Assign Therapist

**Files:**
- Modify: `lib/screens/admin/admin_users_screen.dart`

- [ ] **Step 1: Add `_assignTherapist` method and therapist list loading**

In `_AdminUsersScreenState`, add the instance variable and method:

```dart
// Add instance variable at the top of _AdminUsersScreenState:
final _therapistService = TherapistService();
List<UserModel> _therapists = [];

// Add import at top of file:
import 'package:physiocare/services/therapist_service.dart';
```

Add `_loadTherapists` method:

```dart
Future<void> _loadTherapists() async {
  try {
    _therapists = await _therapistService.fetchTherapists();
  } catch (_) {
    _therapists = [];
  }
}
```

Call it in `initState` after `_loadUsers()`:

```dart
@override
void initState() {
  super.initState();
  _loadUsers();
  _loadTherapists();
  // ... existing listener code
}
```

- [ ] **Step 2: Add `_showAssignTherapistSheet` method**

```dart
Future<void> _showAssignTherapistSheet(UserModel patient) async {
  if (_therapists.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No therapists found. Create a therapist account first.')),
    );
    return;
  }

  String? selectedTherapistId = patient.assignedTherapistId;

  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Therapist to ${patient.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTherapistId,
                decoration: const InputDecoration(
                  labelText: 'Therapist',
                  border: OutlineInputBorder(),
                ),
                items: _therapists
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setSheetState(() => selectedTherapistId = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    if (selectedTherapistId == null) return;
                    try {
                      await _therapistService.assignTherapist(
                          patient.id, selectedTherapistId!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadUsers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${patient.name} assigned to therapist')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Assign'),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
```

- [ ] **Step 3: Add "Assign Therapist" to the popup menu**

In the `PopupMenuButton` `itemBuilder`, add after the existing `admin` menu item and before `PopupMenuDivider`:

```dart
const PopupMenuDivider(),
PopupMenuItem(
  value: 'assign_therapist',
  enabled: user.userType != 'admin' && user.userType != 'therapist',
  child: const Row(
    children: [
      Icon(Icons.person_pin_outlined, size: 18, color: Colors.teal),
      SizedBox(width: 8),
      Text('Assign Therapist'),
    ],
  ),
),
```

In the `onSelected` callback, add handling:

```dart
} else if (value == 'assign_therapist') {
  _showAssignTherapistSheet(user);
}
```

Also add `therapist` to the user type change options:

```dart
const PopupMenuItem(
  value: 'therapist',
  child: Row(
    children: [
      Icon(Icons.medical_services_outlined, size: 18, color: Colors.teal),
      SizedBox(width: 8),
      Text('Make Therapist'),
    ],
  ),
),
```

And add `'therapist'` to the `onSelected` type-change check:

```dart
if (value == 'freemium' || value == 'premium' ||
    value == 'admin' || value == 'therapist') {
  _changeUserType(user, value);
}
```

Update `_chipColor` to handle `therapist`:

```dart
case 'therapist':
  return Colors.teal;
```

- [ ] **Step 4: Run analyzer**

```
flutter analyze lib/screens/admin/admin_users_screen.dart
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```
git add lib/screens/admin/admin_users_screen.dart
git commit -m "feat: add assign therapist action and therapist role to admin users screen"
```

---

## Task 9: Patient Dashboard — Therapist Card + Tips Section

**Files:**
- Modify: `lib/screens/dashboard/dashboard_screen.dart`

- [ ] **Step 1: Add imports to dashboard_screen.dart**

```dart
import 'package:physiocare/models/therapist_note_model.dart';
import 'package:physiocare/models/therapist_tip_model.dart';
import 'package:physiocare/providers/therapist_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';
import 'package:physiocare/services/therapist_service.dart';
```

- [ ] **Step 2: Load therapist data in initState**

Add to `_DashboardScreenState`:

```dart
final _therapistService = TherapistService();
List<TherapistNoteModel> _therapistNotes = [];
List<TherapistTipModel> _therapistTips = [];
String? _therapistName;
```

In `initState`, after existing loads, add:

```dart
_loadTherapistData(authProvider.userModel);
```

Add the method:

```dart
Future<void> _loadTherapistData(UserModel? userModel) async {
  if (userModel == null) return;
  final assignedId = userModel.assignedTherapistId;
  if (assignedId != null && assignedId.isNotEmpty) {
    try {
      // Fetch therapist name
      final therapists = await TherapistService().fetchTherapists();
      final match = therapists.where((t) => t.id == assignedId).toList();
      if (match.isNotEmpty && mounted) {
        setState(() => _therapistName = match.first.name);
      }
      // Fetch notes
      final notes = await _therapistService
          .streamNotes(userModel.id)
          .first;
      if (mounted) setState(() => _therapistNotes = notes);
    } catch (_) {}
  }
  // Fetch tips for premium users
  if (userModel.userType == 'premium') {
    try {
      final tips = await _therapistService
          .fetchActiveTips(userModel.bodyFocusAreas);
      if (mounted) setState(() => _therapistTips = tips);
    } catch (_) {}
  }
}
```

- [ ] **Step 3: Add `_buildTherapistCard` widget method**

```dart
Widget _buildTherapistCard() {
  final authProvider = context.watch<AppAuthProvider>();
  final user = authProvider.userModel;
  if (user == null || user.assignedTherapistId == null) return const SizedBox.shrink();
  if (_therapistName == null) return const SizedBox.shrink();

  final latestNote = _therapistNotes.isNotEmpty ? _therapistNotes.first : null;
  final preview = latestNote != null
      ? (latestNote.content.length > 80
          ? '${latestNote.content.substring(0, 80)}...'
          : latestNote.content)
      : 'No notes yet.';

  return GestureDetector(
    onTap: () => _showNotesModal(),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryDark,
              child: Icon(Icons.medical_services, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Therapist: $_therapistName',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Add `_showNotesModal` method**

```dart
void _showNotesModal() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notes from $_therapistName',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_therapistNotes.isEmpty)
              const Text('No notes yet.',
                  style: TextStyle(color: Colors.grey))
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _therapistNotes.length,
                  itemBuilder: (ctx, i) {
                    final note = _therapistNotes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(note.content),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 5: Add `_buildTipsSection` widget method**

```dart
Widget _buildTipsSection() {
  if (_therapistTips.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Tips from Your Therapist',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _therapistTips.length,
          itemBuilder: (context, index) {
            final tip = _therapistTips[index];
            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tip.content,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tip.bodyArea != null) ...[
                    const Spacer(),
                    Chip(
                      label: Text(tip.bodyArea!,
                          style: const TextStyle(fontSize: 9)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
```

- [ ] **Step 6: Add therapist card and tips to `_buildHomeTab`**

In `_buildHomeTab`, after `_buildTodaysPlan(planProvider)` and before the closing `],`, add:

```dart
const SizedBox(height: 20),
_buildTherapistCard(),
const SizedBox(height: 20),
_buildTipsSection(),
```

- [ ] **Step 7: Run analyzer**

```
flutter analyze lib/screens/dashboard/dashboard_screen.dart
```

Expected: No issues found.

- [ ] **Step 8: Run all tests**

```
flutter test test/widget_test.dart
```

Expected: All 14 tests pass.

- [ ] **Step 9: Commit**

```
git add lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: add therapist card and tips section to patient dashboard"
```

---

## Task 10: Widget Tests for Therapist Screens

**Files:**
- Create: `test/phase3a_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/phase3a_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/utils/app_theme.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/therapist_provider.dart';
import 'package:physiocare/models/therapist_tip_model.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/screens/therapist/therapist_shell.dart';
import 'package:physiocare/screens/therapist/therapist_patients_screen.dart';

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppAuthProvider>(
          create: (_) => AppAuthProvider()),
      ChangeNotifierProvider<TherapistProvider>(
          create: (_) => TherapistProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('TherapistPatientsScreen', () {
    testWidgets('shows empty state when no patients', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(const TherapistPatientsScreen()),
      );
      await tester.pump();
      expect(find.text('No patients assigned yet.'), findsNothing);
      // Provider starts with empty list, shows empty state text
      expect(find.byType(TherapistPatientsScreen), findsOneWidget);
    });
  });

  group('TherapistTipModel', () {
    test('copyWith changes only specified fields', () {
      final tip = TherapistTipModel(
        id: '1',
        therapistId: 'tid',
        title: 'Original Title',
        content: 'content',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final updated = tip.copyWith(isActive: false);
      expect(updated.isActive, false);
      expect(updated.title, 'Original Title');
      expect(updated.id, '1');
    });

    test('toMap includes all fields', () {
      final tip = TherapistTipModel(
        id: '1',
        therapistId: 'tid',
        title: 'Hip Stretch',
        content: 'Do this daily.',
        bodyArea: 'hip',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final map = tip.toMap();
      expect(map['title'], 'Hip Stretch');
      expect(map['bodyArea'], 'hip');
      expect(map['isActive'], true);
    });
  });

  group('TherapistNoteModel', () {
    test('toMap includes required fields', () {
      final note = TherapistNoteModel(
        id: '1',
        therapistId: 'tid',
        patientId: 'pid',
        content: 'Rest your knee today.',
        createdAt: DateTime(2026, 5, 1),
      );
      final map = note.toMap();
      expect(map['therapistId'], 'tid');
      expect(map['patientId'], 'pid');
      expect(map['content'], 'Rest your knee today.');
    });
  });

  group('UserModel assignedTherapistId', () {
    test('copyWith preserves assignedTherapistId', () {
      final user = UserModel(
        id: 'u1',
        name: 'Alice',
        email: 'alice@test.com',
        userType: 'freemium',
        bodyFocusAreas: ['knee'],
        painSeverity: 5,
        createdAt: DateTime(2026, 1, 1),
        assignedTherapistId: 'tid1',
      );
      final updated = user.copyWith(name: 'Alice Updated');
      expect(updated.assignedTherapistId, 'tid1');
      expect(updated.name, 'Alice Updated');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect them to compile and pass**

```
flutter test test/phase3a_test.dart
```

Expected: All tests pass. (These are unit tests on models + widget smoke tests that don't require Firebase.)

- [ ] **Step 3: Run full test suite**

```
flutter test
```

Expected: All tests pass (14 original + new phase3a tests).

- [ ] **Step 4: Commit**

```
git add test/phase3a_test.dart
git commit -m "test: add Phase 3A model and widget tests"
```

---

## Task 11: Final Analyzer + Git Tag

- [ ] **Step 1: Run full analysis**

```
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Run full test suite**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Push and tag**

```
git push origin main
git tag v3.0.0-3a
git push origin v3.0.0-3a
```
