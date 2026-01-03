import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Export appointment reminder functions
export {
  sendAppointmentReminders,
  cleanupOldNotifications,
  cancelRemindersOnAppointmentCancellation,
} from './appointmentReminders';

// Scheduled function: send pending reminders every 15 minutes.
export const sendReminders = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('UTC')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
      .collection('notifications')
      .where('sent', '==', false)
      .where('sendAt', '<=', now)
      .limit(300)
      .get();

    const batch = db.batch();

    for (const doc of snap.docs) {
      const data = doc.data();
      const receiverId = data.receiverId as string;
      const userDoc = await db.collection('users').doc(receiverId).get();
      const token = userDoc.get('fcmToken') as string | undefined;
      const enabled = userDoc.get('notificationsEnabled') !== false;

      if (token && enabled) {
        await admin.messaging().send({
          token,
          notification: {
            title: data.title ?? 'Rappel',
            body: data.body ?? '',
          },
          data: {
            appointmentId: data.appointmentId ?? '',
            receiverRole: data.receiverRole ?? '',
          },
        });
      }

      batch.update(doc.ref, {
        sent: true,
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }

    if (!snap.empty) {
      await batch.commit();
    }
    return null;
  });
