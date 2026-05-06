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
  late final _therapistService = TherapistService();
  final _notificationService = NotificationService();

  StreamSubscription<List<TherapistFeedbackModel>>? _feedbackSub;
  StreamSubscription<List<TherapistPlanModel>>? _planSub;

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
