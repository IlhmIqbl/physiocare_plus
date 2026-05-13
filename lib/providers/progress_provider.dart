import 'dart:async';
import 'package:flutter/material.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/services/progress_service.dart';
import 'package:physiocare/services/notification_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<SessionModel> _sessions = [];
  List<ProgressModel> _progressEntries = [];
  int _streak = 0;
  bool _isLoading = false;
  String? _userId;

  // Stream subscriptions — kept alive as long as the user is logged in.
  StreamSubscription<List<SessionModel>>? _sessionsSub;
  StreamSubscription<List<ProgressModel>>? _progressSub;
  bool _sessionsReady = false;
  bool _progressReady = false;

  final _progressService = ProgressService();

  List<SessionModel> get sessions => List.unmodifiable(_sessions);
  List<ProgressModel> get progressEntries =>
      List.unmodifiable(_progressEntries);
  int get streak => _streak;
  bool get isLoading => _isLoading;
  String? get userId => _userId;

  int get weeklySessionCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _sessions
        .where((s) => s.completed && s.startedAt.isAfter(cutoff))
        .length;
  }

  double get avgPainReduction {
    if (_progressEntries.isEmpty) return 0.0;
    final valid = _progressEntries
        .where((p) => p.painLevelBefore > 0 || p.painLevelAfter > 0)
        .toList();
    if (valid.isEmpty) return 0.0;
    final total = valid.fold<double>(
        0.0, (sum, p) => sum + (p.painLevelBefore - p.painLevelAfter));
    return total / valid.length;
  }

  // Subscribes to live Firestore streams for this user.
  // Safe to call multiple times — re-subscribes only when userId changes.
  Future<void> loadUserProgress(String userId) async {
    if (_userId == userId && _sessionsSub != null) return;

    _userId = userId;
    _isLoading = true;
    _sessionsReady = false;
    _progressReady = false;
    notifyListeners();

    await _sessionsSub?.cancel();
    await _progressSub?.cancel();

    _sessionsSub =
        _progressService.watchUserSessions(userId).listen((sessions) {
      _sessions = sessions;
      _recalculateStreak();
      if (!_sessionsReady) {
        _sessionsReady = true;
        if (_progressReady) _isLoading = false;
      }
      notifyListeners();
    }, onError: (_) {
      if (!_sessionsReady) {
        _sessionsReady = true;
        if (_progressReady) _isLoading = false;
        notifyListeners();
      }
    });

    _progressSub =
        _progressService.watchUserProgress(userId).listen((entries) {
      _progressEntries = entries;
      if (!_progressReady) {
        _progressReady = true;
        if (_sessionsReady) _isLoading = false;
      }
      notifyListeners();
    }, onError: (_) {
      if (!_progressReady) {
        _progressReady = true;
        if (_sessionsReady) _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Recalculates streak from in-memory session list — no extra network call.
  void _recalculateStreak() {
    final dates = <DateTime>{};
    for (final s in _sessions) {
      if (s.completed && s.completedAt != null) {
        final d = s.completedAt!;
        dates.add(DateTime(d.year, d.month, d.day));
      }
    }
    final today = DateTime.now();
    var check = DateTime(today.year, today.month, today.day);
    int streak = 0;
    while (dates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    _streak = streak;
  }

  // Cancels active subscriptions (call when the user logs out).
  Future<void> clearProgress() async {
    await _sessionsSub?.cancel();
    await _progressSub?.cancel();
    _sessionsSub = null;
    _progressSub = null;
    _sessions = [];
    _progressEntries = [];
    _streak = 0;
    _userId = null;
    _isLoading = false;
    _sessionsReady = false;
    _progressReady = false;
    notifyListeners();
  }

  Future<String> startSession(SessionModel session) async {
    final id = await _progressService.startSession(session);
    // Stream will pick up the new doc automatically.
    return id;
  }

  Future<void> completeSession(
      String sessionId, DateTime completedAt, int totalSteps,
      {int? painLevel, String? painNote}) async {
    await _progressService.completeSession(
        sessionId, completedAt, totalSteps,
        painLevel: painLevel, painNote: painNote);

    // Optimistic local update so the UI reacts immediately while the
    // Firestore stream delivers the confirmed update.
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions = List.of(_sessions);
      _sessions[index] = _sessions[index].copyWith(
        completed: true,
        completedAt: completedAt,
        status: 'completed',
        stepsCompleted: totalSteps,
        totalSteps: totalSteps,
        completionPercent: 100.0,
      );
      _recalculateStreak();
      notifyListeners();
    }

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
    // Stream will deliver the updated document automatically.
  }

  Future<void> saveProgress(ProgressModel progress) async {
    await _progressService.saveProgress(progress);
    // Optimistic local update; stream will confirm shortly.
    _progressEntries = [progress, ..._progressEntries];
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}
