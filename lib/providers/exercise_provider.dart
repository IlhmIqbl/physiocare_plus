import 'package:flutter/material.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/services/exercise_service.dart';

class ExerciseProvider extends ChangeNotifier {
  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;
  String? _selectedBodyArea;
  String? _selectedDifficulty;

  final _exerciseService = ExerciseService();

  List<ExerciseModel> get exercises {
    return _exercises.where((exercise) {
      final matchesBodyArea = _selectedBodyArea == null ||
          exercise.bodyArea == _selectedBodyArea;
      final matchesDifficulty = _selectedDifficulty == null ||
          exercise.difficulty == _selectedDifficulty;
      return matchesBodyArea && matchesDifficulty;
    }).toList();
  }

  List<ExerciseModel> get allExercises => List.unmodifiable(_exercises);
  bool get isLoading => _isLoading;
  String? get selectedBodyArea => _selectedBodyArea;
  String? get selectedDifficulty => _selectedDifficulty;

  Future<void> loadExercises() async {
    _isLoading = true;
    notifyListeners();

    try {
      _exercises = await _exerciseService.getAllExercises();
    } catch (_) {
      _exercises = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setBodyAreaFilter(String? bodyArea) {
    _selectedBodyArea = bodyArea;
    notifyListeners();
  }

  void setDifficultyFilter(String? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void clearFilters() {
    _selectedBodyArea = null;
    _selectedDifficulty = null;
    notifyListeners();
  }

  ExerciseModel? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
