import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor availability slot model
/// Represents a time slot when doctor is available for consultations
class AvailabilitySlot {
  final String id;
  final String doctorId;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status; // AVAILABLE, BOOKED, BLOCKED
  final ConsultationType type; // IN_PERSON, VIDEO
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? patientId; // Only set if BOOKED

  AvailabilitySlot({
    required this.id,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.patientId,
  });

  /// Create slot from Firestore document
  factory AvailabilitySlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvailabilitySlot(
      id: doc.id,
      doctorId: data['doctorId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: _parseSlotStatus(data['status'] as String),
      type: _parseConsultationType(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      patientId: data['patientId'] as String?,
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': _slotStatusToString(status),
      'type': _consultationTypeToString(type),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'patientId': patientId,
    };
  }

  /// Check if slot overlaps with another slot
  bool overlaps(AvailabilitySlot other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  /// Check if slot is in the past
  bool isPast() => endTime.isBefore(DateTime.now());

  /// Check if slot can be deleted
  bool canBeDeleted() => status != SlotStatus.booked;

  /// Check if slot can be edited
  bool canBeEdited() => status != SlotStatus.booked;

  /// Get duration in minutes
  int getDurationMinutes() => endTime.difference(startTime).inMinutes;

  @override
  String toString() =>
      'AvailabilitySlot(id: $id, status: $status, startTime: $startTime)';
}

enum SlotStatus { available, booked, blocked }

enum ConsultationType { inPerson, video }

SlotStatus _parseSlotStatus(String value) {
  return SlotStatus.values.firstWhere(
    (e) => e.toString().split('.').last == value.toLowerCase(),
    orElse: () => SlotStatus.available,
  );
}

String _slotStatusToString(SlotStatus status) {
  return status.toString().split('.').last.toUpperCase();
}

ConsultationType _parseConsultationType(String value) {
  if (value.toUpperCase() == 'IN_PERSON') return ConsultationType.inPerson;
  return ConsultationType.video;
}

String _consultationTypeToString(ConsultationType type) {
  return type == ConsultationType.inPerson ? 'IN_PERSON' : 'VIDEO';
}
