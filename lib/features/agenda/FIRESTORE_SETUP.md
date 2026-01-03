# Firestore Setup Guide & Sample Data

## 🗄️ Collection Structure

```
Cloud Firestore Root
├── doctors/
│   ├── doc_001/
│   │   ├── (profile fields)
│   │   └── slots/
│   │       ├── slot_001
│   │       ├── slot_002
│   │       └── ...
│   └── doc_002/
│       └── slots/
│           └── ...
└── appointments/
    ├── apt_001
    ├── apt_002
    └── ...
```

---

## 📝 Sample Data

### 1. Availability Slots

#### Example 1: Available In-Person Slot

```json
{
  "docRef": "/doctors/doc_001/slots/slot_001",
  "data": {
    "doctorId": "doc_001",
    "startTime": Timestamp("2026-01-15 09:00:00"),
    "endTime": Timestamp("2026-01-15 10:00:00"),
    "status": "AVAILABLE",
    "type": "IN_PERSON",
    "createdAt": Timestamp("2026-01-01 08:00:00"),
    "updatedAt": Timestamp("2026-01-01 08:00:00"),
    "patientId": null
  }
}
```

#### Example 2: Booked Video Slot

```json
{
  "docRef": "/doctors/doc_001/slots/slot_002",
  "data": {
    "doctorId": "doc_001",
    "startTime": Timestamp("2026-01-15 10:00:00"),
    "endTime": Timestamp("2026-01-15 10:30:00"),
    "status": "BOOKED",
    "type": "VIDEO",
    "createdAt": Timestamp("2026-01-05 14:20:00"),
    "updatedAt": Timestamp("2026-01-05 14:20:00"),
    "patientId": "patient_123"
  }
}
```

#### Example 3: Blocked Slot (Lunch Break)

```json
{
  "docRef": "/doctors/doc_001/slots/slot_003",
  "data": {
    "doctorId": "doc_001",
    "startTime": Timestamp("2026-01-15 12:00:00"),
    "endTime": Timestamp("2026-01-15 13:00:00"),
    "status": "BLOCKED",
    "type": "IN_PERSON",
    "createdAt": Timestamp("2026-01-01 08:00:00"),
    "updatedAt": Timestamp("2026-01-01 08:00:00"),
    "patientId": null
  }
}
```

#### Example 4: Multiple Slots for a Day (Full Schedule)

```json
[
  {
    "docRef": "/doctors/doc_001/slots/slot_004",
    "data": {
      "doctorId": "doc_001",
      "startTime": Timestamp("2026-01-15 08:00:00"),
      "endTime": Timestamp("2026-01-15 09:00:00"),
      "status": "AVAILABLE",
      "type": "IN_PERSON",
      "createdAt": Timestamp("2026-01-01 08:00:00"),
      "updatedAt": Timestamp("2026-01-01 08:00:00"),
      "patientId": null
    }
  },
  {
    "docRef": "/doctors/doc_001/slots/slot_005",
    "data": {
      "doctorId": "doc_001",
      "startTime": Timestamp("2026-01-15 09:00:00"),
      "endTime": Timestamp("2026-01-15 10:00:00"),
      "status": "BOOKED",
      "type": "IN_PERSON",
      "createdAt": Timestamp("2026-01-05 10:00:00"),
      "updatedAt": Timestamp("2026-01-05 10:00:00"),
      "patientId": "patient_456"
    }
  },
  {
    "docRef": "/doctors/doc_001/slots/slot_006",
    "data": {
      "doctorId": "doc_001",
      "startTime": Timestamp("2026-01-15 10:00:00"),
      "endTime": Timestamp("2026-01-15 11:00:00"),
      "status": "AVAILABLE",
      "type": "IN_PERSON",
      "createdAt": Timestamp("2026-01-01 08:00:00"),
      "updatedAt": Timestamp("2026-01-01 08:00:00"),
      "patientId": null
    }
  },
  {
    "docRef": "/doctors/doc_001/slots/slot_007",
    "data": {
      "doctorId": "doc_001",
      "startTime": Timestamp("2026-01-15 11:00:00"),
      "endTime": Timestamp("2026-01-15 12:00:00"),
      "status": "AVAILABLE",
      "type": "VIDEO",
      "createdAt": Timestamp("2026-01-01 08:00:00"),
      "updatedAt": Timestamp("2026-01-01 08:00:00"),
      "patientId": null
    }
  }
]
```

---

### 2. Appointments

#### Example 1: Confirmed In-Person Appointment

```json
{
  "docRef": "/appointments/apt_001",
  "data": {
    "doctorId": "doc_001",
    "patientId": "patient_123",
    "startTime": Timestamp("2026-01-15 09:00:00"),
    "endTime": Timestamp("2026-01-15 10:00:00"),
    "mode": "IN_PERSON",
    "status": "CONFIRMED",
    "createdAt": Timestamp("2026-01-10 14:30:00"),
    "updatedAt": Timestamp("2026-01-10 14:30:00"),
    "notes": "First consultation"
  }
}
```

#### Example 2: Completed Appointment

```json
{
  "docRef": "/appointments/apt_002",
  "data": {
    "doctorId": "doc_001",
    "patientId": "patient_456",
    "startTime": Timestamp("2026-01-08 10:00:00"),
    "endTime": Timestamp("2026-01-08 11:00:00"),
    "mode": "VIDEO",
    "status": "COMPLETED",
    "createdAt": Timestamp("2026-01-05 09:15:00"),
    "updatedAt": Timestamp("2026-01-08 11:00:00"),
    "notes": "Follow-up, prescribed antibiotics"
  }
}
```

#### Example 3: Cancelled Appointment

```json
{
  "docRef": "/appointments/apt_003",
  "data": {
    "doctorId": "doc_001",
    "patientId": "patient_789",
    "startTime": Timestamp("2026-01-12 14:00:00"),
    "endTime": Timestamp("2026-01-12 14:30:00"),
    "mode": "IN_PERSON",
    "status": "CANCELLED",
    "createdAt": Timestamp("2026-01-07 10:00:00"),
    "updatedAt": Timestamp("2026-01-11 16:45:00"),
    "notes": "Patient requested cancellation"
  }
}
```

#### Example 4: Upcoming Week Appointments

```json
[
  {
    "docRef": "/appointments/apt_004",
    "data": {
      "doctorId": "doc_001",
      "patientId": "patient_111",
      "startTime": Timestamp("2026-01-16 08:30:00"),
      "endTime": Timestamp("2026-01-16 09:30:00"),
      "mode": "IN_PERSON",
      "status": "CONFIRMED",
      "createdAt": Timestamp("2026-01-14 11:20:00"),
      "updatedAt": Timestamp("2026-01-14 11:20:00"),
      "notes": "Routine checkup"
    }
  },
  {
    "docRef": "/appointments/apt_005",
    "data": {
      "doctorId": "doc_001",
      "patientId": "patient_222",
      "startTime": Timestamp("2026-01-16 14:00:00"),
      "endTime": Timestamp("2026-01-16 14:45:00"),
      "mode": "VIDEO",
      "status": "CONFIRMED",
      "createdAt": Timestamp("2026-01-12 09:00:00"),
      "updatedAt": Timestamp("2026-01-12 09:00:00"),
      "notes": "Consultation for lab results"
    }
  },
  {
    "docRef": "/appointments/apt_006",
    "data": {
      "doctorId": "doc_001",
      "patientId": "patient_333",
      "startTime": Timestamp("2026-01-17 10:30:00"),
      "endTime": Timestamp("2026-01-17 11:00:00"),
      "mode": "IN_PERSON",
      "status": "CONFIRMED",
      "createdAt": Timestamp("2026-01-13 15:45:00"),
      "updatedAt": Timestamp("2026-01-13 15:45:00"),
      "notes": "Initial consultation"
    }
  }
]
```

---

## 🔧 Firestore Index Configuration

### Required Composite Indexes

Create these indexes in Firestore Console: **Cloud Firestore** > **Indexes** > **Composite**

#### 1. Slots Collection Indexes

```
Collection: doctors/{doctorId}/slots

Index 1:
  Collection ID: slots
  Fields: startTime (Ascending), status (Ascending)
  Query scopes: Collection

Index 2:
  Collection ID: slots
  Fields: startTime (Ascending), endTime (Ascending), status (Ascending)
  Query scopes: Collection

Index 3:
  Collection ID: slots
  Fields: startTime (Descending)
  Query scopes: Collection
```

#### 2. Appointments Collection Indexes

```
Collection: appointments

Index 1:
  Collection ID: appointments
  Fields: doctorId (Ascending), startTime (Ascending), status (Ascending)
  Query scopes: Collection

Index 2:
  Collection ID: appointments
  Fields: doctorId (Ascending), status (Ascending), startTime (Ascending)
  Query scopes: Collection

Index 3:
  Collection ID: appointments
  Fields: doctorId (Ascending), startTime (Descending)
  Query scopes: Collection
```

### Quick Setup Script (Firebase CLI)

```bash
# Deploy indexes from firestore.indexes.json
firebase deploy --only firestore:indexes
```

**firestore.indexes.json:**

```json
{
  "indexes": [
    {
      "collectionGroup": "slots",
      "queryScope": "Collection",
      "fields": [
        {"fieldPath": "startTime", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "slots",
      "queryScope": "Collection",
      "fields": [
        {"fieldPath": "startTime", "order": "ASCENDING"},
        {"fieldPath": "endTime", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "appointments",
      "queryScope": "Collection",
      "fields": [
        {"fieldPath": "doctorId", "order": "ASCENDING"},
        {"fieldPath": "startTime", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "appointments",
      "queryScope": "Collection",
      "fields": [
        {"fieldPath": "doctorId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "startTime", "order": "ASCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 💰 Cost Estimation

### Read Operations

| Query | Cost |
|-------|------|
| Get slots for day (up to 50 slots) | 1 read |
| Get slots for week (up to 350 slots) | 1 read |
| Get slots for month (up to 1500 slots) | 1 read |
| Check overlaps (before creating slot) | 1 read |
| Get appointments for range | 1 read |

### Write Operations

| Operation | Cost |
|-----------|------|
| Add slot | 2 reads + 1 write = 3 ops |
| Update slot | 1 read + 1 read (overlap) + 1 write = 3 ops |
| Delete slot | 1 read + 1 write = 2 ops |
| Create appointment | 1 write = 1 op |

### Monthly Estimate (1 Doctor, 30 Days)

```
Assumptions:
- 50 slots per day
- 3 appointments per day
- Doctor checks calendar 10 times per day
- Updates 5 slots per week

Calculations:
- Calendar reads: 10 reads/day × 30 days × 1 = 300 reads
- Appointment reads: 3 reads/day × 30 days × 1 = 90 reads
- Add slots: 5/week × 4 weeks × 3 ops = 60 ops
- Update slots: 2/week × 4 weeks × 3 ops = 24 ops
- Delete slots: 1/week × 4 weeks × 2 ops = 8 ops
- Appointment creates: 3/day × 30 days × 1 = 90 writes

Total: ~572 reads + 182 writes = 754 operations
Cost: (754 / 100,000) × $0.06 = $0.00045 per month (negligible)
```

---

## 🔄 Data Migration Scripts

### Script 1: Create Sample Slots

```dart
Future<void> createSampleSlots(String doctorId) async {
  final slotsRepo = SlotsRepository();
  final baseDate = DateTime(2026, 1, 15);

  // Create slots for entire week
  for (int day = 0; day < 5; day++) {
    final date = baseDate.add(Duration(days: day));
    
    // Morning slots (9-12)
    for (int hour = 9; hour < 12; hour++) {
      final slot = AvailabilitySlot(
        id: '',
        doctorId: doctorId,
        startTime: DateTime(date.year, date.month, date.day, hour, 0),
        endTime: DateTime(date.year, date.month, date.day, hour + 1, 0),
        status: SlotStatus.available,
        type: ConsultationType.inPerson,
        createdAt: DateTime.now(),
      );
      await slotsRepo.addSlot(doctorId, slot);
    }

    // Lunch break
    await slotsRepo.addSlot(
      doctorId,
      AvailabilitySlot(
        id: '',
        doctorId: doctorId,
        startTime: DateTime(date.year, date.month, date.day, 12, 0),
        endTime: DateTime(date.year, date.month, date.day, 13, 0),
        status: SlotStatus.blocked,
        type: ConsultationType.inPerson,
        createdAt: DateTime.now(),
      ),
    );

    // Afternoon slots (14-17)
    for (int hour = 14; hour < 17; hour++) {
      final slot = AvailabilitySlot(
        id: '',
        doctorId: doctorId,
        startTime: DateTime(date.year, date.month, date.day, hour, 0),
        endTime: DateTime(date.year, date.month, date.day, hour + 1, 0),
        status: SlotStatus.available,
        type: hour == 16 ? ConsultationType.video : ConsultationType.inPerson,
        createdAt: DateTime.now(),
      );
      await slotsRepo.addSlot(doctorId, slot);
    }
  }
}
```

### Script 2: Create Sample Appointments

```dart
Future<void> createSampleAppointments(String doctorId) async {
  final firestore = FirebaseFirestore.instance;
  final baseDate = DateTime(2026, 1, 16);

  final appointments = [
    Appointment(
      id: 'apt_001',
      doctorId: doctorId,
      patientId: 'patient_001',
      startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0),
      endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0),
      mode: AppointmentMode.inPerson,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
      notes: 'Routine checkup',
    ),
    Appointment(
      id: 'apt_002',
      doctorId: doctorId,
      patientId: 'patient_002',
      startTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0),
      endTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 11, 0),
      mode: AppointmentMode.video,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
      notes: 'Follow-up consultation',
    ),
  ];

  for (final apt in appointments) {
    await firestore.collection('appointments').doc(apt.id).set(apt.toFirestore());
  }
}
```

---

## ✅ Data Validation Checklist

Before deploying to production:

- [ ] All timestamps use UTC (no timezone offsets)
- [ ] `endTime` > `startTime` for all slots/appointments
- [ ] No overlapping slots for same doctor
- [ ] Status enums are uppercase strings (AVAILABLE, BOOKED, etc.)
- [ ] Appointment references valid doctor and patient IDs
- [ ] No past slots or appointments
- [ ] All required fields are non-null
- [ ] Indexes are deployed
- [ ] Security rules are configured
- [ ] Backup is enabled

---

## 🔒 Backup & Restore

### Automated Backups

Enable in Firestore Console > **Backups**

```bash
# Manual backup via CLI
gcloud firestore backups create --retention-days=30
```

### Restore from Backup

```bash
# List backups
gcloud firestore backups list

# Restore to new database
gcloud firestore restore <BACKUP_ID> --destination-database=restored-db
```

---

**Last Updated:** January 1, 2026
**Version:** 1.0.0
