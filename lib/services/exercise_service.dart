import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/exercise_model.dart';

class ExerciseService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<ExerciseModel>> getAllExercises() async {
    final snapshot = await _db
        .collection('exercises')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => ExerciseModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ExerciseModel>> getExercisesByBodyArea(String bodyArea) async {
    final snapshot = await _db
        .collection('exercises')
        .where('isActive', isEqualTo: true)
        .where('bodyArea', isEqualTo: bodyArea)
        .get();
    return snapshot.docs
        .map((doc) => ExerciseModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ExerciseModel>> getExercisesByFilter({
    String? bodyArea,
    String? difficulty,
  }) async {
    Query query =
        _db.collection('exercises').where('isActive', isEqualTo: true);

    if (bodyArea != null) {
      query = query.where('bodyArea', isEqualTo: bodyArea);
    }
    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ExerciseModel.fromFirestore(doc))
        .toList();
  }

  Future<ExerciseModel?> getExerciseById(String id) async {
    final doc = await _db.collection('exercises').doc(id).get();
    if (!doc.exists) return null;
    return ExerciseModel.fromFirestore(doc);
  }

  Future<void> addExercise(ExerciseModel exercise) async {
    await _db
        .collection('exercises')
        .doc(exercise.id)
        .set(exercise.toMap());
  }

  Future<void> updateExercise(ExerciseModel exercise) async {
    await _db
        .collection('exercises')
        .doc(exercise.id)
        .update(exercise.toMap());
  }

  Future<void> deleteExercise(String id) async {
    await _db.collection('exercises').doc(id).update({'isActive': false});
  }
}
