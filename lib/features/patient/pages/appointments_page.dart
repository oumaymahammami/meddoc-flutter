import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme_config.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = 'calendar'; // 'calendar' or 'list'

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Appointment> _appointments = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _subscribeAppointments();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _subscribeAppointments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _sub?.cancel();
    if (uid == null) {
      setState(() => _appointments = []);
      return;
    }

    final query = FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: uid)
        .orderBy('startTime');

    _sub = query.snapshots().listen((snapshot) {
      final mapped = snapshot.docs.map((doc) {
        final data = doc.data();
        final start = (data['startTime'] as Timestamp).toDate();
        final end = (data['endTime'] as Timestamp).toDate();
        final status = _parseStatus(data['status'] as String?);
        return Appointment(
          id: doc.id,
          title: (data['reason'] ?? 'Consultation').toString(),
          doctor: (data['doctorName'] ?? data['doctorId'] ?? 'Your doctor')
              .toString(),
          doctorId: (data['doctorId'] ?? '').toString(),
          specialty: (data['doctorSpecialty'] ?? '').toString(),
          slotId: data['slotId']?.toString(),
          date: DateTime(start.year, start.month, start.day),
          time: TimeOfDay.fromDateTime(start),
          duration: end.difference(start).inMinutes,
          type: AppointmentType.checkup,
          status: status,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _appointments = mapped;
        });
      }
    });
  }

  AppointmentStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'pending':
        return AppointmentStatus.pending;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }

  List<Appointment> _getAppointmentsForDate(DateTime date) {
    return _appointments.where((apt) {
      return apt.date.year == date.year &&
          apt.date.month == date.month &&
          apt.date.day == date.day;
    }).toList();
  }

  bool _hasAppointment(DateTime date) {
    return _appointments.any(
      (apt) =>
          apt.date.year == date.year &&
          apt.date.month == date.month &&
          apt.date.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cancelledCount = _appointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cancelledCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFCA5A5).withValues(alpha: 0.3),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: Row(
                  children: [
                    const Icon(
                      Icons.delete_sweep_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cancelledCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                onSelected: (value) {
                  if (value == 'clear') {
                    _clearCancelledAppointments();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear All Cancelled ($cancelledCount)',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'calendar',
                icon: Icon(Icons.calendar_month_rounded, size: 18),
              ),
              ButtonSegment(
                value: 'list',
                icon: Icon(Icons.view_list_rounded, size: 18),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _viewMode = newSelection.first;
                _fadeController.reset();
                _fadeController.forward();
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF667EEA);
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF718096);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(color: const Color(0xFFE2E8F0), width: 1);
              }),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _viewMode == 'calendar'
            ? _buildCalendarView()
            : _buildListView(),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/patient/search'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'New Appointment',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    // Make the whole view scrollable to avoid overflows on small screens.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildWeekDays(),
          _buildCalendarGrid(),
          const SizedBox(height: AppSpacing.md),
          _buildSelectedDateAppointments(shrinkWrap: true),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_appointments.length} appointments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildMonthNavButton(
                icon: Icons.chevron_left_rounded,
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildMonthNavButton(
                icon: Icons.chevron_right_rounded,
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 8,
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: startingWeekday + daysInMonth,
        itemBuilder: (context, index) {
          if (index < startingWeekday) {
            return const SizedBox();
          }

          final day = index - startingWeekday + 1;
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          final isSelected =
              _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isToday =
              DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;
          final hasAppointment = _hasAppointment(date);

          return _buildDatePill(date, isSelected, isToday, hasAppointment);
        },
      ),
    );
  }

  Widget _buildDatePill(
    DateTime date,
    bool isSelected,
    bool isToday,
    bool hasAppointment,
  ) {
    return TweenAnimationBuilder<double>(
      duration: AppAnimations.fast,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: isSelected ? 1.0 : scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() => _selectedDate = date);
              },
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : isToday
                      ? const LinearGradient(
                          colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).scale(0.3)
                      : null,
                  color: isSelected || isToday
                      ? null
                      : hasAppointment
                      ? const Color(0xFF4FD1C5).withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF667EEA).withValues(alpha: 0.5)
                        : isToday && !isSelected
                        ? const Color(0xFFFF5F6D).withValues(alpha: 0.5)
                        : hasAppointment && !isSelected
                        ? const Color(0xFF4FD1C5).withValues(alpha: 0.3)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF667EEA,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : isToday
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFF5F6D,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? const Color(0xFFFF5F6D)
                              : const Color(0xFF2D3748),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (hasAppointment && !isSelected)
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4FD1C5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4FD1C5),
                                  blurRadius: 3,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateAppointments({bool shrinkWrap = false}) {
    final appointments = _getAppointmentsForDate(_selectedDate);
    final isToday =
        DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC).withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isToday ? Icons.today_rounded : Icons.event_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isToday
                            ? 'Today\'s schedule'
                            : '${appointments.length} appointment${appointments.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          shrinkWrap
              ? (appointments.isEmpty
                    ? _buildEmptyAppointments()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(appointments[index]);
                        },
                      ))
              : Expanded(
                  child: appointments.isEmpty
                      ? _buildEmptyAppointments()
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(appointments[index]);
                          },
                        ),
                ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final upcomingAppointments = [..._appointments]
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: upcomingAppointments.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildAppointmentCard(upcomingAppointments[index]),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final statusColor = appointment.status == AppointmentStatus.confirmed
        ? const Color(0xFF10B981)
        : appointment.status == AppointmentStatus.pending
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return TweenAnimationBuilder<double>(
      duration: AppAnimations.normal,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCancelled
                      ? const Color(0xFFE5E7EB)
                      : statusColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCancelled
                        ? Colors.black.withOpacity(0.04)
                        : statusColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: isCancelled ? null : () {},
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Icon Container with gradient
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: isCancelled
                                    ? LinearGradient(
                                        colors: [
                                          Colors.grey.shade400,
                                          Colors.grey.shade500,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : _getAppointmentGradient(appointment.type),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCancelled
                                        ? Colors.grey.withOpacity(0.2)
                                        : _getAppointmentColor(
                                            appointment.type,
                                          ).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isCancelled
                                    ? Icons.event_busy_rounded
                                    : _getAppointmentIcon(appointment.type),
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appointment.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isCancelled
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF111827),
                                            decoration: isCancelled
                                                ? TextDecoration.lineThrough
                                                : null,
                                            letterSpacing: -0.3,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      _buildStatusBadge(appointment.status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isCancelled
                                              ? Colors.grey.shade200
                                              : _getAppointmentColor(
                                                  appointment.type,
                                                ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person_outline_rounded,
                                          size: 16,
                                          color: isCancelled
                                              ? Colors.grey.shade500
                                              : _getAppointmentColor(
                                                  appointment.type,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          appointment.doctor,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isCancelled
                                                ? Colors.grey.shade500
                                                : const Color(0xFF374151),
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (appointment.specialty != null &&
                                      appointment.specialty!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? Colors.grey.shade100
                                            : _getAppointmentColor(
                                                appointment.type,
                                              ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCancelled
                                              ? Colors.grey.shade300
                                              : _getAppointmentColor(
                                                  appointment.type,
                                                ).withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        appointment.specialty!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isCancelled
                                              ? Colors.grey.shade600
                                              : _getAppointmentColor(
                                                  appointment.type,
                                                ),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Modern time and date section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCancelled
                                  ? [Colors.grey.shade50, Colors.grey.shade100]
                                  : [
                                      _getAppointmentColor(
                                        appointment.type,
                                      ).withOpacity(0.08),
                                      _getAppointmentColor(
                                        appointment.type,
                                      ).withOpacity(0.03),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCancelled
                                  ? Colors.grey.shade200
                                  : _getAppointmentColor(
                                      appointment.type,
                                    ).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? Colors.grey.shade200
                                            : _getAppointmentColor(
                                                appointment.type,
                                              ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: isCancelled
                                            ? Colors.grey.shade600
                                            : _getAppointmentColor(
                                                appointment.type,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'EEE, d MMM',
                                        ).format(appointment.fullDate),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isCancelled
                                              ? Colors.grey.shade600
                                              : const Color(0xFF374151),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isCancelled
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade400,
                                            Colors.grey.shade500,
                                          ],
                                        )
                                      : _getAppointmentGradient(
                                          appointment.type,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isCancelled
                                          ? Colors.grey.withOpacity(0.2)
                                          : _getAppointmentColor(
                                              appointment.type,
                                            ).withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${appointment.time.format(context)} \u2022 ${appointment.duration}m',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        if (isCancelled)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _deleteSingleAppointment(appointment),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFEE2E2),
                                      Color(0xFFFECDCD),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.delete_sweep_rounded,
                                      size: 22,
                                      color: Color(0xFFDC2626),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Clear Appointment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _cancelAppointment(appointment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFEF4444),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 2,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 22),
                            label: const Text(
                              'Cancel Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    final color = status == AppointmentStatus.confirmed
        ? const Color(0xFF10B981)
        : status == AppointmentStatus.pending
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final label = status == AppointmentStatus.confirmed
        ? 'Confirmed'
        : status == AppointmentStatus.pending
        ? 'Pending'
        : 'Cancelled';

    final icon = status == AppointmentStatus.confirmed
        ? Icons.verified_rounded
        : status == AppointmentStatus.pending
        ? Icons.pending_rounded
        : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 64,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'No appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A202C),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your schedule is free this day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/patient/search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF667EEA).withValues(alpha: 0.3),
              ),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text(
                'Find a Doctor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(Appointment apt) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final aptRef = FirebaseFirestore.instance
            .collection('appointments')
            .doc(apt.id);
        txn.update(aptRef, {
          'status': 'CANCELLED',
          'cancelledBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (apt.slotId != null && apt.slotId!.isNotEmpty) {
          final doctorId = apt.doctorId.isNotEmpty ? apt.doctorId : null;
          if (doctorId != null) {
            txn.update(
              FirebaseFirestore.instance
                  .collection('doctors')
                  .doc(doctorId)
                  .collection('slots')
                  .doc(apt.slotId),
              {
                'status': 'AVAILABLE',
                'patientId': FieldValue.delete(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l annulation: $e')),
        );
      }
    }
  }

  Future<void> _deleteSingleAppointment(Appointment apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'Clear Appointment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Delete this cancelled appointment from your history? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(apt.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Appointment cleared successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearCancelledAppointments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cancelled Appointments'),
        content: const Text(
          'Are you sure you want to delete all cancelled appointments? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final cancelledAppointments = _appointments
          .where((apt) => apt.status == AppointmentStatus.cancelled)
          .toList();

      final batch = FirebaseFirestore.instance.batch();
      for (final apt in cancelledAppointments) {
        batch.delete(
          FirebaseFirestore.instance.collection('appointments').doc(apt.id),
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancelled appointments deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  LinearGradient _getAppointmentGradient(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return const LinearGradient(
          colors: [Color(0xFF4FD1C5), Color(0xFF38B2AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppointmentType.dental:
        return const LinearGradient(
          colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppointmentType.labWork:
        return const LinearGradient(
          colors: [Color(0xFFF6AD55), Color(0xFFED8936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppointmentType.specialist:
        return const LinearGradient(
          colors: [Color(0xFF63B3ED), Color(0xFF4299E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getAppointmentColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return const Color(0xFF4FD1C5);
      case AppointmentType.dental:
        return const Color(0xFF9F7AEA);
      case AppointmentType.labWork:
        return const Color(0xFFF6AD55);
      case AppointmentType.specialist:
        return const Color(0xFF63B3ED);
    }
  }

  IconData _getAppointmentIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.checkup:
        return Icons.medical_services_rounded;
      case AppointmentType.dental:
        return Icons.medication_rounded;
      case AppointmentType.labWork:
        return Icons.science_rounded;
      case AppointmentType.specialist:
        return Icons.local_hospital_rounded;
    }
  }
}

// Models
class Appointment {
  final String id;
  final String title;
  final String doctor;
  final String doctorId;
  final String? specialty;
  final String? slotId;
  final DateTime date;
  final TimeOfDay time;
  final int duration;
  final AppointmentType type;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.title,
    required this.doctor,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.duration,
    required this.type,
    required this.status,
    this.specialty,
    this.slotId,
  });

  DateTime get fullDate =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

enum AppointmentType { checkup, dental, labWork, specialist }

enum AppointmentStatus { confirmed, pending, cancelled }
