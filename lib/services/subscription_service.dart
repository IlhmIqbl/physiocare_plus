import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/subscription_model.dart';

class SubscriptionService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<SubscriptionModel?> getSubscription(String userId) async {
    final doc = await _db.collection('subscriptions').doc(userId).get();
    if (!doc.exists) return null;
    return SubscriptionModel.fromFirestore(doc);
  }

  Future<void> upgradeToPremium(String userId) async {
    final now = DateTime.now();
    await _db.collection('subscriptions').doc(userId).update({
      'type': 'premium',
      'paymentStatus': 'active',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(
        DateTime(now.year + 1, now.month, now.day),
      ),
    });
  }

  Future<bool> isPremium(String userId) async {
    final subscription = await getSubscription(userId);
    if (subscription == null) return false;
    return subscription.type == 'premium' &&
        subscription.paymentStatus == 'active';
  }

  Stream<SubscriptionModel?> subscriptionStream(String userId) {
    return _db
        .collection('subscriptions')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SubscriptionModel.fromFirestore(doc);
    });
  }
}
