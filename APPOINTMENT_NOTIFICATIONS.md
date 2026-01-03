# Appointment Reminder Notification System

## Overview
Automated notification system to reduce missed appointments by sending timely reminders to patients and immediate notifications to doctors when appointments are booked.

## Features

### 1. **Doctor Notification on Booking**
- ✅ Instant notification sent to doctor when patient books appointment
- Includes: patient name, appointment time, consultation type (in-person/video)
- Notification appears in doctor's notifications page

### 2. **Patient Reminders**
- ✅ 1 hour before appointment
- ✅ 30 minutes before appointment
- Scheduled automatically when appointment is created
- Only sent if appointment time is in the future
- Includes: doctor name, appointment time

### 3. **Smart Reminder Management**
- Reminders automatically cancelled if appointment is cancelled
- Only sends reminders for confirmed appointments
- Cleans up old notifications after 30 days

## Architecture

### Flutter (Client Side)

#### **NotificationService** (`lib/shared/services/notification_service.dart`)

**Purpose**: Handle notification creation and management from the Flutter app

**Key Methods**:
- `sendDoctorAppointmentNotification()` - Send immediate notification to doctor
- `schedulePatientReminders()` - Create scheduled reminder documents in Firestore
- `cancelScheduledReminders()` - Remove reminders when appointment is cancelled
- `markAsRead()` - Mark notification as read

**Usage in Booking Flow**:
```dart
// In doctor_detail_page.dart _bookAppointment() method
final notificationService = NotificationService();

// 1. Send immediate notification to doctor
await notificationService.sendDoctorAppointmentNotification(
  doctorId: doctor.id,
  patientName: patientName,
  appointmentTime: selected.startTime,
  consultationType: 'in-person' or 'video',
);

// 2. Schedule patient reminders (1h and 30min)
await notificationService.schedulePatientReminders(
  patientId: user.uid,
  appointmentId: appointmentId,
  appointmentTime: selected.startTime,
  doctorName: doctor.fullName,
  consultationType: consultationType,
);
```

### Cloud Functions (Server Side)

#### **Appointment Reminders** (`functions/src/appointmentReminders.ts`)

**1. sendAppointmentReminders** (Scheduled Function)
- Runs every 10 minutes
- Queries notifications where:
  - `type == 'appointment_reminder'`
  - `sent == false`
  - `scheduledFor <= now`
- Validates appointment is still confirmed
- Marks reminders as sent
- Deletes reminders for cancelled appointments

**2. cleanupOldNotifications** (Scheduled Function)
- Runs daily at midnight UTC
- Removes notifications older than 30 days
- Keeps database clean and efficient

**3. cancelRemindersOnAppointmentCancellation** (Firestore Trigger)
- Triggered when appointment document is updated
- Detects status change to 'CANCELLED'
- Automatically removes unsent reminders
- Prevents sending reminders for cancelled appointments

## Firestore Data Structure

### Notifications Collection

#### Doctor Notification (Immediate)
```javascript
{
  recipientId: "doctor_uid",
  type: "new_appointment",
  title: "New Appointment Booked",
  message: "John Doe has booked a in-person appointment on Jan 15 at 14:30",
  createdAt: Timestamp,
  read: false,
  appointmentTime: Timestamp,
  patientName: "John Doe"
}
```

#### Patient Reminder (Scheduled)
```javascript
{
  recipientId: "patient_uid",
  type: "appointment_reminder",
  title: "Appointment Reminder",
  message: "Your appointment with Dr. Smith is in 1 hour at 14:30",
  createdAt: Timestamp,
  scheduledFor: Timestamp,  // When to send
  sent: false,               // Processed by Cloud Function
  read: false,
  appointmentId: "apt_123",
  appointmentTime: Timestamp,
  doctorName: "Dr. Smith",
  reminderType: "1_hour" or "30_minutes"
}
```

## Flow Diagram

### Booking Flow with Notifications
```
1. Patient selects time slot
   ↓
2. Appointment created in Firestore
   ↓
3. NotificationService.sendDoctorAppointmentNotification()
   → Creates notification document for doctor
   → Doctor sees in notifications page immediately
   ↓
4. NotificationService.schedulePatientReminders()
   → Creates 2 notification documents:
     - scheduledFor: appointmentTime - 1 hour
     - scheduledFor: appointmentTime - 30 minutes
   ↓
5. Cloud Function runs every 10 minutes
   → Checks for scheduledFor <= now
   → Validates appointment status == 'CONFIRMED'
   → Marks notification as sent: true
   → Patient sees in notifications page
```

### Cancellation Flow
```
1. Doctor/Patient cancels appointment
   ↓
2. Appointment status → 'CANCELLED'
   ↓
3. Firestore trigger detects change
   ↓
4. cancelRemindersOnAppointmentCancellation() runs
   → Deletes all unsent reminders for this appointment
   → Prevents sending reminders for cancelled appointments
```

## Deployment

### Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

This deploys:
- `sendAppointmentReminders` (runs every 10 minutes)
- `cleanupOldNotifications` (runs daily at midnight)
- `cancelRemindersOnAppointmentCancellation` (Firestore trigger)

### Test Locally
```bash
cd functions
npm run build
firebase emulators:start
```

## Testing Checklist

### Test 1: Doctor Receives Notification on Booking
1. Log in as patient
2. Find a doctor with available slots
3. Book an appointment
4. Log in as that doctor
5. ✅ Check notifications page - should see "New Appointment Booked"

### Test 2: Patient Receives 1-Hour Reminder
1. Create appointment 1 hour and 5 minutes in future
2. Wait for Cloud Function to run (every 10 minutes)
3. After 10 minutes, patient should see reminder notification

### Test 3: Patient Receives 30-Minute Reminder
1. Create appointment 35 minutes in future
2. Wait for Cloud Function to run
3. After next cycle, patient should see 30-min reminder

### Test 4: Reminders Cancelled When Appointment Cancelled
1. Create appointment
2. Check notifications collection - should have 2 reminders (sent: false)
3. Cancel appointment
4. Check notifications collection - reminders should be deleted

### Test 5: No Reminders for Past Appointments
1. Try to create appointment in the past (if possible)
2. Check notifications collection
3. Should not create any scheduled reminders

## Configuration

### Adjust Reminder Schedule
Edit `sendAppointmentReminders` in `functions/src/appointmentReminders.ts`:

```typescript
// Change from 10 minutes to 5 minutes
export const sendAppointmentReminders = functions.pubsub
  .schedule('every 5 minutes')  // <-- Change here
  .onRun(async (context) => {
    // ...
  });
```

### Change Reminder Times
Edit `schedulePatientReminders()` in `lib/shared/services/notification_service.dart`:

```dart
// Add 15-minute reminder
final fifteenMinsBefore = appointmentTime.subtract(const Duration(minutes: 15));
if (fifteenMinsBefore.isAfter(now)) {
  await _notificationsRef.add({
    // ... same structure as other reminders
    'reminderType': '15_minutes',
  });
}
```

### Change Notification Cleanup Period
Edit `cleanupOldNotifications` in `functions/src/appointmentReminders.ts`:

```typescript
// Change from 30 days to 60 days
const thirtyDaysAgo = new Date();
thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 60);  // <-- Change here
```

## Monitoring

### View Function Logs
```bash
firebase functions:log
```

### Check Specific Function
```bash
firebase functions:log --only sendAppointmentReminders
```

### Monitor in Firebase Console
1. Go to Firebase Console
2. Navigate to Functions section
3. View execution count, errors, and logs

## Troubleshooting

### Reminders Not Sending
1. Check Cloud Function is deployed: `firebase functions:list`
2. Check function logs: `firebase functions:log`
3. Verify notification documents have `sent: false` and `scheduledFor <= now`
4. Ensure appointment status is 'CONFIRMED'

### Doctor Not Getting Notification
1. Check notification document was created in Firestore
2. Verify `recipientId` matches doctor's uid
3. Check notifications page StreamBuilder is working

### Old Notifications Not Deleted
1. Verify `cleanupOldNotifications` function is deployed
2. Check it's running at midnight UTC
3. View logs to see deletion count

## Future Enhancements

- [ ] Add push notifications (FCM) in addition to in-app notifications
- [ ] SMS reminders for patients without app access
- [ ] Email notifications as backup
- [ ] Customizable reminder times per patient preference
- [ ] Notification preferences (enable/disable specific types)
- [ ] Multi-language support for notification messages
- [ ] Appointment confirmation reminders (24 hours before)

## Security Considerations

### Firestore Rules
Ensure users can only read their own notifications:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if request.auth.uid == resource.data.recipientId;
      
      // Users can update read status on their own notifications
      allow update: if request.auth.uid == resource.data.recipientId 
                     && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      
      // Only Cloud Functions can create/delete
      allow create, delete: if false;
    }
  }
}
```

## Performance

### Batch Operations
- Cloud Functions use batched writes (max 500 per batch)
- Efficient querying with composite indexes
- Cleanup runs during low-traffic hours (midnight)

### Firestore Costs
Per appointment booking:
- 1 write: doctor notification
- 2 writes: patient reminders (1h, 30min)
- 2 updates: marking reminders as sent
- **Total: 5 operations per appointment**

Cleanup operation:
- 1 read per 30-day-old notification
- 1 delete per old notification

## Files Modified

1. **Created**: `lib/shared/services/notification_service.dart`
   - Notification creation and management service

2. **Modified**: `lib/features/patient/pages/doctor_detail_page.dart`
   - Added import for NotificationService
   - Integrated notification calls in `_bookAppointment()` method

3. **Created**: `functions/src/appointmentReminders.ts`
   - Cloud Functions for scheduled reminders
   - Cleanup and cancellation logic

4. **Modified**: `functions/src/index.ts`
   - Exported new appointment reminder functions

## Summary

✅ **Implemented**: Complete automated notification system
✅ **Doctor Notifications**: Instant notification on booking
✅ **Patient Reminders**: Automated 1h and 30min reminders
✅ **Smart Cancellation**: Reminders auto-deleted when appointment cancelled
✅ **Cleanup**: Old notifications removed after 30 days
✅ **Production Ready**: Error handling, logging, and efficient batching
