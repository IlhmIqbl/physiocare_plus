import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String scheduledTime;
  final List<int> daysOfWeek;
  final bool isActive;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.isActive,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      scheduledTime: map['scheduledTime'] as String,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      isActive: map['isActive'] as bool,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    return NotificationModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'scheduledTime': scheduledTime,
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? scheduledTime,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }
}
