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
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    _plansSub = _service.getTherapistPlans(patientId).listen(
      (plans) {
        _plans = plans;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> addSessionFeedback(TherapistFeedbackModel feedback) async {
    _isLoading = true;
    _error = null;
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
    _error = null;
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
    _error = null;
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
    _error = null;
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

  void reset() {
    _patientsSub?.cancel();
    _feedbackSub?.cancel();
    _plansSub?.cancel();
    _patientsSub = null;
    _feedbackSub = null;
    _plansSub = null;
    _patients = [];
    _selectedPatient = null;
    _feedback = [];
    _plans = [];
    _error = null;
    notifyListeners();
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
