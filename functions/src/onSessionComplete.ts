import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { QueryDocumentSnapshot } from 'firebase-admin/firestore';

export const onSessionComplete = onDocumentWritten(
  'sessions/{sessionId}',
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // Only fire when completedAt transitions from null/missing → timestamp
    if (!after?.completedAt || before?.completedAt) return;

    const userId = after.userId as string | undefined;
    if (!userId) return;

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData['fcmToken'] as string | undefined;
    const streakAlerts = (userData['notificationPrefs'] as Record<string, unknown> | undefined)
      ?.streakAlerts as boolean | undefined;

    if (!fcmToken || !streakAlerts) return;

    const streak = await _calculateStreak(userId);

    if ([7, 14, 30].includes(streak)) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🔥 Streak Achievement!',
          body: `${streak}-day streak! You're crushing your recovery.`,
        },
        data: { type: 'streak', route: '/progress' },
      });
    }
  }
);

async function _calculateStreak(userId: string): Promise<number> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const snap = await admin.firestore()
    .collection('sessions')
    .where('userId', '==', userId)
    .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .orderBy('completedAt', 'desc')
    .get();

  if (snap.empty) return 0;

  const dates = snap.docs.map((d: QueryDocumentSnapshot) => {
    const ts = d.data()['completedAt'] as admin.firestore.Timestamp;
    const date = ts.toDate();
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  });

  const unique = [...new Set(dates)].sort((a, b) => b - a);

  let streak = 1;
  for (let i = 1; i < unique.length; i++) {
    const diffDays = (unique[i - 1] - unique[i]) / (1000 * 60 * 60 * 24);
    if (diffDays === 1) streak++;
    else break;
  }
  return streak;
}
