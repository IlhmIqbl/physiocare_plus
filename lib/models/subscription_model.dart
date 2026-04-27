import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String type;
  final DateTime startDate;
  final DateTime? endDate;
  final String paymentStatus;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.paymentStatus,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] as String,
      type: map['type'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      paymentStatus: map['paymentStatus'] as String,
    );
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    return SubscriptionModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'paymentStatus': paymentStatus,
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentStatus,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
