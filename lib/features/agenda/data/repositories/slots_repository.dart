import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability_slot.dart';

/// Repository for managing doctor availability slots
/// Handles all CRUD operations for availability slots
class SlotsRepository {
  final FirebaseFirestore _firestore;

  SlotsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get collection reference for doctor's slots
  CollectionReference _doctorSlotsRef(String doctorId) {
    return _firestore.collection('doctors').doc(doctorId).collection('slots');
  }

  /// Add a new availability slot
  /// Throws exception if slot overlaps with existing slots
  Future<String> addSlot(String doctorId, AvailabilitySlot slot) async {
    try {
      // Check for overlapping slots
      final overlapping = await _getOverlappingSlots(doctorId, slot);
      if (overlapping.isNotEmpty) {
        throw Exception('Slot overlaps with existing slots');
      }

      final docRef = _doctorSlotsRef(doctorId).doc();
      final slotWithId = AvailabilitySlot(
        id: docRef.id,
        doctorId: doctorId,
        startTime: slot.startTime,
        endTime: slot.endTime,
        status: slot.status,
        type: slot.type,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        patientId: slot.patientId,
      );

      await docRef.set(slotWithId.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing slot
  /// Cannot update if slot is BOOKED
  Future<void> updateSlot(
    String doctorId,
    String slotId,
    AvailabilitySlot updates,
  ) async {
    try {
      // Fetch current slot to check if it's booked
      final currentSlot = await getSlot(doctorId, slotId);
      if (currentSlot == null) {
        throw Exception('Slot not found');
      }

      if (!currentSlot.canBeEdited()) {
        throw Exception('Cannot edit a booked slot');
      }

      // Check for overlaps with other slots (excluding current slot)
      final overlapping = await _getOverlappingSlots(
        doctorId,
        updates,
        excludeSlotId: slotId,
      );
      if (overlapping.isNotEmpty) {
        throw Exception('Updated slot would overlap with existing slots');
      }

      await _doctorSlotsRef(doctorId).doc(slotId).update({
        'startTime': Timestamp.fromDate(updates.startTime),
        'endTime': Timestamp.fromDate(updates.endTime),
        'status': updates.status.toString().split('.').last.toUpperCase(),
        'type': updates.type == ConsultationType.inPerson
            ? 'IN_PERSON'
            : 'VIDEO',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a slot
  /// Cannot delete if slot is BOOKED
  Future<void> deleteSlot(String doctorId, String slotId) async {
    try {
      final slot = await getSlot(doctorId, slotId);
      if (slot == null) {
        throw Exception('Slot not found');
      }

      if (!slot.canBeDeleted()) {
        throw Exception('Cannot delete a booked slot');
      }

      await _doctorSlotsRef(doctorId).doc(slotId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific slot
  Future<AvailabilitySlot?> getSlot(String doctorId, String slotId) async {
    try {
      final doc = await _doctorSlotsRef(doctorId).doc(slotId).get();
      if (!doc.exists) return null;
      return AvailabilitySlot.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all slots for a specific date (day view)
  /// Queries slots where startTime is on the given date
  Future<List<AvailabilitySlot>> getSlotsForDay(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = _doctorSlotsRef(doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all slots for a week (7 days starting from Monday)
  /// Optimized with date range queries
  Future<List<AvailabilitySlot>> getSlotsForWeek(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Calculate Monday of the week
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final query = _doctorSlotsRef(doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfWeek))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all slots for a month
  /// Optimized with date range queries
  Future<List<AvailabilitySlot>> getSlotsForMonth(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 1);

      final query = _doctorSlotsRef(doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all slots for a date range
  /// Generic query for custom ranges
  Future<List<AvailabilitySlot>> getSlotsForDateRange(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = _doctorSlotsRef(doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get available slots (not booked or blocked)
  Future<List<AvailabilitySlot>> getAvailableSlots(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = _doctorSlotsRef(doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'AVAILABLE');

      final snapshot = await query.get();
      final slots = snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();

      // Sort in memory instead of using orderBy to avoid index requirement
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));

      return slots;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all slots with real-time updates (for live calendar view)
  Stream<List<AvailabilitySlot>> watchSlotsForDay(
    String doctorId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _doctorSlotsRef(doctorId)
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AvailabilitySlot.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get overlapping slots (helper method)
  /// Used to prevent double-booking
  Future<List<AvailabilitySlot>> _getOverlappingSlots(
    String doctorId,
    AvailabilitySlot slot, {
    String? excludeSlotId,
  }) async {
    try {
      // Pull candidates with start before this slot ends, then filter locally to avoid multi-field inequality index
      final snapshot = await _doctorSlotsRef(
        doctorId,
      ).where('startTime', isLessThan: Timestamp.fromDate(slot.endTime)).get();

      final slots = snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .where(
            (s) =>
                // Slot must overlap: starts before this ends AND ends after this starts
                s.endTime.isAfter(slot.startTime),
          )
          .toList();

      // Filter out excluded slot
      return slots
          .where((s) => excludeSlotId == null || s.id != excludeSlotId)
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
