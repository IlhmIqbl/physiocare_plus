# Exercise Session Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-timer exercise session with a step-by-step fitness session where each step has its own Cloudinary-hosted video, a per-step auto-advance countdown with pause toggle, a persistent "I'm in pain" stop button, and full session data recorded to Firestore.

**Architecture:** `ExerciseStep` becomes a first-class model replacing `List<String>` steps in `ExerciseModel`. `SessionModel` gains completion/pain fields. `ExerciseSessionScreen` is rewritten to drive a `VideoPlayerController` per step with a countdown. Stop flow uses `PainStopDialog`; completion navigates to `SessionCompleteScreen`.

**Tech Stack:** Flutter, Cloud Firestore, `video_player` + `chewie` (already in pubspec), Provider

---

### Task 1: ExerciseStep model

**Files:**
- Create: `lib/models/exercise_step_model.dart`

- [ ] **Step 1: Create the file**

```dart
class ExerciseStep {
  final String description;
  final String videoUrl;
  final int durationSeconds;

  const ExerciseStep({
    required this.description,
    required this.videoUrl,
    required this.durationSeconds,
  });

  factory ExerciseStep.fromMap(Map<String, dynamic> map) {
    return ExerciseStep(
      description: map['description'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      durationSeconds: map['durationSeconds'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'videoUrl': videoUrl,
        'durationSeconds': durationSeconds,
      };
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/models/exercise_step_model.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/models/exercise_step_model.dart
git commit -m "feat: add ExerciseStep model"
```

---

### Task 2: Update ExerciseModel

**Files:**
- Modify: `lib/models/exercise_model.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/exercise_step_model.dart';

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
  final List<ExerciseStep> steps;
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
    final rawSteps = map['steps'];
    List<ExerciseStep> parsedSteps = [];
    if (rawSteps is List) {
      parsedSteps = rawSteps.map((s) {
        if (s is Map<String, dynamic>) return ExerciseStep.fromMap(s);
        return ExerciseStep(
            description: s.toString(), videoUrl: '', durationSeconds: 30);
      }).toList();
    }
    return ExerciseModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      bodyArea: map['bodyArea'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'easy',
      duration: map['duration'] as int? ?? 0,
      videoUrl: map['videoUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      targetPainTypes: List<String>.from(map['targetPainTypes'] ?? []),
      steps: parsedSteps,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) =>
      ExerciseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'bodyArea': bodyArea,
        'difficulty': difficulty,
        'duration': duration,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'targetPainTypes': targetPainTypes,
        'steps': steps.map((s) => s.toMap()).toList(),
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

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
    List<ExerciseStep>? steps,
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
```

- [ ] **Step 2: Fix exercise_detail_screen.dart step display (line 170)**

```dart
// Old:
title: Text(exercise.steps[index]),
// New:
title: Text(exercise.steps[index].description),
```

- [ ] **Step 3: Fix admin_exercises_screen.dart step init (line 249)**

```dart
// Old:
_stepsCtrl = TextEditingController(
    text: e != null ? e.steps.join(', ') : '');
// New:
_stepsCtrl = TextEditingController(
    text: e != null ? e.steps.map((s) => s.description).join(', ') : '');
```

Fix the two `steps: steps` assignments in `_save()` (one for add, one for update) to build `List<ExerciseStep>`:

```dart
steps: _stepsCtrl.text
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .map((s) => ExerciseStep(description: s, videoUrl: '', durationSeconds: 30))
    .toList(),
```

Add import at top of admin_exercises_screen.dart:
```dart
import 'package:physiocare/models/exercise_step_model.dart';
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/models/exercise_model.dart lib/screens/exercises/exercise_detail_screen.dart lib/screens/admin/admin_exercises_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```
git add lib/models/exercise_model.dart lib/screens/exercises/exercise_detail_screen.dart lib/screens/admin/admin_exercises_screen.dart
git commit -m "feat: update ExerciseModel steps to List<ExerciseStep>"
```

---

### Task 3: Update SessionModel

**Files:**
- Modify: `lib/models/session_model.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseTitle;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final bool completed;
  final int stepsCompleted;
  final int totalSteps;
  final String status;
  final int? painLevel;
  final String? painNote;
  final double completionPercent;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.completed,
    this.stepsCompleted = 0,
    this.totalSteps = 0,
    this.status = 'in_progress',
    this.painLevel,
    this.painNote,
    this.completionPercent = 0.0,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseTitle: map['exerciseTitle'] as String? ?? '',
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
      stepsCompleted: map['stepsCompleted'] as int? ?? 0,
      totalSteps: map['totalSteps'] as int? ?? 0,
      status: map['status'] as String? ?? 'in_progress',
      painLevel: map['painLevel'] as int?,
      painNote: map['painNote'] as String?,
      completionPercent:
          (map['completionPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) =>
      SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'exerciseId': exerciseId,
        'exerciseTitle': exerciseTitle,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'durationSeconds': durationSeconds,
        'completed': completed,
        'stepsCompleted': stepsCompleted,
        'totalSteps': totalSteps,
        'status': status,
        'painLevel': painLevel,
        'painNote': painNote,
        'completionPercent': completionPercent,
      };

  SessionModel copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseTitle,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    bool? completed,
    int? stepsCompleted,
    int? totalSteps,
    String? status,
    int? painLevel,
    String? painNote,
    double? completionPercent,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      totalSteps: totalSteps ?? this.totalSteps,
      status: status ?? this.status,
      painLevel: painLevel ?? this.painLevel,
      painNote: painNote ?? this.painNote,
      completionPercent: completionPercent ?? this.completionPercent,
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/models/session_model.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/models/session_model.dart
git commit -m "feat: extend SessionModel with stepsCompleted, status, painLevel, completionPercent"
```

---

### Task 4: Update ProgressService and ProgressProvider

**Files:**
- Modify: `lib/services/progress_service.dart`
- Modify: `lib/providers/progress_provider.dart`

- [ ] **Step 1: Add stopSession and update completeSession in ProgressService**

Replace `completeSession` and add `stopSession` after it:

```dart
Future<void> completeSession(
    String sessionId, DateTime completedAt, int totalSteps) async {
  await _db.collection('sessions').doc(sessionId).update({
    'completed': true,
    'completedAt': Timestamp.fromDate(completedAt),
    'status': 'completed',
    'stepsCompleted': totalSteps,
    'totalSteps': totalSteps,
    'completionPercent': 100.0,
  });
}

Future<void> stopSession({
  required String sessionId,
  required int stepsCompleted,
  required int totalSteps,
  required int? painLevel,
  required String? painNote,
}) async {
  final pct = totalSteps > 0 ? stepsCompleted / totalSteps * 100.0 : 0.0;
  await _db.collection('sessions').doc(sessionId).update({
    'completed': false,
    'completedAt': Timestamp.fromDate(DateTime.now()),
    'status': 'stopped',
    'stepsCompleted': stepsCompleted,
    'totalSteps': totalSteps,
    'painLevel': painLevel,
    'painNote': painNote,
    'completionPercent': pct,
  });
}
```

- [ ] **Step 2: Update ProgressProvider**

Replace `completeSession` and add `stopSession`:

```dart
Future<void> completeSession(
    String sessionId, DateTime completedAt, int totalSteps) async {
  await _progressService.completeSession(sessionId, completedAt, totalSteps);
  final index = _sessions.indexWhere((s) => s.id == sessionId);
  if (index != -1) {
    _sessions[index] = _sessions[index].copyWith(
      completed: true,
      completedAt: completedAt,
      status: 'completed',
      stepsCompleted: totalSteps,
      totalSteps: totalSteps,
      completionPercent: 100.0,
    );
  }
  notifyListeners();
  if (_userId != null) {
    final ns = NotificationService();
    await ns.checkAndNotifyStreakMilestone(_userId!);
    await ns.cancelTodayStreakReminder();
  }
}

Future<void> stopSession({
  required String sessionId,
  required int stepsCompleted,
  required int totalSteps,
  required int? painLevel,
  required String? painNote,
}) async {
  await _progressService.stopSession(
    sessionId: sessionId,
    stepsCompleted: stepsCompleted,
    totalSteps: totalSteps,
    painLevel: painLevel,
    painNote: painNote,
  );
  notifyListeners();
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/services/progress_service.dart lib/providers/progress_provider.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```
git add lib/services/progress_service.dart lib/providers/progress_provider.dart
git commit -m "feat: add stopSession and update completeSession in ProgressService/Provider"
```

---

### Task 5: Add sessionComplete route + screen

**Files:**
- Modify: `lib/utils/app_constants.dart`
- Create: `lib/screens/exercises/session_complete_screen.dart`
- Modify: `lib/utils/app_router.dart`

- [ ] **Step 1: Add route constant in app_constants.dart**

Inside `AppRoutes`, add:
```dart
static const String sessionComplete = '/sessionComplete';
```

- [ ] **Step 2: Create SessionCompleteScreen**

Create `lib/screens/exercises/session_complete_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:physiocare/utils/app_constants.dart';

class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final stepsCompleted = args['stepsCompleted'] as int;
    final totalSteps = args['totalSteps'] as int;
    final elapsedSeconds = args['elapsedSeconds'] as int;
    final exerciseTitle = args['exerciseTitle'] as String;

    final m = elapsedSeconds ~/ 60;
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF00897B), size: 96),
              const SizedBox(height: 24),
              const Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _StatRow(
                  label: 'Steps completed',
                  value: '$stepsCompleted / $totalSteps'),
              const SizedBox(height: 12),
              _StatRow(label: 'Time taken', value: '${m}m ${s}s'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.exerciseLibrary,
                    (route) =>
                        route.settings.name == AppRoutes.dashboard,
                  ),
                  child: const Text('Back to Exercises',
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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Register route in app_router.dart**

Add import at top:
```dart
import 'package:physiocare/screens/exercises/session_complete_screen.dart';
```

Add case before `default`:
```dart
case AppRoutes.sessionComplete:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const SessionCompleteScreen(),
  );
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/utils/ lib/screens/exercises/session_complete_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```
git add lib/utils/app_constants.dart lib/utils/app_router.dart lib/screens/exercises/session_complete_screen.dart
git commit -m "feat: add sessionComplete route and SessionCompleteScreen"
```

---

### Task 6: Create PainStopDialog

**Files:**
- Create: `lib/widgets/pain_stop_dialog.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';

class PainStopResult {
  final bool shouldStop;
  final int? painLevel;
  final String? painNote;
  const PainStopResult(
      {required this.shouldStop, this.painLevel, this.painNote});
}

class PainStopDialog extends StatefulWidget {
  const PainStopDialog({super.key});

  @override
  State<PainStopDialog> createState() => _PainStopDialogState();
}

class _PainStopDialogState extends State<PainStopDialog> {
  double _painLevel = 5;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stop this session?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate your current pain level:'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('1'),
              Expanded(
                child: Slider(
                  value: _painLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF00897B),
                  label: _painLevel.round().toString(),
                  onChanged: (v) => setState(() => _painLevel = v),
                ),
              ),
              const Text('10'),
            ],
          ),
          Text('Pain level: ${_painLevel.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g. sharp pain in knee',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
              context, const PainStopResult(shouldStop: false)),
          child: const Text('Continue'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(
            context,
            PainStopResult(
              shouldStop: true,
              painLevel: _painLevel.round(),
              painNote: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
            ),
          ),
          child: const Text('Stop Session'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/widgets/pain_stop_dialog.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/widgets/pain_stop_dialog.dart
git commit -m "feat: add PainStopDialog widget"
```

---

### Task 7: Rewrite ExerciseSessionScreen

**Files:**
- Rewrite: `lib/screens/exercises/exercise_session_screen.dart`

- [ ] **Step 1: Replace the entire file**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/exercise_step_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/widgets/pain_stop_dialog.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() =>
      _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  late ExerciseModel _exercise;
  late String _sessionId;
  late DateTime _sessionStart;

  int _currentStepIndex = 0;
  bool _isPauseBetweenSteps = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitializing = false;
  bool _videoEnded = false;

  bool _argsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
      _exercise = args['exercise'] as ExerciseModel;
      _sessionId = args['sessionId'] as String;
      _sessionStart = DateTime.now();
      _argsInitialized = true;
      if (_exercise.steps.isNotEmpty) _loadStep(0);
    }
  }

  ExerciseStep get _currentStep => _exercise.steps[_currentStepIndex];

  Future<void> _loadStep(int index) async {
    _disposeVideo();
    setState(() {
      _videoInitializing = true;
      _videoEnded = false;
      _countdownSeconds = 0;
    });
    _countdownTimer?.cancel();

    final step = _exercise.steps[index];
    if (step.videoUrl.isNotEmpty) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(step.videoUrl));
        _videoController = controller;
        await controller.initialize();
        if (!mounted) return;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primaryDark,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: const Color(0xFFe0f2f1),
          ),
        );
        controller.addListener(_onVideoUpdate);
      } catch (_) {}
    }

    if (mounted) setState(() => _videoInitializing = false);
  }

  void _onVideoUpdate() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    if (!c.value.isPlaying &&
        c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration) {
      c.removeListener(_onVideoUpdate);
      if (!_videoEnded) {
        setState(() => _videoEnded = true);
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    if (_isPauseBetweenSteps) return;
    setState(() => _countdownSeconds = 3);
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        t.cancel();
        _advanceStep();
      }
    });
  }

  void _advanceStep() {
    _countdownTimer?.cancel();
    if (_currentStepIndex < _exercise.steps.length - 1) {
      setState(() => _currentStepIndex++);
      _loadStep(_currentStepIndex);
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    _countdownTimer?.cancel();
    _disposeVideo();
    final elapsed =
        DateTime.now().difference(_sessionStart).inSeconds;
    final total = _exercise.steps.length;
    await context
        .read<ProgressProvider>()
        .completeSession(_sessionId, DateTime.now(), total);
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sessionComplete,
        arguments: {
          'stepsCompleted': total,
          'totalSteps': total,
          'elapsedSeconds': elapsed,
          'exerciseTitle': _exercise.title,
        },
      );
    }
  }

  Future<void> _onPainPressed() async {
    _countdownTimer?.cancel();
    _videoController?.pause();

    final result = await showDialog<PainStopResult>(
      context: context,
      builder: (_) => const PainStopDialog(),
    );

    if (result == null || !result.shouldStop) {
      _videoController?.play();
      return;
    }

    await context.read<ProgressProvider>().stopSession(
          sessionId: _sessionId,
          stepsCompleted: _currentStepIndex,
          totalSteps: _exercise.steps.length,
          painLevel: result.painLevel,
          painNote: result.painNote,
        );

    if (mounted) Navigator.pop(context);
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsInitialized || _exercise.steps.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final total = _exercise.steps.length;
    final progress = ((_currentStepIndex + 1) / total).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              const Text('Pause between steps',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              Switch(
                value: _isPauseBetweenSteps,
                activeColor: Colors.white,
                onChanged: (v) =>
                    setState(() => _isPauseBetweenSteps = v),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPainPressed,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text("I'm in pain",
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Step ${_currentStepIndex + 1} of $total',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildVideoSection(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).round()}% complete',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentStep.description,
                      style:
                          const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),
                  if (_countdownSeconds > 0)
                    Center(
                      child: Text(
                        'Next step in $_countdownSeconds...',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  if (_isPauseBetweenSteps && _videoEnded)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        onPressed: _advanceStep,
                        child: Text(
                          _currentStepIndex < total - 1
                              ? 'Next Step'
                              : 'Finish',
                        ),
                      ),
                    ),
                  if (_currentStep.videoUrl.isEmpty && !_videoInitializing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        onPressed: _advanceStep,
                        child: Text(
                          _currentStepIndex < total - 1
                              ? 'Next Step'
                              : 'Finish',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_videoInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.primary,
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF004D40),
        child: const Center(
          child: Icon(Icons.videocam_off,
              color: Colors.white70, size: 48),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/screens/exercises/exercise_session_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/screens/exercises/exercise_session_screen.dart
git commit -m "feat: rewrite ExerciseSessionScreen with per-step video and pain stop"
```

---

### Task 8: Update ExerciseDetailScreen session creation

**Files:**
- Modify: `lib/screens/exercises/exercise_detail_screen.dart`

- [ ] **Step 1: Update the SessionModel construction**

Replace the `SessionModel(...)` block inside the "Start Exercise" `onPressed` (around lines 195–203):

```dart
final session = SessionModel(
  id: '',
  userId: userId,
  exerciseId: exercise.id,
  exerciseTitle: exercise.title,
  startedAt: DateTime.now(),
  durationSeconds: exercise.duration,
  completed: false,
  totalSteps: exercise.steps.length,
  stepsCompleted: 0,
  status: 'in_progress',
  completionPercent: 0.0,
);
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/screens/exercises/exercise_detail_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/screens/exercises/exercise_detail_screen.dart
git commit -m "feat: pass totalSteps and status when starting session"
```

---

### Task 9: Update AdminExercisesScreen step editor

**Files:**
- Modify: `lib/screens/admin/admin_exercises_screen.dart`

- [ ] **Step 1: Replace `_ExerciseFormSheetState` with per-step editor**

Replace the entire `_ExerciseFormSheetState` class (lines 223–509) with:

```dart
class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _thumbnailUrlCtrl;
  late final TextEditingController _durationCtrl;

  late String _bodyArea;
  late String _difficulty;
  late bool _isActive;

  final List<Map<String, TextEditingController>> _stepControllers = [];

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _videoUrlCtrl = TextEditingController(text: e?.videoUrl ?? '');
    _thumbnailUrlCtrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _durationCtrl =
        TextEditingController(text: e != null ? '${e.duration}' : '');
    _bodyArea = e?.bodyArea ?? widget.bodyAreas.first;
    _difficulty = e?.difficulty ?? widget.difficulties.first;
    _isActive = e?.isActive ?? true;

    if (e != null && e.steps.isNotEmpty) {
      for (final step in e.steps) {
        _stepControllers.add({
          'desc': TextEditingController(text: step.description),
          'video': TextEditingController(text: step.videoUrl),
          'dur': TextEditingController(text: '${step.durationSeconds}'),
        });
      }
    } else {
      _addStep();
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add({
        'desc': TextEditingController(),
        'video': TextEditingController(),
        'dur': TextEditingController(text: '30'),
      });
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      final ctrls = _stepControllers.removeAt(index);
      for (final c in ctrls.values) {
        c.dispose();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _durationCtrl.dispose();
    for (final ctrls in _stepControllers) {
      for (final c in ctrls.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final steps = _stepControllers
          .map((ctrls) => ExerciseStep(
                description: ctrls['desc']!.text.trim(),
                videoUrl: ctrls['video']!.text.trim(),
                durationSeconds:
                    int.tryParse(ctrls['dur']!.text.trim()) ?? 30,
              ))
          .where((s) => s.description.isNotEmpty)
          .toList();

      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
      final now = DateTime.now();

      if (widget.exercise == null) {
        final docRef =
            await FirebaseFirestore.instance.collection('exercises').add({});
        final newExercise = ExerciseModel(
          id: docRef.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bodyArea: _bodyArea,
          difficulty: _difficulty,
          duration: duration,
          videoUrl: _videoUrlCtrl.text.trim(),
          thumbnailUrl: _thumbnailUrlCtrl.text.trim(),
          targetPainTypes: const [],
          steps: steps,
          isActive: _isActive,
          createdAt: now,
        );
        await widget.exerciseService.addExercise(newExercise);
      } else {
        final updated = widget.exercise!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bodyArea: _bodyArea,
          difficulty: _difficulty,
          duration: duration,
          videoUrl: _videoUrlCtrl.text.trim(),
          thumbnailUrl: _thumbnailUrlCtrl.text.trim(),
          steps: steps,
          isActive: _isActive,
        );
        await widget.exerciseService.updateExercise(updated);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.exercise == null
                  ? 'Exercise added'
                  : 'Exercise updated')),
        );
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Edit Exercise' : 'Add Exercise',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoUrlCtrl,
                decoration: const InputDecoration(
                    labelText: 'Intro Video URL',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailUrlCtrl,
                decoration: const InputDecoration(
                    labelText: 'Thumbnail URL',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bodyArea,
                      decoration: const InputDecoration(
                          labelText: 'Body Area',
                          border: OutlineInputBorder()),
                      items: widget.bodyAreas
                          .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                  a[0].toUpperCase() + a.substring(1))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _bodyArea = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder()),
                      items: widget.difficulties
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                  d[0].toUpperCase() + d.substring(1))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _difficulty = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Total Duration (seconds)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Steps',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Step'),
                    onPressed: _addStep,
                  ),
                ],
              ),
              ..._stepControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrls = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Step ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                  size: 20),
                              onPressed: () => _removeStep(i),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrls['desc'],
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder()),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrls['video'],
                          decoration: const InputDecoration(
                            labelText: 'Cloudinary Video URL',
                            border: OutlineInputBorder(),
                            hintText: 'https://res.cloudinary.com/...',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrls['dur'],
                          decoration: const InputDecoration(
                              labelText: 'Duration (seconds)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text(
                    'Inactive exercises won\'t appear to users'),
                value: _isActive,
                activeThumbColor: Colors.teal,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEditing
                          ? 'Update Exercise'
                          : 'Add Exercise'),
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

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/screens/admin/admin_exercises_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/screens/admin/admin_exercises_screen.dart
git commit -m "feat: update admin step editor with per-step video URL and duration"
```

---

### Task 10: Update ExerciseSeeder

**Files:**
- Modify: `lib/utils/exercise_seeder.dart`

- [ ] **Step 1: Update the `ex()` helper inside `_exercises()`**

Find the `ex()` helper function inside `_exercises()`. Replace the `'steps': steps` line so steps are stored as maps:

```dart
Map<String, dynamic> ex({
  required String title,
  required String description,
  required String bodyArea,
  required String difficulty,
  required int duration,
  required String videoId,
  required List<String> targetPainTypes,
  required List<String> steps,
}) {
  final url = videoId.isNotEmpty ? _yt(videoId) : '';
  final thumb = videoId.isNotEmpty ? _thumb(videoId) : '';
  final stepDur = steps.isNotEmpty ? duration ~/ steps.length : 30;
  return {
    'title': title,
    'description': description,
    'bodyArea': bodyArea,
    'difficulty': difficulty,
    'duration': duration,
    'videoUrl': url,
    'thumbnailUrl': thumb,
    'targetPainTypes': targetPainTypes,
    'steps': steps
        .map((s) => {
              'description': s,
              'videoUrl': '',
              'durationSeconds': stepDur,
            })
        .toList(),
    'isActive': true,
    'createdAt': now,
  };
}
```

No changes to the individual exercise definitions — only the helper changes.

- [ ] **Step 2: Force re-seed**

In `seed()`, temporarily change the guard:
```dart
// Temporarily force re-seed (revert after seeding):
if (false) return;
```

Run app → Admin Dashboard → "Seed Sample Exercises". Then revert:
```dart
if (existing.docs.length >= 50) return;
```

First delete all documents in the Firestore `exercises` collection via Firebase Console before seeding.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/utils/exercise_seeder.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```
git add lib/utils/exercise_seeder.dart
git commit -m "feat: update seeder to write ExerciseStep map format with empty Cloudinary URLs"
```

---

### Task 11: Final build and smoke test

- [ ] **Step 1: Full analysis**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 2: Build**

Run: `flutter build apk --debug`
Expected: Build succeeded

- [ ] **Step 3: Smoke test**

1. Delete all Firestore `exercises` docs → re-seed from Admin Dashboard
2. Log in as patient → Exercise Library → pick any exercise → Exercise Detail
3. Steps list shows descriptions (not raw maps)
4. Tap "Start Exercise" → ExerciseSessionScreen opens at Step 1 of N
5. If step videoUrl is empty: dark placeholder shown, "Next Step" button appears immediately
6. If step videoUrl is a valid Cloudinary URL: video plays, auto-advances after ending
7. Toggle "Pause between steps" → "Next Step" button appears instead of countdown
8. Tap "I'm in pain" → PainStopDialog shows → rate pain → Stop Session → returns to exercise list
9. Complete all steps → SessionCompleteScreen shows correct step count and elapsed time
10. Admin → Manage Exercises → Edit an exercise → step editor shows description + video URL + duration fields per step

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "feat: complete exercise session redesign with per-step Cloudinary video and pain stop"
```
