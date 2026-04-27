import 'dart:async';
import 'package:flutter/material.dart';
import 'package:physiocare/models/subscription_model.dart';
import 'package:physiocare/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _subscription;
  bool _isLoading = false;
  StreamSubscription<SubscriptionModel?>? _streamSubscription;

  final _subscriptionService = SubscriptionService();

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;

  bool get isPremium =>
      _subscription != null &&
      _subscription!.type == 'premium' &&
      _subscription!.paymentStatus == 'active';

  bool get isFree => !isPremium;

  Future<void> loadSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = await _subscriptionService.getSubscription(userId);
    } catch (_) {
      _subscription = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradeToPremium(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _subscriptionService.upgradeToPremium(userId);
      await loadSubscription(userId);
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToSubscription(String userId) {
    _streamSubscription?.cancel();
    _streamSubscription =
        _subscriptionService.subscriptionStream(userId).listen(
      (sub) {
        _subscription = sub;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
