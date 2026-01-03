import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

/// Repository for managing doctor appointments
/// Handles queries for appointments across date ranges
class AppointmentsRepository {
  final FirebaseFirestore _firestore;

  AppointmentsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get appointments collection reference
  CollectionReference get _appointmentsRef =>
      _firestore.collection('appointments');

  /// Get all appointments for a doctor for a specific date (day view)
  Future<List<Appointment>> getAppointmentsForDay(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all appointments for a doctor for a week
  Future<List<Appointment>> getAppointmentsForWeek(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Calculate Monday of the week
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfWeek))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all appointments for a doctor for a month
  Future<List<Appointment>> getAppointmentsForMonth(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 1);

      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get appointments for a date range
  Future<List<Appointment>> getAppointmentsForDateRange(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific appointment by ID
  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final doc = await _appointmentsRef.doc(appointmentId).get();
      if (!doc.exists) return null;
      return Appointment.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get active appointments (not cancelled or completed)
  Future<List<Appointment>> getActiveAppointments(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('startTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status == AppointmentStatus.confirmed)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming appointments (future appointments)
  Future<List<Appointment>> getUpcomingAppointments(
    String doctorId, {
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final query = _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startTime')
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => apt.doctorId == doctorId)
          .where((apt) => apt.status == AppointmentStatus.confirmed)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Watch appointments for a day in real-time
  Stream<List<Appointment>> watchAppointmentsForDay(
    String doctorId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _appointmentsRef
        .where('doctorId', isEqualTo: doctorId)
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .where((apt) => apt.status != AppointmentStatus.cancelled)
              .toList(),
        );
  }

  /// Get appointment statistics for a date range
  Future<AppointmentStats> getAppointmentStats(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final appointments = await getAppointmentsForDateRange(
        doctorId,
        startDate,
        endDate,
      );

      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;

      for (final apt in appointments) {
        switch (apt.status) {
          case AppointmentStatus.pending:
          case AppointmentStatus.rejected:
            break;
          case AppointmentStatus.confirmed:
            confirmed++;
            break;
          case AppointmentStatus.completed:
            completed++;
            break;
          case AppointmentStatus.cancelled:
            cancelled++;
            break;
        }
      }

      return AppointmentStats(
        total: appointments.length,
        confirmed: confirmed,
        completed: completed,
        cancelled: cancelled,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Statistics about appointments
class AppointmentStats {
  final int total;
  final int confirmed;
  final int completed;
  final int cancelled;

  AppointmentStats({
    required this.total,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
  });

  int get pending => confirmed + completed;
}
