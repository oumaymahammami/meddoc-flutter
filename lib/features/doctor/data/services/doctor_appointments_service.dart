import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meddoc/features/agenda/data/models/appointment.dart';
import 'package:intl/intl.dart';

/// Service responsible for doctor-side appointment actions and slot sync.
class DoctorAppointmentsService {
  final FirebaseFirestore _firestore;

  DoctorAppointmentsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _appointmentsRef =>
      _firestore.collection('appointments');

  CollectionReference _slotsRef(String doctorId) =>
      _firestore.collection('doctors').doc(doctorId).collection('slots');

  Future<Appointment?> _getAppointment(String id) async {
    final doc = await _appointmentsRef.doc(id).get();
    if (!doc.exists) return null;
    return Appointment.fromFirestore(doc);
  }

  Future<void> acceptAppointment(String appointmentId) async {
    final appointment = await _getAppointment(appointmentId);
    if (appointment == null) return;

    await _firestore.runTransaction((txn) async {
      final aptRef = _appointmentsRef.doc(appointmentId);
      txn.update(aptRef, {'status': 'CONFIRMED', 'updatedAt': DateTime.now()});

      final slotRef = await _resolveSlotRef(
        appointment.doctorId,
        appointment,
        txn: txn,
      );
      if (slotRef != null) {
        txn.update(slotRef, {
          'status': 'BOOKED',
          'booking': {
            'appointmentId': appointmentId,
            'patientId': appointment.patientId,
            'date': _formatDate(appointment.startTime),
            'time': _formatTime(appointment.startTime),
          },
        });
      }
    });

    await _createReminders(appointment);
  }

  Future<void> rejectAppointment(
    String appointmentId, {
    required String reason,
  }) async {
    final appointment = await _getAppointment(appointmentId);
    if (appointment == null) return;

    await _firestore.runTransaction((txn) async {
      txn.update(_appointmentsRef.doc(appointmentId), {
        'status': 'REJECTED',
        'rejectionReason': reason,
        'updatedAt': DateTime.now(),
      });

      final slotRef = await _resolveSlotRef(
        appointment.doctorId,
        appointment,
        txn: txn,
      );
      if (slotRef != null) {
        txn.update(slotRef, {
          'status': 'AVAILABLE',
          'booking': FieldValue.delete(),
        });
      }
    });

    await _clearPendingNotifications(appointmentId);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final appointment = await _getAppointment(appointmentId);
    if (appointment == null) return;

    await _firestore.runTransaction((txn) async {
      txn.update(_appointmentsRef.doc(appointmentId), {
        'status': 'CANCELLED',
        'cancelledBy': 'doctor',
        'updatedAt': DateTime.now(),
      });

      final slotRef = await _resolveSlotRef(
        appointment.doctorId,
        appointment,
        txn: txn,
      );
      if (slotRef != null) {
        txn.update(slotRef, {
          'status': 'AVAILABLE',
          'booking': FieldValue.delete(),
        });
      }
    });

    await _clearPendingNotifications(appointmentId);
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStart,
    required Duration duration,
    String? slotId,
  }) async {
    final appointment = await _getAppointment(appointmentId);
    if (appointment == null) return;

    final newEnd = newStart.add(duration);

    await _firestore.runTransaction((txn) async {
      final aptRef = _appointmentsRef.doc(appointmentId);
      txn.update(aptRef, {
        'rescheduledFrom': {
          'date': _formatDate(appointment.startTime),
          'time': _formatTime(appointment.startTime),
          'startTime': appointment.startTime.toIso8601String(),
        },
        'startTime': newStart,
        'endTime': newEnd,
        'date': _formatDate(newStart),
        'time': _formatTime(newStart),
        'status': 'CONFIRMED',
        'updatedAt': DateTime.now(),
      });

      // Free old slot
      final oldSlotRef = await _resolveSlotRef(
        appointment.doctorId,
        appointment,
        txn: txn,
      );
      if (oldSlotRef != null) {
        txn.update(oldSlotRef, {
          'status': 'AVAILABLE',
          'booking': FieldValue.delete(),
        });
      }

      // Book new slot
      final newSlotRef = await _resolveSlotRef(
        appointment.doctorId,
        appointment.copyWith(
          startTime: newStart,
          endTime: newEnd,
          slotId: slotId ?? appointment.slotId,
        ),
        txn: txn,
      );
      if (newSlotRef != null) {
        txn.update(newSlotRef, {
          'status': 'BOOKED',
          'booking': {
            'appointmentId': appointmentId,
            'patientId': appointment.patientId,
            'date': _formatDate(newStart),
            'time': _formatTime(newStart),
          },
        });
      }
    });

    await _clearPendingNotifications(appointmentId);
    await _createReminders(
      appointment.copyWith(startTime: newStart, endTime: newEnd),
    );
  }

  /// Resolve slot document reference either by slotId if present or by startTime match.
  Future<DocumentReference?> _resolveSlotRef(
    String doctorId,
    Appointment appointment, {
    Transaction? txn,
  }) async {
    if (appointment.slotId != null) {
      return _slotsRef(doctorId).doc(appointment.slotId);
    }

    final query = await _slotsRef(doctorId)
        .where(
          'startTime',
          isEqualTo: Timestamp.fromDate(appointment.startTime),
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.reference;
  }

  Stream<List<Appointment>> watchAppointmentsByStatus(
    String doctorId,
    List<String> statuses,
  ) {
    return _appointmentsRef
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: statuses)
        .orderBy('startTime')
        .snapshots()
        .map((snap) => snap.docs.map(Appointment.fromFirestore).toList());
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// Create patient/doctor reminders as notification docs.
  Future<void> _createReminders(Appointment apt) async {
    final start = apt.startTime;
    final now = DateTime.now();

    DateTime remind(Duration delta) => start.subtract(delta);
    final patientReminders = <DateTime>[
      remind(const Duration(hours: 24)),
      remind(const Duration(hours: 2)),
    ].where((t) => t.isAfter(now)).toList();

    final doctorReminders = <DateTime>[
      remind(const Duration(minutes: 30)),
    ].where((t) => t.isAfter(now)).toList();

    final batch = _firestore.batch();
    final fmtHm = DateFormat('HH:mm');
    final doctorTime = fmtHm.format(start);

    for (final t in patientReminders) {
      final doc = _firestore.collection('notifications').doc();
      batch.set(doc, {
        'receiverId': apt.patientId,
        'receiverRole': 'patient',
        'appointmentId': apt.id,
        'title': 'Rappel',
        'body': 'RDV à ${fmtHm.format(start)} avec votre médecin.',
        'sent': false,
        'sendAt': t,
        'createdAt': DateTime.now(),
      });
    }

    for (final t in doctorReminders) {
      final doc = _firestore.collection('notifications').doc();
      batch.set(doc, {
        'receiverId': apt.doctorId,
        'receiverRole': 'doctor',
        'appointmentId': apt.id,
        'title': 'Rappel',
        'body': 'Vous avez un RDV à $doctorTime dans 30 min.',
        'sent': false,
        'sendAt': t,
        'createdAt': DateTime.now(),
      });
    }

    await batch.commit();
  }

  /// Clear pending notifications for an appointment (e.g., on reject/cancel/reschedule).
  Future<void> _clearPendingNotifications(String appointmentId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('appointmentId', isEqualTo: appointmentId)
        .where('sent', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

extension on Appointment {
  Appointment copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? slotId,
  }) {
    return Appointment(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      slotId: slotId ?? this.slotId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      mode: mode,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes,
      reason: reason,
      rescheduledFrom: rescheduledFrom,
      rejectionReason: rejectionReason,
      cancelledBy: cancelledBy,
    );
  }
}
