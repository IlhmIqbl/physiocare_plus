import 'package:flutter/material.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<SessionModel> _sessions = [];
  List<ProgressModel> _progressEntries = [];
  int _streak = 0;
  bool _isLoading = false;

  final _progressService = ProgressService();

  List<SessionModel> get sessions => List.unmodifiable(_sessions);
  List<ProgressModel> get progressEntries =>
      List.unmodifiable(_progressEntries);
  int get streak => _streak;
  bool get isLoading => _isLoading;

  int get weeklySessionCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _sessions
        .where((s) => s.completed && s.startedAt.isAfter(cutoff))
        .length;
  }

  double get avgPainReduction {
    if (_progressEntries.isEmpty) return 0.0;
    final total = _progressEntries.fold<double>(
      0.0,
      (sum, p) => sum + (p.painLevelBefore - p.painLevelAfter),
    );
    return total / _progressEntries.length;
  }

  Future<void> loadUserProgress(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _progressService.getUserSessions(userId);
      _progressEntries = await _progressService.getUserProgress(userId);
      _streak = await _progressService.getSessionStreak(userId);
    } catch (_) {
      _sessions = [];
      _progressEntries = [];
      _streak = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> startSession(SessionModel session) async {
    final id = await _progressService.startSession(session);
    notifyListeners();
    return id;
  }

  Future<void> completeSession(String sessionId, DateTime completedAt) async {
    await _progressService.completeSession(sessionId, completedAt);
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(
        completed: true,
        completedAt: completedAt,
      );
    }
    notifyListeners();
  }

  Future<void> saveProgress(ProgressModel progress) async {
    await _progressService.saveProgress(progress);
    _progressEntries = [progress, ..._progressEntries];
    notifyListeners();
  }
}
