import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  static StreamSubscription<RemoteMessage>? _fcmSubscription;

  Future<void> initialize() async {
    if (kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }

  Future<void> scheduleReminder(NotificationModel reminder) async {
    if (kIsWeb) return;
    for (int i = 0; i < reminder.daysOfWeek.length; i++) {
      final notifId = reminder.id.hashCode + i;
      await _plugin.periodicallyShow(
        notifId,
        'PhysioCare+',
        reminder.title,
        RepeatInterval.weekly,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'physiocare_reminders',
            'Exercise Reminders',
            channelDescription: 'Reminders to complete your exercises',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(reminderId.hashCode + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> saveReminder(NotificationModel reminder, String userId) async {
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminder.id)
        .set(reminder.toMap());
  }

  Future<List<NotificationModel>> getUserReminders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  Future<void> toggleReminder(
      String reminderId, bool isActive, String userId) async {
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .update({'isActive': isActive});

    if (isActive) {
      final doc = await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .get();
      if (doc.exists) {
        await scheduleReminder(NotificationModel.fromFirestore(doc));
      }
    } else {
      await cancelReminder(reminderId);
    }
  }

  Future<void> initFCM(String userId) async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    await _fcmSubscription?.cancel();
    _fcmSubscription = FirebaseMessaging.onMessage.listen(handleForegroundMessage);
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'physiocare_fcm',
          'PhysioCare Notifications',
          channelDescription: 'Push notifications from PhysioCare+',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextReminderTime({int addDays = 0}) {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + addDays, 18, 0, 0);
    if (addDays == 0 && target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }
}
