import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

export const checkDailyStreak = onSchedule('every day 18:00', async () => {
  const usersSnap = await admin.firestore().collection('users').get();

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yStart = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate());
  const todayMidnight = new Date(yStart.getFullYear(), yStart.getMonth(), yStart.getDate() + 1);

  const sends: Promise<void>[] = [];

  for (const userDoc of usersSnap.docs) {
    const userData = userDoc.data();
    const fcmToken = userData['fcmToken'] as string | undefined;
    const streakAlerts = (userData['notificationPrefs'] as Record<string, unknown> | undefined)
      ?.streakAlerts as boolean | undefined;

    if (!fcmToken || !streakAlerts) continue;

    const sessionsSnap = await admin.firestore()
      .collection('sessions')
      .where('userId', '==', userDoc.id)
      .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(yStart))
      .where('completedAt', '<', admin.firestore.Timestamp.fromDate(todayMidnight))
      .limit(1)
      .get();

    // Only notify users who completed a session YESTERDAY (they have a streak to protect)
    if (!sessionsSnap.empty) {
      sends.push(
        admin.messaging()
          .send({
            token: fcmToken,
            notification: {
              title: "Don't break your streak!",
              body: 'Complete a session today to keep your recovery on track.',
            },
            data: { type: 'reminder', route: '/exerciseLibrary' },
          })
          .then(() => undefined)
          .catch(() => undefined)
      );
    }
  }

  await Promise.allSettled(sends);
});
