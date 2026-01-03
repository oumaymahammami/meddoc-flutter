# Doctor Agenda System - Integration Guide

## 🚀 Quick Start

### 1. Add Riverpod Dependency

Ensure `pubspec.yaml` has flutter_riverpod:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  cloud_firestore: ^4.13.0
  intl: ^0.19.0
```

### 2. Wrap App with Riverpod

Update `main.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 3. Add Route to Navigation

Update `router.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'features/agenda/presentation/pages/agenda_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/doctor/agenda',
      name: 'agenda',
      builder: (context, state) {
        final doctorId = state.pathParameters['doctorId'] ?? 'doc_001';
        return AgendaScreen(doctorId: doctorId);
      },
    ),
    // ... other routes
  ],
);
```

### 4. Navigate to Agenda Screen

```dart
// From anywhere in your app
context.go('/doctor/agenda?doctorId=doc_001');

// Or with named route
context.go('/doctor/agenda');
```

---

## 📱 Screen Integration

### Add Agenda Tab in Doctor Dashboard

```dart
// In doctor_dashboard_screen.dart

Widget _buildAgendaTab(BuildContext context) {
  return Tab(
    icon: const Icon(Icons.calendar_month),
    text: 'Agenda',
  );
}

// In TabBarView
TabBarView(
  children: [
    // ... other tabs
    AgendaScreen(doctorId: currentDoctorId),
  ],
)
```

### Add Quick Link to Dashboard

```dart
// In doctor_dashboard_screen.dart

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    leading: const Icon(Icons.calendar_today, color: Colors.blue),
    title: const Text('Manage Availability'),
    subtitle: const Text('Add or edit your time slots'),
    trailing: const Icon(Icons.arrow_forward),
    onTap: () => context.go('/doctor/agenda'),
  ),
)
```

---

## 🔌 Usage Patterns

### Pattern 1: Watch Slots for Current Week

```dart
ConsumerWidget(
  builder: (context, ref, child) {
    final doctorId = 'doc_001';
    final slotsAsync = ref.watch(slotsForWeekProvider(doctorId));

    return slotsAsync.when(
      data: (slots) => ListView(
        children: slots.map((slot) => SlotCard(slot: slot)).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)
```

### Pattern 2: Add Slot with Error Handling

```dart
Future<void> addNewSlot(WidgetRef ref, String doctorId) async {
  try {
    final slot = AvailabilitySlot(
      id: '',
      doctorId: doctorId,
      startTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
      status: SlotStatus.available,
      type: ConsultationType.inPerson,
      createdAt: DateTime.now(),
    );

    final slotId = await ref.read(addSlotProvider(
      (doctorId: doctorId, slot: slot),
    ).future);

    // Show success
    print('Slot added: $slotId');
  } catch (e) {
    // Handle error
    print('Failed to add slot: $e');
    // Show error message to user
  }
}
```

### Pattern 3: Real-time Calendar Updates

```dart
ConsumerWidget(
  builder: (context, ref, child) {
    final doctorId = 'doc_001';
    final selectedDate = ref.watch(selectedDateProvider);
    
    // Use Stream provider for real-time updates
    final slotsStream = ref.watch(watchSlotsForDayProvider(doctorId));

    return slotsStream.when(
      data: (slots) {
        // Auto-rebuilds when slots change
        return _buildCalendarWithSlots(slots);
      },
      loading: () => const Loader(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  },
)
```

### Pattern 4: Combined Slots + Appointments View

```dart
ConsumerWidget(
  builder: (context, ref, child) {
    final doctorId = 'doc_001';
    final eventsAsync = ref.watch(calendarEventsProvider(doctorId));

    return eventsAsync.when(
      data: (events) {
        // events is List<CalendarEvent>
        final slots = events.where((e) => e.type == EventType.slot).toList();
        final appointments = events.where((e) => e.type == EventType.appointment).toList();

        return Column(
          children: [
            _buildSlotsSection(slots),
            _buildAppointmentsSection(appointments),
          ],
        );
      },
      loading: () => const LoadingPlaceholder(),
      error: (err, stack) => const ErrorPlaceholder(),
    );
  },
)
```

### Pattern 5: Date Navigation

```dart
// Change selected date
ref.read(selectedDateProvider.notifier).state = newDate;

// Change view mode
ref.read(agendaViewModeProvider.notifier).state = AgendaViewMode.month;

// Watch changes
final selectedDate = ref.watch(selectedDateProvider);
final viewMode = ref.watch(agendaViewModeProvider);
```

---

## 🧪 Testing

### Unit Tests for Repository

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('SlotsRepository', () {
    late SlotsRepository repository;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      repository = SlotsRepository(firestore: mockFirestore);
    });

    test('addSlot should create slot and return ID', () async {
      // Arrange
      final slot = AvailabilitySlot(
        id: '',
        doctorId: 'doc_001',
        startTime: DateTime(2026, 1, 15, 9, 0),
        endTime: DateTime(2026, 1, 15, 10, 0),
        status: SlotStatus.available,
        type: ConsultationType.inPerson,
        createdAt: DateTime.now(),
      );

      // Act
      final slotId = await repository.addSlot('doc_001', slot);

      // Assert
      expect(slotId, isNotEmpty);
    });

    test('addSlot should throw when overlapping with existing slot', () async {
      // Arrange
      final existingSlot = AvailabilitySlot(
        id: 'existing',
        doctorId: 'doc_001',
        startTime: DateTime(2026, 1, 15, 9, 0),
        endTime: DateTime(2026, 1, 15, 10, 0),
        status: SlotStatus.available,
        type: ConsultationType.inPerson,
        createdAt: DateTime.now(),
      );

      final newSlot = AvailabilitySlot(
        id: '',
        doctorId: 'doc_001',
        startTime: DateTime(2026, 1, 15, 9, 30),
        endTime: DateTime(2026, 1, 15, 10, 30),
        status: SlotStatus.available,
        type: ConsultationType.inPerson,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => repository.addSlot('doc_001', newSlot),
        throwsException,
      );
    });
  });
}
```

### Widget Tests for AgendaScreen

```dart
void main() {
  group('AgendaScreen', () {
    testWidgets('displays day/week/month tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AgendaScreen(doctorId: 'doc_001'),
          ),
        ),
      );

      // Verify tabs exist
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('can change between view modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AgendaScreen(doctorId: 'doc_001'),
          ),
        ),
      );

      // Tap week button
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // Verify UI updates
      expect(find.byType(AgendaScreen), findsOneWidget);
    });
  });
}
```

---

## 🔗 Integration Checklist

### Pre-Launch

- [ ] Firestore indexes created
- [ ] Sample data added to Firestore
- [ ] AgendaScreen properly routed
- [ ] Tests passing
- [ ] Error handling implemented
- [ ] Loading states visible
- [ ] Empty states handled
- [ ] Offline mode tested (if applicable)
- [ ] Permissions configured
- [ ] Doctor ID passed correctly

### Production Deployment

- [ ] Security rules enabled
- [ ] Backups configured
- [ ] Monitoring enabled
- [ ] Analytics integrated
- [ ] Error tracking (Sentry) configured
- [ ] Performance tested with real data
- [ ] Mobile and web versions tested
- [ ] Accessibility reviewed
- [ ] User documentation complete

---

## 🐛 Troubleshooting

### Issue: "No matching index" Firestore error

**Solution:** Create composite index as described in FIRESTORE_SETUP.md

```bash
firebase deploy --only firestore:indexes
```

### Issue: Empty calendar despite slots in Firestore

**Solution:** Check doctorId parameter matches Firestore data

```dart
// Verify doctor ID
print('Current doctor: $doctorId');

// Check Firestore data
final doc = await FirebaseFirestore.instance
  .collection('doctors')
  .doc(doctorId)
  .collection('slots')
  .limit(1)
  .get();
print('Slots found: ${doc.docs.length}');
```

### Issue: Slots show but appointments don't

**Solution:** Appointments are at root level, verify doctorId filter

```dart
// Debug appointments query
final apts = await FirebaseFirestore.instance
  .collection('appointments')
  .where('doctorId', isEqualTo: doctorId)
  .get();
print('Appointments: ${apts.docs.length}');
```

### Issue: "Riverpod state lost" after navigation

**Solution:** Use `keepAlive()` on providers that need to persist

```dart
final slotsForDayProvider = FutureProvider.family<List<AvailabilitySlot>, String>(
  (ref, doctorId) async {
    // Keep alive for 5 minutes
    ref.cacheFor(const Duration(minutes: 5));
    // ...
  },
);
```

### Issue: Overlapping slots creation not prevented

**Solution:** Ensure _getOverlappingSlots is returning results

```dart
// Debug overlap checking
final overlapping = await repository._getOverlappingSlots(doctorId, newSlot);
print('Overlaps found: ${overlapping.length}');
if (overlapping.isNotEmpty) {
  print('Conflicting slots: ${overlapping.map((s) => s.id).toList()}');
}
```

---

## 📚 Related Documentation

- [AGENDA_ARCHITECTURE.md](./AGENDA_ARCHITECTURE.md) - Full architecture & patterns
- [FIRESTORE_SETUP.md](./FIRESTORE_SETUP.md) - Database setup & indexes
- [AvailabilitySlot Model](../data/models/availability_slot.dart)
- [SlotsRepository](../data/repositories/slots_repository.dart)
- [Riverpod Providers](../presentation/providers/agenda_providers.dart)

---

## 🎓 Learn More

- [Riverpod Documentation](https://riverpod.dev)
- [Cloud Firestore Guide](https://firebase.google.com/docs/firestore)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)

---

**Last Updated:** January 1, 2026
**Version:** 1.0.0
**Status:** Ready for Integration
