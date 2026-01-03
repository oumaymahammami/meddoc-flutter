import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meddoc/features/agenda/data/models/availability_slot.dart';
import 'package:meddoc/features/agenda/data/models/appointment.dart';
import 'package:meddoc/features/agenda/data/repositories/slots_repository.dart';
import 'package:meddoc/features/agenda/data/repositories/appointments_repository.dart';

// ==================== Repository Providers ====================

/// Slots repository provider
final slotsRepositoryProvider = Provider((ref) {
  return SlotsRepository();
});

/// Appointments repository provider
final appointmentsRepositoryProvider = Provider((ref) {
  return AppointmentsRepository();
});

// ==================== Agenda View State ====================

/// Currently selected date in calendar view
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Currently selected view mode (Day/Week/Month)
final agendaViewModeProvider = StateProvider<AgendaViewMode>((ref) {
  return AgendaViewMode.week;
});

/// Enum for view modes
enum AgendaViewMode { day, week, month }

// ==================== Slots Providers ====================

/// Get slots for the selected day
final slotsForDayProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((
      ref,
      doctorId,
    ) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(slotsRepositoryProvider);
      return repository.getSlotsForDay(doctorId, selectedDate);
    });

/// Get slots for the selected week
final slotsForWeekProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((
      ref,
      doctorId,
    ) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(slotsRepositoryProvider);
      return repository.getSlotsForWeek(doctorId, selectedDate);
    });

/// Get slots for the selected month
final slotsForMonthProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((
      ref,
      doctorId,
    ) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(slotsRepositoryProvider);
      return repository.getSlotsForMonth(doctorId, selectedDate);
    });

/// Get slots based on selected view mode
final slotsForViewProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((
      ref,
      doctorId,
    ) async {
      final viewMode = ref.watch(agendaViewModeProvider);
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(slotsRepositoryProvider);

      switch (viewMode) {
        case AgendaViewMode.day:
          return repository.getSlotsForDay(doctorId, selectedDate);
        case AgendaViewMode.week:
          return repository.getSlotsForWeek(doctorId, selectedDate);
        case AgendaViewMode.month:
          return repository.getSlotsForMonth(doctorId, selectedDate);
      }
    });

/// Watch slots for real-time updates
final watchSlotsForDayProvider =
    StreamProvider.family<List<AvailabilitySlot>, String>((ref, doctorId) {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(slotsRepositoryProvider);
      return repository.watchSlotsForDay(doctorId, selectedDate);
    });

/// Available slots (not booked or blocked)
final availableSlotsProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((
      ref,
      doctorId,
    ) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final startDate = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final endDate = startDate.add(const Duration(days: 7));

      final repository = ref.watch(slotsRepositoryProvider);
      return repository.getAvailableSlots(doctorId, startDate, endDate);
    });

// ==================== Appointments Providers ====================

/// Get appointments for selected day
final appointmentsForDayProvider =
    FutureProvider.family<List<Appointment>, String>((ref, doctorId) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(appointmentsRepositoryProvider);
      return repository.getAppointmentsForDay(doctorId, selectedDate);
    });

/// Get appointments for selected week
final appointmentsForWeekProvider =
    FutureProvider.family<List<Appointment>, String>((ref, doctorId) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(appointmentsRepositoryProvider);
      return repository.getAppointmentsForWeek(doctorId, selectedDate);
    });

/// Get appointments for selected month
final appointmentsForMonthProvider =
    FutureProvider.family<List<Appointment>, String>((ref, doctorId) async {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(appointmentsRepositoryProvider);
      return repository.getAppointmentsForMonth(doctorId, selectedDate);
    });

/// Get appointments based on view mode
final appointmentsForViewProvider =
    FutureProvider.family<List<Appointment>, String>((ref, doctorId) async {
      final viewMode = ref.watch(agendaViewModeProvider);
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(appointmentsRepositoryProvider);

      switch (viewMode) {
        case AgendaViewMode.day:
          return repository.getAppointmentsForDay(doctorId, selectedDate);
        case AgendaViewMode.week:
          return repository.getAppointmentsForWeek(doctorId, selectedDate);
        case AgendaViewMode.month:
          return repository.getAppointmentsForMonth(doctorId, selectedDate);
      }
    });

/// Watch appointments for real-time updates
final watchAppointmentsForDayProvider =
    StreamProvider.family<List<Appointment>, String>((ref, doctorId) {
      final selectedDate = ref.watch(selectedDateProvider);
      final repository = ref.watch(appointmentsRepositoryProvider);
      return repository.watchAppointmentsForDay(doctorId, selectedDate);
    });

/// Get upcoming appointments
final upcomingAppointmentsProvider =
    FutureProvider.family<List<Appointment>, String>((ref, doctorId) async {
      final repository = ref.watch(appointmentsRepositoryProvider);
      return repository.getUpcomingAppointments(doctorId, limit: 10);
    });

// ==================== Combined Data Providers ====================

/// Get all calendar events (slots + appointments) for current view
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? slotId;
  final String? appointmentId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.slotId,
    this.appointmentId,
  });
}

enum EventType { slot, appointment }

final calendarEventsProvider =
    FutureProvider.family<List<CalendarEvent>, String>((ref, doctorId) async {
      final slots = await ref.watch(slotsForViewProvider(doctorId).future);
      final appointments = await ref.watch(
        appointmentsForViewProvider(doctorId).future,
      );

      final events = <CalendarEvent>[
        ...slots.map(
          (slot) => CalendarEvent(
            id: slot.id,
            title: slot.status == SlotStatus.booked ? 'Booked' : 'Available',
            startTime: slot.startTime,
            endTime: slot.endTime,
            type: EventType.slot,
            slotId: slot.id,
          ),
        ),
        ...appointments.map(
          (apt) => CalendarEvent(
            id: apt.id,
            title: 'Appointment',
            startTime: apt.startTime,
            endTime: apt.endTime,
            type: EventType.appointment,
            appointmentId: apt.id,
          ),
        ),
      ];

      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    });

// ==================== Action Providers ====================

/// Add a new slot
final addSlotProvider =
    FutureProvider.family<String, ({String doctorId, AvailabilitySlot slot})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(slotsRepositoryProvider);
      final slotId = await repository.addSlot(params.doctorId, params.slot);
      // Invalidate relevant caches
      ref.invalidate(slotsForDayProvider);
      ref.invalidate(slotsForWeekProvider);
      ref.invalidate(slotsForMonthProvider);
      ref.invalidate(calendarEventsProvider);
      return slotId;
    });

/// Update a slot
final updateSlotProvider =
    FutureProvider.family<
      void,
      ({String doctorId, String slotId, AvailabilitySlot updates})
    >((ref, params) async {
      final repository = ref.watch(slotsRepositoryProvider);
      await repository.updateSlot(
        params.doctorId,
        params.slotId,
        params.updates,
      );
      // Invalidate relevant caches
      ref.invalidate(slotsForDayProvider);
      ref.invalidate(slotsForWeekProvider);
      ref.invalidate(slotsForMonthProvider);
      ref.invalidate(calendarEventsProvider);
    });

/// Delete a slot
final deleteSlotProvider =
    FutureProvider.family<void, ({String doctorId, String slotId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(slotsRepositoryProvider);
      await repository.deleteSlot(params.doctorId, params.slotId);
      // Invalidate relevant caches
      ref.invalidate(slotsForDayProvider);
      ref.invalidate(slotsForWeekProvider);
      ref.invalidate(slotsForMonthProvider);
      ref.invalidate(calendarEventsProvider);
    });
