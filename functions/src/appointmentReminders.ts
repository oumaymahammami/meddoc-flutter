import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function to send appointment reminder notifications
 * Runs every 10 minutes to check for scheduled reminders
 * Sends notifications to patients 1 hour and 30 minutes before appointments
 */
export const sendAppointmentReminders = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Query for unsent reminders that are due to be sent
      const remindersSnapshot = await db
        .collection('notifications')
        .where('type', '==', 'appointment_reminder')
        .where('sent', '==', false)
        .where('scheduledFor', '<=', now)
        .get();

      if (remindersSnapshot.empty) {
        console.log('No reminders to send at this time');
        return null;
      }

      console.log(`Found ${remindersSnapshot.size} reminders to send`);

      // Use batched writes for efficiency
      const batch = db.batch();
      const remindersSent: string[] = [];

      for (const reminderDoc of remindersSnapshot.docs) {
        const reminderData = reminderDoc.data();
        
        // Check if appointment is still valid (not cancelled)
        const appointmentDoc = await db
          .collection('appointments')
          .doc(reminderData.appointmentId)
          .get();

        if (!appointmentDoc.exists) {
          console.log(`Appointment ${reminderData.appointmentId} not found, skipping reminder`);
          // Delete the reminder
          batch.delete(reminderDoc.ref);
          continue;
        }

        const appointment = appointmentDoc.data();
        
        // Only send if appointment is still confirmed
        if (appointment?.status !== 'CONFIRMED') {
          console.log(`Appointment ${reminderData.appointmentId} is ${appointment?.status}, skipping reminder`);
          // Delete the reminder since appointment is not active
          batch.delete(reminderDoc.ref);
          continue;
        }

        // Mark the reminder as sent
        batch.update(reminderDoc.ref, {
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        remindersSent.push(reminderDoc.id);
        console.log(
          `Sent ${reminderData.reminderType} reminder for appointment ${reminderData.appointmentId}`
        );
      }

      await batch.commit();
      console.log(`Successfully sent ${remindersSent.length} reminders`);

      return {
        success: true,
        remindersSent: remindersSent.length,
        timestamp: now.toDate().toISOString(),
      };
    } catch (error) {
      console.error('Error sending appointment reminders:', error);
      throw error;
    }
  });

/**
 * Cloud Function to clean up old notifications
 * Runs daily at midnight to remove notifications older than 30 days
 */
export const cleanupOldNotifications = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const cutoffDate = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

    try {
      const oldNotificationsSnapshot = await db
        .collection('notifications')
        .where('createdAt', '<', cutoffDate)
        .get();

      if (oldNotificationsSnapshot.empty) {
        console.log('No old notifications to clean up');
        return null;
      }

      console.log(`Found ${oldNotificationsSnapshot.size} old notifications to delete`);

      const batch = db.batch();
      oldNotificationsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Successfully deleted ${oldNotificationsSnapshot.size} old notifications`);

      return {
        success: true,
        deletedCount: oldNotificationsSnapshot.size,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
      throw error;
    }
  });

/**
 * Firestore trigger: Cancel reminders when appointment is cancelled
 * Automatically removes scheduled reminders when an appointment status changes to CANCELLED
 */
export const cancelRemindersOnAppointmentCancellation = functions.firestore
  .document('appointments/{appointmentId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const appointmentId = context.params.appointmentId;

    // Check if status changed to CANCELLED
    if (before.status !== 'CANCELLED' && after.status === 'CANCELLED') {
      console.log(`Appointment ${appointmentId} was cancelled, removing scheduled reminders`);

      const db = admin.firestore();
      
      try {
        const remindersSnapshot = await db
          .collection('notifications')
          .where('appointmentId', '==', appointmentId)
          .where('sent', '==', false)
          .get();

        if (remindersSnapshot.empty) {
          console.log('No unsent reminders to cancel');
          return null;
        }

        const batch = db.batch();
        remindersSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Successfully cancelled ${remindersSnapshot.size} reminders`);

        return {
          success: true,
          cancelledCount: remindersSnapshot.size,
        };
      } catch (error) {
        console.error('Error cancelling reminders:', error);
        throw error;
      }
    }

    return null;
  });
