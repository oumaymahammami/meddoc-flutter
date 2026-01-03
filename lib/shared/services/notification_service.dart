import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing appointment notifications
/// Handles sending notifications to doctors and patients
class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  /// Send notification to doctor when patient books an appointment
  /// Called immediately after appointment creation
  Future<void> sendDoctorAppointmentNotification({
    required String doctorId,
    required String patientName,
    required DateTime appointmentTime,
    required String consultationType,
  }) async {
    try {
      await _notificationsRef.add({
        'recipientId': doctorId,
        'type': 'new_appointment',
        'title': 'New Appointment Booked',
        'message':
            '$patientName has booked a $consultationType appointment on ${_formatDateTime(appointmentTime)}',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'appointmentTime': Timestamp.fromDate(appointmentTime),
        'patientName': patientName,
      });
    } catch (e) {
      print('Error sending doctor notification: $e');
      rethrow;
    }
  }

  /// Create reminder notification documents for patient
  /// These will be picked up by Cloud Functions and sent at appropriate times
  Future<void> schedulePatientReminders({
    required String patientId,
    required String appointmentId,
    required DateTime appointmentTime,
    required String doctorName,
    required String consultationType,
  }) async {
    try {
      // Calculate reminder times
      final oneHourBefore = appointmentTime.subtract(const Duration(hours: 1));
      final thirtyMinsBefore = appointmentTime.subtract(
        const Duration(minutes: 30),
      );

      // Only schedule if the reminder time is in the future
      final now = DateTime.now();

      // Schedule 1 hour reminder
      if (oneHourBefore.isAfter(now)) {
        await _notificationsRef.add({
          'recipientId': patientId,
          'type': 'appointment_reminder',
          'title': 'Appointment Reminder',
          'message':
              'Your appointment with Dr. $doctorName is in 1 hour at ${_formatTime(appointmentTime)}',
          'createdAt': FieldValue.serverTimestamp(),
          'scheduledFor': Timestamp.fromDate(oneHourBefore),
          'read': false,
          'sent': false,
          'appointmentId': appointmentId,
          'appointmentTime': Timestamp.fromDate(appointmentTime),
          'doctorName': doctorName,
          'reminderType': '1_hour',
        });
      }

      // Schedule 30 minutes reminder
      if (thirtyMinsBefore.isAfter(now)) {
        await _notificationsRef.add({
          'recipientId': patientId,
          'type': 'appointment_reminder',
          'title': 'Appointment Reminder',
          'message':
              'Your appointment with Dr. $doctorName is in 30 minutes at ${_formatTime(appointmentTime)}',
          'createdAt': FieldValue.serverTimestamp(),
          'scheduledFor': Timestamp.fromDate(thirtyMinsBefore),
          'read': false,
          'sent': false,
          'appointmentId': appointmentId,
          'appointmentTime': Timestamp.fromDate(appointmentTime),
          'doctorName': doctorName,
          'reminderType': '30_minutes',
        });
      }
    } catch (e) {
      print('Error scheduling patient reminders: $e');
      rethrow;
    }
  }

  /// Cancel scheduled reminders for an appointment (e.g., when appointment is cancelled)
  Future<void> cancelScheduledReminders(String appointmentId) async {
    try {
      final reminders = await _notificationsRef
          .where('appointmentId', isEqualTo: appointmentId)
          .where('sent', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in reminders.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error cancelling reminders: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month $day at $hour:$minute';
  }

  /// Format time only
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
