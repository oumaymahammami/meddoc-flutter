import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:meddoc/features/agenda/data/models/appointment.dart';
import 'package:meddoc/features/doctor/data/services/doctor_appointments_service.dart';

class DoctorAppointmentsPage extends ConsumerWidget {
  final String doctorId;
  const DoctorAppointmentsPage({Key? key, required this.doctorId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [_doctorIdProvider.overrideWithValue(doctorId)],
      child: const _DoctorAppointmentsView(),
    );
  }
}

final _doctorIdProvider = Provider<String>((ref) => '');
final _serviceProvider = Provider((ref) => DoctorAppointmentsService());

enum AppointmentTab { pending, confirmed, history }

final _tabProvider = StateProvider<AppointmentTab>(
  (ref) => AppointmentTab.pending,
);

final _searchProvider = StateProvider<String>((ref) => '');
final _dateFilterProvider = StateProvider<DateFilter>(
  (ref) => DateFilter.today,
);

enum DateFilter { today, week, custom }

final _appointmentsStreamProvider =
    StreamProvider.autoDispose<List<Appointment>>(
      (ref) {
        final doctorId = ref.watch(_doctorIdProvider);
        final tab = ref.watch(_tabProvider);
        final search = ref.watch(_searchProvider).toLowerCase();
        final service = ref.watch(_serviceProvider);

        List<String> statuses;
        if (tab == AppointmentTab.pending) {
          statuses = ['pending', 'PENDING'];
        } else if (tab == AppointmentTab.confirmed) {
          statuses = ['confirmed', 'CONFIRMED'];
        } else {
          statuses = ['cancelled', 'rejected', 'CANCELLED', 'REJECTED'];
        }

        return service
            .watchAppointmentsByStatus(doctorId, statuses)
            .map(
              (list) => list.where((apt) {
                if (search.isEmpty) return true;
                final patientName = apt.patientName?.toLowerCase() ?? '';
                final patientId = apt.patientId.toLowerCase();
                return patientName.contains(search) ||
                    patientId.contains(search);
              }).toList(),
            );
      },
      dependencies: [
        _doctorIdProvider,
        _serviceProvider,
        _tabProvider,
        _searchProvider,
      ],
    );

class _DoctorAppointmentsView extends ConsumerWidget {
  const _DoctorAppointmentsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final search = ref.watch(_searchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Appointments',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/doctor/dashboard');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchBar(
              value: search,
              onChanged: (v) =>
                  ref.read(_searchProvider.notifier).state = v.trim(),
            ),
          ),
          _TabBar(tab: tab),
          Expanded(child: _AppointmentsList()),
        ],
      ),
    );
  }
}

class _TabBar extends ConsumerWidget {
  final AppointmentTab tab;
  const _TabBar({required this.tab});

  Color _statusColor(AppointmentTab t) {
    switch (t) {
      case AppointmentTab.pending:
        return const Color(0xFF8B5CF6);
      case AppointmentTab.confirmed:
        return const Color(0xFF22C55E);
      case AppointmentTab.history:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: AppointmentTab.values.map((t) {
            final selected = t == tab;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => ref.read(_tabProvider.notifier).state = t,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _statusColor(t).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _tabLabel(t),
                      style: TextStyle(
                        color: selected
                            ? _statusColor(t)
                            : const Color(0xFF475569),
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _tabLabel(AppointmentTab t) {
    switch (t) {
      case AppointmentTab.pending:
        return 'Pending';
      case AppointmentTab.confirmed:
        return 'Confirmed';
      case AppointmentTab.history:
        return 'History';
    }
  }
}

class _AppointmentsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApts = ref.watch(_appointmentsStreamProvider);

    return asyncApts.when(
      loading: () => const _ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState();
        }
        final grouped = _groupByDate(list);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StickyHeader(label: entry.key),
                const SizedBox(height: 8),
                ...entry.value.map((apt) => _AppointmentCard(appointment: apt)),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<Appointment>> _groupByDate(List<Appointment> list) {
    final Map<String, List<Appointment>> map = {};
    final fmt = DateFormat('EEEE, d MMM');
    for (final apt in list) {
      final key = fmt.format(apt.startTime);
      map.putIfAbsent(key, () => []).add(apt);
    }
    return map;
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  Color get statusColor {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF22C55E);
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
      case AppointmentStatus.completed:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(_serviceProvider);
    final tab = ref.watch(_tabProvider);
    final actions = _actionsForStatus(appointment.status);

    return Dismissible(
      key: ValueKey(appointment.id),
      background: _swipeBg(
        color: const Color(0xFF22C55E),
        icon: Icons.check,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        color: const Color(0xFFF97316),
        icon: Icons.close,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (tab != AppointmentTab.pending) return false;
        if (direction == DismissDirection.startToEnd) {
          await service.acceptAppointment(appointment.id);
          return true;
        } else {
          await _confirmReject(context, ref, appointment.id);
          return true;
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetails(context, appointment),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F4FF),
                  child: const Icon(Icons.person, color: Color(0xFF1B6CA8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.patientName?.isNotEmpty == true
                                  ? appointment.patientName!
                                  : 'Patient ${appointment.patientId.substring(0, math.min(6, appointment.patientId.length))}',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: appointment.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${DateFormat('EEE, d MMM').format(appointment.startTime)} • ${DateFormat('HH:mm').format(appointment.startTime)}',
                        style: const TextStyle(
                          color: Color(0xFF1B6CA8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.reason ??
                            appointment.notes ??
                            'No reason provided',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: actions
                            .map(
                              (action) => _ActionChip(
                                label: action.label,
                                color: action.color,
                                icon: action.icon,
                                onTap: () => action.onTap(
                                  service,
                                  appointment,
                                  context,
                                  ref,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject appointment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(_serviceProvider)
                  .rejectAppointment(
                    id,
                    reason: controller.text.trim().isEmpty
                        ? 'No reason'
                        : controller.text.trim(),
                  );
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, Appointment apt) {
    // TODO: implement details screen / hero transition
  }

  _SwipeAction _action(
    String label,
    Color color,
    IconData icon,
    Future<void> Function(
      DoctorAppointmentsService service,
      Appointment apt,
      BuildContext context,
      WidgetRef ref,
    )
    onTap,
  ) => _SwipeAction(label: label, color: color, icon: icon, onTap: onTap);

  List<_SwipeAction> _actionsForStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return [
          _action(
            'Cancel',
            const Color(0xFFEF4444),
            Icons.close,
            (s, a, c, r) => s.cancelAppointment(a.id),
          ),
          _action(
            'Reschedule',
            const Color(0xFF2D9CDB),
            Icons.schedule,
            (s, a, c, r) => _showRescheduleSheet(c, r, a),
          ),
        ];
      case AppointmentStatus.cancelled:
      case AppointmentStatus.completed:
      case AppointmentStatus.rejected:
        return [];
      default:
        return [
          _action(
            'Accept',
            const Color(0xFF22C55E),
            Icons.check,
            (s, a, c, r) => s.acceptAppointment(a.id),
          ),
          _action(
            'Reject',
            const Color(0xFFF97316),
            Icons.close,
            (s, a, c, r) => _confirmReject(c, r, a.id),
          ),
          _action(
            'Reschedule',
            const Color(0xFF2D9CDB),
            Icons.schedule,
            (s, a, c, r) => _showRescheduleSheet(c, r, a),
          ),
        ];
    }
  }

  Future<void> _showRescheduleSheet(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) async {
    final duration = appointment.endTime.difference(appointment.startTime);
    DateTime newDate = appointment.startTime;
    TimeOfDay newTime = TimeOfDay.fromDateTime(appointment.startTime);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reschedule',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1B6CA8),
                ),
                title: Text(DateFormat('EEE, d MMM').format(newDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: newDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    newDate = picked;
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1B6CA8),
                ),
                title: Text(newTime.format(ctx)),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: newTime,
                  );
                  if (picked != null) {
                    newTime = picked;
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9CDB),
                    ),
                    onPressed: () async {
                      final newStart = DateTime(
                        newDate.year,
                        newDate.month,
                        newDate.day,
                        newTime.hour,
                        newTime.minute,
                      );
                      await ref
                          .read(_serviceProvider)
                          .rescheduleAppointment(
                            appointmentId: appointment.id,
                            newStart: newStart,
                            duration: duration,
                          );
                      // ignore: use_build_context_synchronously
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _SwipeAction {
  final String label;
  final Color color;
  final IconData icon;
  final Future<void> Function(
    DoctorAppointmentsService service,
    Appointment apt,
    BuildContext context,
    WidgetRef ref,
  )
  onTap;

  _SwipeAction({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _SearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search patient',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D9CDB)),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final label = _statusLabel(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFF8B5CF6);
      case AppointmentStatus.confirmed:
        return const Color(0xFF22C55E);
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
      case AppointmentStatus.rejected:
        return const Color(0xFFF97316);
      case AppointmentStatus.completed:
        return const Color(0xFF22C55E);
    }
  }

  IconData _statusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.close;
      case AppointmentStatus.rejected:
        return Icons.warning_amber;
      case AppointmentStatus.completed:
        return Icons.check_circle;
    }
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.completed:
        return 'Completed';
    }
  }
}

class _StickyHeader extends StatelessWidget {
  final String label;
  const _StickyHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_busy, size: 56, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No appointments here',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'New appointments will appear in this list.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmer = Tween<double>(begin: 0.3, end: 0.7).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        return Opacity(
          opacity: shimmer.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  width: 220,
                  color: const Color(0xFFE2E8F0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
