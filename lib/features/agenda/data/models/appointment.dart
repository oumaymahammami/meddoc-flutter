import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor appointment model
/// Represents a booked appointment between doctor and patient
class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String? patientName;
  final String? slotId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentMode mode; // IN_PERSON, VIDEO
  final AppointmentStatus status; // CONFIRMED, CANCELLED, COMPLETED
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String? reason;
  final Map<String, dynamic>? rescheduledFrom;
  final String? rejectionReason;
  final String? cancelledBy;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.patientName,
    this.slotId,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.reason,
    this.rescheduledFrom,
    this.rejectionReason,
    this.cancelledBy,
  });

  /// Create appointment from Firestore document
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] as String,
      patientId: data['patientId'] as String,
      patientName: data['patientName'] as String?,
      slotId: data['slotId'] as String?,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      mode: _parseAppointmentMode(data['mode'] as String),
      status: _parseAppointmentStatus(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
      reason: data['reason'] as String?,
      rescheduledFrom: data['rescheduledFrom'] as Map<String, dynamic>?,
      rejectionReason: data['rejectionReason'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      if (slotId != null) 'slotId': slotId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'mode': _appointmentModeToString(mode),
      'status': _appointmentStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'notes': notes,
      if (reason != null) 'reason': reason,
      if (rescheduledFrom != null) 'rescheduledFrom': rescheduledFrom,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
    };
  }

  int getDurationMinutes() => endTime.difference(startTime).inMinutes;

  @override
  String toString() =>
      'Appointment(id: $id, status: $status, startTime: $startTime)';
}

enum AppointmentMode { inPerson, video }

enum AppointmentStatus { pending, confirmed, cancelled, rejected, completed }

AppointmentMode _parseAppointmentMode(String value) {
  if (value.toUpperCase() == 'IN_PERSON') return AppointmentMode.inPerson;
  return AppointmentMode.video;
}

String _appointmentModeToString(AppointmentMode mode) {
  return mode == AppointmentMode.inPerson ? 'IN_PERSON' : 'VIDEO';
}

AppointmentStatus _parseAppointmentStatus(String value) {
  final lower = value.toLowerCase();
  switch (lower) {
    case 'pending':
      return AppointmentStatus.pending;
    case 'confirmed':
      return AppointmentStatus.confirmed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    case 'rejected':
      return AppointmentStatus.rejected;
    case 'completed':
      return AppointmentStatus.completed;
    default:
      return AppointmentStatus.pending;
  }
}

String _appointmentStatusToString(AppointmentStatus status) {
  return status.toString().split('.').last.toUpperCase();
}
