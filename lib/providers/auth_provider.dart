import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/services/auth_service.dart';
import 'package:physiocare/services/notification_service.dart';

class AppAuthProvider extends ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  final _authService = AuthService();

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _userModel != null;
  String get userType => _userModel?.userType ?? 'freemium';
  bool get isAdmin => _userModel?.userType == 'admin';

  Future<void> initialize() async {
    try {
      _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          _userModel = await _authService.getUserModel(user.uid);
          NotificationService().initFCM(user.uid).ignore();
        } else {
          _userModel = null;
        }
        notifyListeners();
      });
    } catch (_) {
      // Firebase not configured yet — app runs in demo mode
      notifyListeners();
    }
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
    await _authService.signOut();
    _userModel = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
