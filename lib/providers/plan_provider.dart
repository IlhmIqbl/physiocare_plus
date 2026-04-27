import 'package:flutter/material.dart';
import 'package:physiocare/models/recovery_plan_model.dart';
import 'package:physiocare/services/plan_service.dart';

class PlanProvider extends ChangeNotifier {
  RecoveryPlanModel? _activePlan;
  List<RecoveryPlanModel> _planHistory = [];
  bool _isLoading = false;

  final _planService = PlanService();

  RecoveryPlanModel? get activePlan => _activePlan;
  List<RecoveryPlanModel> get planHistory => List.unmodifiable(_planHistory);
  bool get isLoading => _isLoading;

  Future<void> loadUserPlans(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activePlan = await _planService.getActivePlan(userId);
      _planHistory = await _planService.getUserPlans(userId);
    } catch (_) {
      _activePlan = null;
      _planHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RecoveryPlanModel?> generatePlan(
      String userId, String bodyArea, int severity) async {
    _isLoading = true;
    notifyListeners();

    try {
      final plan = await _planService.generatePlan(userId, bodyArea, severity);
      _activePlan = plan;
      _planHistory = [plan, ..._planHistory];
      _isLoading = false;
      notifyListeners();
      return plan;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePlan(String planId) async {
    await _planService.deletePlan(planId);

    if (_activePlan?.id == planId) {
      _activePlan = null;
    }
    _planHistory = _planHistory.where((p) => p.id != planId).toList();
    notifyListeners();
  }
}
