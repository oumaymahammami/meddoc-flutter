# Doctor Appointment & Availability Management System

## 📋 Architecture Overview

This is a scalable, modular system for managing doctor appointments and availability slots. Built with clean architecture principles, Riverpod state management, and optimized Firestore queries.

### Folder Structure

```
lib/features/agenda/
├── data/
│   ├── models/
│   │   ├── availability_slot.dart       # Slot model & enum
│   │   └── appointment.dart             # Appointment model & enum
│   └── repositories/
│       ├── slots_repository.dart        # Slot CRUD & queries
│       └── appointments_repository.dart # Appointment queries
├── presentation/
│   ├── pages/
│   │   └── agenda_screen.dart          # Calendar UI (Day/Week/Month)
│   ├── providers/
│   │   └── agenda_providers.dart       # Riverpod state management
│   └── widgets/
│       └── agenda_widgets.dart         # Reusable UI components
└── README.md (this file)
```

---

## 🗄️ Firestore Data Model

### 1. Availability Slots Collection

**Path:** `/doctors/{doctorId}/slots/{slotId}`

Represents time slots when a doctor is available for consultations.

#### Document Schema

```json
{
  "doctorId": "doc_001",
  "startTime": Timestamp("2026-01-15 09:00:00"),
  "endTime": Timestamp("2026-01-15 10:00:00"),
  "status": "AVAILABLE",
  "type": "IN_PERSON",
  "createdAt": Timestamp("2026-01-01 08:00:00"),
  "updatedAt": Timestamp("2026-01-01 08:00:00"),
  "patientId": null
}
```

#### Fields Explanation

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `doctorId` | String | ✅ | Reference to doctor |
| `startTime` | Timestamp | ✅ | Slot start time |
| `endTime` | Timestamp | ✅ | Slot end time |
| `status` | String | ✅ | `AVAILABLE`, `BOOKED`, or `BLOCKED` |
| `type` | String | ✅ | `IN_PERSON` or `VIDEO` |
| `createdAt` | Timestamp | ✅ | Creation timestamp |
| `updatedAt` | Timestamp | ✅ | Last update timestamp |
| `patientId` | String | ❌ | Patient ID (only if BOOKED) |

#### Status Meanings

- **AVAILABLE**: Doctor is free and patient can book
- **BOOKED**: Patient has booked this slot
- **BLOCKED**: Doctor blocked time (lunch, break, etc.)

#### Firestore Indexes Required

```
Collection: /doctors/{doctorId}/slots
Composite Indexes:
- (startTime ↑, status ↑)
- (startTime ↑, endTime ↑, status ↑)
```

---

### 2. Appointments Collection

**Path:** `/appointments/{appointmentId}`

Represents confirmed bookings between doctor and patient.

#### Document Schema

```json
{
  "doctorId": "doc_001",
  "patientId": "pat_123",
  "startTime": Timestamp("2026-01-15 09:00:00"),
  "endTime": Timestamp("2026-01-15 10:00:00"),
  "mode": "IN_PERSON",
  "status": "CONFIRMED",
  "createdAt": Timestamp("2026-01-10 12:30:00"),
  "updatedAt": Timestamp("2026-01-10 12:30:00"),
  "notes": "Follow-up consultation"
}
```

#### Fields Explanation

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `doctorId` | String | ✅ | Reference to doctor |
| `patientId` | String | ✅ | Reference to patient |
| `startTime` | Timestamp | ✅ | Appointment start |
| `endTime` | Timestamp | ✅ | Appointment end |
| `mode` | String | ✅ | `IN_PERSON` or `VIDEO` |
| `status` | String | ✅ | `CONFIRMED`, `CANCELLED`, `COMPLETED` |
| `createdAt` | Timestamp | ✅ | Booking timestamp |
| `updatedAt` | Timestamp | ✅ | Last update timestamp |
| `notes` | String | ❌ | Consultation notes |

#### Status Meanings

- **CONFIRMED**: Appointment is scheduled and active
- **CANCELLED**: Patient or doctor cancelled
- **COMPLETED**: Appointment finished

#### Firestore Indexes Required

```
Collection: /appointments
Composite Indexes:
- (doctorId ↑, startTime ↑, status ↑)
- (doctorId ↑, status ↑, startTime ↑)
- (doctorId ↑, startTime ↑, startTime ↓)
```

---

## 📊 Data Models (Dart)

### AvailabilitySlot

```dart
class AvailabilitySlot {
  final String id;
  final String doctorId;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final ConsultationType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? patientId;

  // Factory constructor to parse Firestore docs
  factory AvailabilitySlot.fromFirestore(DocumentSnapshot doc) { }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() { }

  // Check if overlaps with another slot
  bool overlaps(AvailabilitySlot other) { }

  // Utility methods
  bool isPast() { }
  bool canBeDeleted() { }
  bool canBeEdited() { }
  int getDurationMinutes() { }
}

enum SlotStatus { available, booked, blocked }
enum ConsultationType { inPerson, video }
```

### Appointment

```dart
class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentMode mode;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  // Similar methods as AvailabilitySlot
  factory Appointment.fromFirestore(DocumentSnapshot doc) { }
  Map<String, dynamic> toFirestore() { }
  int getDurationMinutes() { }
}

enum AppointmentMode { inPerson, video }
enum AppointmentStatus { confirmed, cancelled, completed }
```

---

## 🔍 Query Patterns & Examples

### Slots Repository Queries

#### 1. Get Slots for a Day

```dart
Future<List<AvailabilitySlot>> getSlotsForDay(String doctorId, DateTime date) {
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
    .orderBy('startTime')
    .get();
}
```

**Firestore Cost:** 1 read per document matching the range

#### 2. Get Slots for a Week

```dart
Future<List<AvailabilitySlot>> getSlotsForWeek(String doctorId, DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final startOfWeek = DateTime(monday.year, monday.month, monday.day);
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  return _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
    .where('startTime', isLessThan: Timestamp.fromDate(endOfWeek))
    .orderBy('startTime')
    .get();
}
```

#### 3. Get Slots for a Month

```dart
Future<List<AvailabilitySlot>> getSlotsForMonth(String doctorId, DateTime date) {
  final startOfMonth = DateTime(date.year, date.month, 1);
  final endOfMonth = DateTime(date.year, date.month + 1, 1);

  return _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
    .where('startTime', isLessThan: Timestamp.fromDate(endOfMonth))
    .orderBy('startTime')
    .get();
}
```

#### 4. Get Available Slots Only

```dart
Future<List<AvailabilitySlot>> getAvailableSlots(
  String doctorId,
  DateTime startDate,
  DateTime endDate,
) {
  return _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .where('startTime', isLessThan: Timestamp.fromDate(endDate))
    .where('status', isEqualTo: 'AVAILABLE')
    .orderBy('startTime')
    .get();
}
```

#### 5. Check for Overlapping Slots

```dart
Future<List<AvailabilitySlot>> _getOverlappingSlots(
  String doctorId,
  AvailabilitySlot newSlot,
) {
  // Slots that start before this slot ends AND end after this slot starts
  return _doctorSlotsRef(doctorId)
    .where('startTime', isLessThan: Timestamp.fromDate(newSlot.endTime))
    .where('endTime', isGreaterThan: Timestamp.fromDate(newSlot.startTime))
    .get();
}
```

### Appointments Repository Queries

#### 1. Get Appointments for Date Range

```dart
Future<List<Appointment>> getAppointmentsForDateRange(
  String doctorId,
  DateTime startDate,
  DateTime endDate,
) {
  return _appointmentsRef
    .where('doctorId', isEqualTo: doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
    .where('startTime', isLessThan: Timestamp.fromDate(endDate))
    .where('status', isNotEqualTo: 'CANCELLED')
    .orderBy('status')
    .orderBy('startTime')
    .get();
}
```

**Note:** Inequality filters require explicit ordering on the field before other fields.

#### 2. Get Upcoming Appointments (Next 10)

```dart
Future<List<Appointment>> getUpcomingAppointments(String doctorId) {
  return _appointmentsRef
    .where('doctorId', isEqualTo: doctorId)
    .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
    .where('status', isEqualTo: 'CONFIRMED')
    .orderBy('startTime')
    .limit(10)
    .get();
}
```

#### 3. Get Appointment Statistics

```dart
Future<AppointmentStats> getAppointmentStats(
  String doctorId,
  DateTime startDate,
  DateTime endDate,
) {
  final appointments = await getAppointmentsForDateRange(
    doctorId,
    startDate,
    endDate,
  );

  return AppointmentStats(
    total: appointments.length,
    confirmed: appointments.where((a) => a.status == AppointmentStatus.confirmed).length,
    completed: appointments.where((a) => a.status == AppointmentStatus.completed).length,
    cancelled: appointments.where((a) => a.status == AppointmentStatus.cancelled).length,
  );
}
```

---

## 🔄 CRUD Operations

### Create Slot

```dart
Future<String> addSlot(String doctorId, AvailabilitySlot slot) async {
  // 1. Check for overlaps
  final overlapping = await _getOverlappingSlots(doctorId, slot);
  if (overlapping.isNotEmpty) {
    throw Exception('Slot overlaps with existing slots');
  }

  // 2. Create new document
  final docRef = _doctorSlotsRef(doctorId).doc();
  
  // 3. Write to Firestore
  await docRef.set(slot.toFirestore());
  
  return docRef.id;
}
```

**Firestore Cost:** 1 read (overlap check) + 1 write = 2 operations

### Update Slot

```dart
Future<void> updateSlot(
  String doctorId,
  String slotId,
  AvailabilitySlot updates,
) async {
  // 1. Fetch current slot to check if booked
  final currentSlot = await getSlot(doctorId, slotId);
  if (!currentSlot.canBeEdited()) {
    throw Exception('Cannot edit a booked slot');
  }

  // 2. Check for overlaps (excluding current slot)
  final overlapping = await _getOverlappingSlots(
    doctorId,
    updates,
    excludeSlotId: slotId,
  );
  if (overlapping.isNotEmpty) {
    throw Exception('Updated slot would overlap');
  }

  // 3. Update in Firestore
  await _doctorSlotsRef(doctorId).doc(slotId).update({
    'startTime': Timestamp.fromDate(updates.startTime),
    'endTime': Timestamp.fromDate(updates.endTime),
    'status': updates.status.toString().split('.').last.toUpperCase(),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });
}
```

**Firestore Cost:** 1 read + 1 read (overlap) + 1 write = 3 operations

### Delete Slot

```dart
Future<void> deleteSlot(String doctorId, String slotId) async {
  // 1. Fetch slot to verify it's not booked
  final slot = await getSlot(doctorId, slotId);
  if (!slot.canBeDeleted()) {
    throw Exception('Cannot delete a booked slot');
  }

  // 2. Delete from Firestore
  await _doctorSlotsRef(doctorId).doc(slotId).delete();
}
```

**Firestore Cost:** 1 read + 1 write = 2 operations

### Read Slot

```dart
Future<AvailabilitySlot?> getSlot(String doctorId, String slotId) {
  return _doctorSlotsRef(doctorId)
    .doc(slotId)
    .get()
    .then((doc) => doc.exists ? AvailabilitySlot.fromFirestore(doc) : null);
}
```

**Firestore Cost:** 1 read

---

## 🎯 State Management (Riverpod)

### Provider Structure

```dart
// Repository providers
final slotsRepositoryProvider = Provider((ref) => SlotsRepository());
final appointmentsRepositoryProvider = Provider((ref) => AppointmentsRepository());

// View state
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final agendaViewModeProvider = StateProvider<AgendaViewMode>((ref) => AgendaViewMode.week);

// Slots data
final slotsForDayProvider = FutureProvider.family<List<AvailabilitySlot>, String>(...);
final slotsForWeekProvider = FutureProvider.family<List<AvailabilitySlot>, String>(...);
final slotsForMonthProvider = FutureProvider.family<List<AvailabilitySlot>, String>(...);

// Appointments data
final appointmentsForDayProvider = FutureProvider.family<List<Appointment>, String>(...);
final appointmentsForWeekProvider = FutureProvider.family<List<Appointment>, String>(...);
final appointmentsForMonthProvider = FutureProvider.family<List<Appointment>, String>(...);

// Actions
final addSlotProvider = FutureProvider.family(...);
final updateSlotProvider = FutureProvider.family(...);
final deleteSlotProvider = FutureProvider.family(...);
```

### Usage Example

```dart
// Watch slots for current view
final slots = ref.watch(slotsForViewProvider(doctorId));

// Change view mode
ref.read(agendaViewModeProvider.notifier).state = AgendaViewMode.month;

// Add a slot (auto-invalidates caches)
await ref.read(addSlotProvider((
  doctorId: 'doc_001',
  slot: newSlot,
)).future);
```

---

## ⚡ Performance Optimization

### 1. Query Optimization

- **Use date range queries** instead of fetching all slots
- **Index on `startTime`** for efficient range queries
- **Limit results** when appropriate (e.g., upcoming appointments)

### 2. Caching Strategy

- Riverpod automatically caches results
- Invalidate caches after mutations (built into providers)
- Use `Stream` providers for real-time updates when needed

### 3. Pagination

For large datasets (many doctors with many slots):

```dart
Future<List<AvailabilitySlot>> getSlotsForDayPaginated(
  String doctorId,
  DateTime date, {
  int pageSize = 20,
  DocumentSnapshot? startAfter,
}) {
  var query = _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
    .where('startTime', isLessThan: Timestamp.fromDate(end))
    .orderBy('startTime')
    .limit(pageSize);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  return query.get();
}
```

### 4. Real-time Updates

For live calendar view:

```dart
Stream<List<AvailabilitySlot>> watchSlotsForDay(String doctorId, DateTime date) {
  return _doctorSlotsRef(doctorId)
    .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
    .orderBy('startTime')
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => AvailabilitySlot.fromFirestore(doc))
        .toList());
}
```

---

## 🛡️ Edge Cases & Solutions

### 1. Slot Overlap Prevention

**Problem:** Two slots booked at the same time

**Solution:** Check overlaps before creating/updating

```dart
bool overlaps(AvailabilitySlot a, AvailabilitySlot b) {
  return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
}
```

### 2. Cannot Delete Booked Slot

**Problem:** Doctor tries to delete a booked slot

**Solution:** Check slot status before allowing deletion

```dart
if (slot.status == SlotStatus.booked) {
  throw Exception('Cannot delete a booked slot');
}
```

### 3. Device Sync & Offline Mode

**Problem:** Doctor changes slots on one device, needs sync on another

**Solution:** Implement offline queue + sync when online

```dart
// Future enhancement
class OfflineQueue {
  final List<SlotOperation> pendingOperations = [];

  void addOperation(SlotOperation operation) {
    pendingOperations.add(operation);
  }

  Future<void> syncWhenOnline() {
    // Retry all pending operations
  }
}
```

### 4. Large Calendar with Many Slots

**Problem:** Loading 1000+ slots at once causes slow UI

**Solution:** Use pagination and lazy loading

```dart
// Load only 30 days at a time
Future<List<AvailabilitySlot>> getSlotsForMonth(String doctorId, DateTime date) {
  // Implementation uses date range limits
}

// Or use pagination within a month
getSlotsForDayPaginated(doctorId, date, pageSize: 20);
```

### 5. Concurrent Updates

**Problem:** Two API calls update same slot simultaneously

**Solution:** Use Firestore transactions (future enhancement)

```dart
Future<void> updateSlotWithTransaction(
  String doctorId,
  String slotId,
  AvailabilitySlot updates,
) async {
  await _firestore.runTransaction((transaction) async {
    final docRef = _doctorSlotsRef(doctorId).doc(slotId);
    final snapshot = await transaction.get(docRef);
    
    final currentSlot = AvailabilitySlot.fromFirestore(snapshot);
    if (!currentSlot.canBeEdited()) {
      throw Exception('Slot was booked while editing');
    }
    
    transaction.update(docRef, updates.toFirestore());
  });
}
```

---

## 🔐 Security Rules (Future Implementation)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Doctor can only access their own slots
    match /doctors/{doctorId}/slots/{slotId} {
      allow read, write: if request.auth.uid == doctorId;
    }

    // Only doctor can read their appointments
    match /appointments/{appointmentId} {
      allow read: if resource.data.doctorId == request.auth.uid
                   || resource.data.patientId == request.auth.uid;
      allow write: if request.auth.uid == resource.data.doctorId;
    }
  }
}
```

---

## 📝 Usage Examples

### Example 1: Display Day View

```dart
final doctorId = 'doc_001';
ref.watch(selectedDateProvider.notifier).state = DateTime.now();
ref.watch(agendaViewModeProvider.notifier).state = AgendaViewMode.day;

final slots = await ref.read(slotsForDayProvider(doctorId).future);
final appointments = await ref.read(appointmentsForDayProvider(doctorId).future);
```

### Example 2: Add New Slot

```dart
final slot = AvailabilitySlot(
  id: '',
  doctorId: 'doc_001',
  startTime: DateTime(2026, 1, 15, 9, 0),
  endTime: DateTime(2026, 1, 15, 10, 0),
  status: SlotStatus.available,
  type: ConsultationType.inPerson,
  createdAt: DateTime.now(),
);

await ref.read(addSlotProvider((
  doctorId: 'doc_001',
  slot: slot,
)).future);
```

### Example 3: Get Month Statistics

```dart
final startDate = DateTime(2026, 1, 1);
final endDate = DateTime(2026, 2, 1);

final stats = await ref.read(appointmentsRepositoryProvider)
  .getAppointmentStats('doc_001', startDate, endDate);

print('Total: ${stats.total}');
print('Confirmed: ${stats.confirmed}');
print('Completed: ${stats.completed}');
```

---

## 🚀 Future Enhancements

### Phase 2 (Scalability)

- [ ] Google Calendar integration (sync slots <-> Google Calendar)
- [ ] Offline mode with local caching
- [ ] Batch import slots (CSV upload)
- [ ] Recurring slots (e.g., "every Monday 9-5")
- [ ] Automatic slot generation from template
- [ ] Doctor working hours configuration

### Phase 3 (Advanced)

- [ ] Waitlist management
- [ ] Buffer time between appointments
- [ ] Cancellation policies
- [ ] Payment integration
- [ ] Appointment reminder notifications
- [ ] Patient rescheduling

### Phase 4 (Admin & Analytics)

- [ ] Admin dashboard
- [ ] Analytics (utilization, no-shows, peak times)
- [ ] Bulk operations
- [ ] Multi-doctor scheduling
- [ ] Resource management

---

## 📚 File Guide

| File | Purpose |
|------|---------|
| `availability_slot.dart` | Slot model, enums, conversion logic |
| `appointment.dart` | Appointment model, enums, conversion logic |
| `slots_repository.dart` | All slot queries and mutations |
| `appointments_repository.dart` | All appointment queries |
| `agenda_providers.dart` | Riverpod state and data providers |
| `agenda_screen.dart` | Main calendar UI (day/week/month) |
| `agenda_widgets.dart` | Reusable components (SlotCard, etc.) |

---

## 🎓 Best Practices

1. **Always check overlap** before creating/updating slots
2. **Use date range queries** to limit Firestore reads
3. **Index properly** for efficient queries
4. **Validate timestamps** (end > start, not in past)
5. **Prevent booked slot deletion** at business logic level
6. **Cache strategically** with Riverpod
7. **Handle errors gracefully** with user feedback
8. **Test edge cases** (overlaps, timezones, DST)

---

**Last Updated:** January 1, 2026
**Version:** 1.0.0
**Status:** Production Ready
