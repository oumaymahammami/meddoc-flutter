import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Client-side reminder activation service
/// This replaces Firebase Cloud Functions for free tier
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  /// Check for due reminders and mark them as sent
  /// Call this periodically while the app is running
  static Future<void> checkAndActivateReminders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('⏰ ReminderService: No user logged in');
      return;
    }

    try {
      final now = Timestamp.now();
      final nowDate = DateTime.now();
      print(
        '⏰ ReminderService: Checking for due reminders at ${nowDate.toString()}',
      );
      print('⏰ Current timestamp: ${now.toDate().toString()}');

      // First, check ALL reminders for this user to see what exists
      // Simplified query to avoid composite index requirement
      final allRemindersSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('type', isEqualTo: 'appointment_reminder')
          .get();

      print('⏰ Total reminders in DB: ${allRemindersSnapshot.docs.length}');

      for (final doc in allRemindersSnapshot.docs) {
        final data = doc.data();
        final scheduledFor = (data['scheduledFor'] as Timestamp?)?.toDate();
        final sent = data['sent'] as bool? ?? false;
        print(
          '  📋 Reminder: "${data['message']}" | Scheduled: $scheduledFor | Sent: $sent',
        );
      }

      // Filter in memory to find reminders that are due but not yet sent
      final dueReminders = allRemindersSnapshot.docs.where((doc) {
        final data = doc.data();
        final sent = data['sent'] as bool? ?? true;
        final scheduledFor = data['scheduledFor'] as Timestamp?;

        if (sent || scheduledFor == null) return false;

        // Check if scheduled time has passed
        return scheduledFor.toDate().isBefore(nowDate) ||
            scheduledFor.toDate().isAtSameMomentAs(nowDate);
      }).toList();

      print('⏰ ReminderService: Found ${dueReminders.length} due reminders');

      if (dueReminders.isEmpty) {
        return;
      }

      // Mark each reminder as sent
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in dueReminders) {
        final data = doc.data();
        print(
          '⏰ Activating reminder: ${data['message']} (scheduled: ${data['scheduledFor']})',
        );
        batch.update(doc.reference, {
          'sent': true,
          'sentAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Activated ${dueReminders.length} due reminders');
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }
}
