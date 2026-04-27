import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/models/progress_model.dart';

class ProgressService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<String> startSession(SessionModel session) async {
    final docRef = _db.collection('sessions').doc(session.id.isEmpty
        ? null
        : session.id);

    if (session.id.isEmpty) {
      final ref = await _db.collection('sessions').add(session.toMap());
      return ref.id;
    }

    await docRef.set(session.toMap());
    return session.id;
  }

  Future<void> completeSession(String sessionId, DateTime completedAt) async {
    await _db.collection('sessions').doc(sessionId).update({
      'completed': true,
      'completedAt': Timestamp.fromDate(completedAt),
    });
  }

  Future<void> saveProgress(ProgressModel progress) async {
    await _db
        .collection('progress')
        .doc(progress.id.isEmpty ? null : progress.id)
        .set(progress.toMap());
  }

  Future<List<SessionModel>> getUserSessions(String userId) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SessionModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ProgressModel>> getUserProgress(String userId) async {
    final snapshot = await _db
        .collection('progress')
        .where('userId', isEqualTo: userId)
        .orderBy('recordedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ProgressModel.fromFirestore(doc))
        .toList();
  }

  Future<int> getSessionStreak(String userId) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // Collect unique dates with completed sessions
    final completedDates = <DateTime>{};
    for (final doc in snapshot.docs) {
      final session = SessionModel.fromFirestore(doc);
      if (session.completedAt != null) {
        final d = session.completedAt!;
        completedDates.add(DateTime(d.year, d.month, d.day));
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime check = todayDate;

    while (completedDates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
