import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

export const onNewPlan = onDocumentCreated(
  'recovery_plans/{planId}',
  async (event) => {
    const planData = event.data?.data();
    if (!planData) return;

    const userId = planData['userId'] as string | undefined;
    if (!userId) return;

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData['fcmToken'] as string | undefined;
    const planUpdates = (userData['notificationPrefs'] as Record<string, unknown> | undefined)
      ?.planUpdates as boolean | undefined;

    if (!fcmToken || !planUpdates) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'New Recovery Plan Available',
        body: 'Your physiotherapist has created a new plan for you.',
      },
      data: { type: 'plan', route: '/recoveryPlan' },
    });
  }
);
