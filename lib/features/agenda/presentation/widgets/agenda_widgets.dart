import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../data/models/availability_slot.dart';
import '../../data/models/appointment.dart';

/// Calendar helper functions and utilities
class CalendarUtils {
  /// Get list of dates for current week (Monday to Sunday)
  static List<DateTime> getWeekDates(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(
      7,
      (index) => DateTime(monday.year, monday.month, monday.day + index),
    );
  }

  /// Get list of dates for current month
  static List<DateTime> getMonthDates(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(
      lastDay.day,
      (index) => DateTime(date.year, date.month, index + 1),
    );
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Format time range (e.g., "09:00 - 10:00")
  static String formatTimeRange(DateTime start, DateTime end) {
    final startStr = DateFormat('HH:mm').format(start);
    final endStr = DateFormat('HH:mm').format(end);
    return '$startStr - $endStr';
  }

  /// Format date (e.g., "Monday, 15 January")
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM').format(date);
  }

  /// Format date short (e.g., "15 Jan")
  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  /// Get time slots between two times with given interval
  static List<DateTime> getTimeSlots(DateTime date, int intervalMinutes) {
    final slots = <DateTime>[];
    var current = DateTime(
      date.year,
      date.month,
      date.day,
      8,
      0,
    ); // Start at 8 AM
    final end = DateTime(date.year, date.month, date.day, 20, 0); // End at 8 PM

    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: intervalMinutes));
    }

    return slots;
  }

  /// Check if slot overlaps with existing slots
  static bool hasOverlap(
    AvailabilitySlot newSlot,
    List<AvailabilitySlot> existingSlots,
  ) {
    return existingSlots.any((slot) => newSlot.overlaps(slot));
  }

  /// Check if appointment overlaps with existing appointments
  static bool hasAppointmentOverlap(
    Appointment newAppointment,
    List<Appointment> existingAppointments,
  ) {
    return existingAppointments.any(
      (apt) =>
          newAppointment.startTime.isBefore(apt.endTime) &&
          newAppointment.endTime.isAfter(apt.startTime),
    );
  }
}

/// Widget for displaying a single availability slot
class SlotCard extends StatelessWidget {
  final AvailabilitySlot slot;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SlotCard({
    Key? key,
    required this.slot,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeRange = CalendarUtils.formatTimeRange(
      slot.startTime,
      slot.endTime,
    );
    final isBooked = slot.status == SlotStatus.booked;
    final isBlocked = slot.status == SlotStatus.blocked;
    final isAvailable = slot.status == SlotStatus.available;
    final statusColor = isAvailable
        ? const Color(0xFF22C55E)
        : isBooked
        ? const Color(0xFFF59E0B)
        : isBlocked
        ? const Color(0xFFEF4444)
        : const Color(0xFF8B5CF6);
    final statusLabel = isAvailable
        ? 'Available'
        : isBooked
        ? 'Booked'
        : isBlocked
        ? 'Blocked'
        : 'Pending';
    final statusIcon = isAvailable
        ? Icons.check_circle
        : isBooked
        ? Icons.person
        : isBlocked
        ? Icons.lock
        : Icons.hourglass_top;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.type == ConsultationType.inPerson ? 'In-Person' : 'Video'} • ${slot.getDurationMinutes()} min',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(child: const Text('Edit'), onTap: onEdit),
                  PopupMenuItem(child: const Text('Delete'), onTap: onDelete),
                ],
                icon: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying a single appointment
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({Key? key, required this.appointment, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeRange = CalendarUtils.formatTimeRange(
      appointment.startTime,
      appointment.endTime,
    );
    final isInPerson = appointment.mode == AppointmentMode.inPerson;
    final statusColor = appointment.status == AppointmentStatus.confirmed
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Icon(
                  isInPerson ? Icons.meeting_room : Icons.videocam,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientId.isNotEmpty
                          ? 'Patient ${appointment.patientId.substring(0, math.min(6, appointment.patientId.length))}'
                          : 'Patient',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeRange,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${isInPerson ? 'In-Person' : 'Video'} • ${appointment.getDurationMinutes()} min',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      appointment.status == AppointmentStatus.confirmed
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appointment.status
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Time range selector widget
class TimeRangeSelector extends StatefulWidget {
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  final Function(TimeOfDay start, TimeOfDay end) onChanged;

  const TimeRangeSelector({
    Key? key,
    this.initialStart,
    this.initialEnd,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<TimeRangeSelector> createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends State<TimeRangeSelector> {
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  @override
  void initState() {
    super.initState();
    startTime = widget.initialStart ?? const TimeOfDay(hour: 9, minute: 0);
    endTime = widget.initialEnd ?? const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time Range', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() {
                          startTime = time;
                          widget.onChanged(startTime, endTime);
                        });
                      }
                    },
                    child: Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('End Time', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() {
                          endTime = time;
                          widget.onChanged(startTime, endTime);
                        });
                      }
                    },
                    child: Text(
                      endTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mini calendar for date selection
class MiniCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<AvailabilitySlot> slots;

  const MiniCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.slots = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dates = CalendarUtils.getMonthDates(selectedDate);
    final now = DateTime.now();
    final Map<int, SlotStatus> dayStatus = {};
    for (final slot in slots) {
      final day = slot.startTime.day;
      // Prioritize Booked > Blocked > Available
      final current = dayStatus[day];
      if (current == SlotStatus.booked) continue;
      if (current == SlotStatus.blocked && slot.status == SlotStatus.available)
        continue;
      dayStatus[day] = slot.status;
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.82,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: dates.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected = CalendarUtils.isSameDay(date, selectedDate);
        final isToday = CalendarUtils.isSameDay(date, now);
        final status = dayStatus[date.day];

        final baseColor = const Color(0xFF0EA5E9);
        final tileColor = isSelected
            ? baseColor
            : (isToday ? baseColor.withOpacity(0.10) : Colors.white);
        final textColor = isSelected
            ? Colors.white
            : (isToday ? baseColor : Colors.black87);

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? baseColor.withOpacity(0.8)
                    : Colors.grey.shade200,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: baseColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                if (status != null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: status == SlotStatus.booked
                          ? const Color(0xFFF59E0B)
                          : status == SlotStatus.blocked
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
