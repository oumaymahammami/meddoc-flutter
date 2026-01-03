import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../providers/agenda_providers.dart';
import '../widgets/agenda_widgets.dart';
import '../../data/models/availability_slot.dart';
import '../../data/models/appointment.dart';

/// =====================
/// Premium UI Design Tokens (Medical Theme)
/// =====================
class MedDocTheme {
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color text = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);
  static const Color disabled = Color(0xFF94A3B8);

  static const Color primary = Color(0xFF2D9CDB);
  static const Color primaryDark = Color(0xFF1B6CA8);
  static const Color primarySoft = Color(0xFFE8F4FF);

  static const Color available = Color(0xFF22C55E);
  static const Color booked = Color(0xFFF59E0B);
  static const Color blocked = Color(0xFFEF4444);

  static BoxShadow softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 20,
    offset: const Offset(0, 12),
  );

  static BoxShadow subtleShadow = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );
}

/// Doctor's agenda/calendar screen
class AgendaScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const AgendaScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final viewMode = ref.watch(agendaViewModeProvider);

    return Scaffold(
      backgroundColor: MedDocTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: _premiumAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildHeader(context, ref, selectedDate, viewMode),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MedDocTheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: _buildCalendarContent(context, ref, viewMode),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _premiumFAB(context),
    );
  }

  PreferredSizeWidget _premiumAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: const Text(
        'My Agenda',
        style: TextStyle(
          color: MedDocTheme.text,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _iconContainer(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/doctor/dashboard');
            }
          },
        ),
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: Colors.white.withOpacity(0.65)),
        ),
      ),
    );
  }

  Widget _iconContainer({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MedDocTheme.border),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: MedDocTheme.text, size: 18),
        ),
      ),
    );
  }

  Widget _premiumFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddSlotDialog(context, ref),
      elevation: 10,
      backgroundColor: MedDocTheme.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Add Slot',
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  /// =====================
  /// HEADER
  /// =====================
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    AgendaViewMode viewMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MedDocTheme.primary, MedDocTheme.primaryDark],
        ),
        boxShadow: [MedDocTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _glassBadge(icon: Icons.bolt_rounded, label: "Flow Mode"),
              const SizedBox(width: 10),
              _glassBadge(icon: Icons.schedule_rounded, label: "Agenda"),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            CalendarUtils.formatDate(selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Manage your availability & appointments",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _viewChip(context, ref, 'Day', AgendaViewMode.day, viewMode),
              const SizedBox(width: 8),
              _viewChip(context, ref, 'Week', AgendaViewMode.week, viewMode),
              const SizedBox(width: 8),
              _viewChip(context, ref, 'Month', AgendaViewMode.month, viewMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    AgendaViewMode value,
    AgendaViewMode current,
  ) {
    final selected = value == current;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected ? Colors.white : Colors.white.withOpacity(0.16),
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withOpacity(0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.read(agendaViewModeProvider.notifier).state = value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? MedDocTheme.primaryDark : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// =====================
  /// Content by View Mode
  /// =====================
  Widget _buildCalendarContent(
    BuildContext context,
    WidgetRef ref,
    AgendaViewMode viewMode,
  ) {
    switch (viewMode) {
      case AgendaViewMode.day:
        return _buildDayView(context, ref);
      case AgendaViewMode.week:
        return _buildWeekView(context, ref);
      case AgendaViewMode.month:
        return _buildMonthView(context, ref);
    }
  }

  Widget _buildDayView(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(slotsForDayProvider(widget.doctorId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Availability Slots',
          icon: Icons.access_time_rounded,
          child: slotsAsync.when(
            data: (slots) => _buildSlotsList(slots, ref),
            loading: () => const _PremiumLoading(),
            error: (err, stack) => _errorBox(err.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final slotsAsync = ref.watch(slotsForWeekProvider(widget.doctorId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'This Week',
          icon: Icons.view_week_rounded,
          child: _buildWeekSelector(context, ref, selectedDate),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Availability Slots',
          icon: Icons.access_time_rounded,
          child: slotsAsync.when(
            data: (slots) => _buildSlotsList(slots, ref),
            loading: () => const _PremiumLoading(),
            error: (err, stack) => _errorBox(err.toString()),
          ),
        ),
      ],
    );
  }

  /// ✅ Month view: Real Calendar + Today Highlight + Booked Count Badge
  Widget _buildMonthView(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final slotsAsync = ref.watch(slotsForMonthProvider(widget.doctorId));

    return slotsAsync.when(
      data: (slots) {
        final bookedSlots = slots
            .where((s) => s.status == SlotStatus.booked)
            .length;
        final availableSlots = slots
            .where((s) => s.status == SlotStatus.available)
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              title: 'Month',
              icon: Icons.calendar_month_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(context, ref, selectedDate),
                  const SizedBox(height: 10),
                  _buildWeekdayHeader(),
                  const SizedBox(height: 8),

                  CompactMonthCalendar(
                    selectedDate: selectedDate,
                    slots: slots,
                    onDateSelected: (date) {
                      ref.read(selectedDateProvider.notifier).state = date;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Summary',
              icon: Icons.pie_chart_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: _summaryItem(
                      title: 'Available',
                      value: availableSlots.toString(),
                      color: MedDocTheme.available,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryItem(
                      title: 'Booked',
                      value: bookedSlots.toString(),
                      color: MedDocTheme.booked,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () =>
          const Padding(padding: EdgeInsets.all(16), child: _PremiumLoading()),
      error: (err, stack) => _errorBox(err.toString()),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => ref.read(selectedDateProvider.notifier).state = DateTime(
            selectedDate.year,
            selectedDate.month - 1,
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(selectedDate),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: MedDocTheme.text,
          ),
        ),
        _miniIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => ref.read(selectedDateProvider.notifier).state = DateTime(
            selectedDate.year,
            selectedDate.month + 1,
          ),
        ),
      ],
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MedDocTheme.primarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MedDocTheme.border),
        ),
        child: Icon(icon, color: MedDocTheme.primaryDark),
      ),
    );
  }

  /// Week selector with previous/next controls and date range label
  Widget _buildWeekSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    String rangeLabel() {
      final sameMonth = weekStart.month == weekEnd.month;
      final startFmt = DateFormat('d MMM').format(weekStart);
      final endFmt = sameMonth
          ? DateFormat('d MMM').format(weekEnd)
          : DateFormat('d MMM').format(weekEnd);
      return '$startFmt - $endFmt';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => ref.read(selectedDateProvider.notifier).state =
              selectedDate.subtract(const Duration(days: 7)),
        ),
        Text(
          rangeLabel(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: MedDocTheme.text,
          ),
        ),
        _miniIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => ref.read(selectedDateProvider.notifier).state =
              selectedDate.add(const Duration(days: 7)),
        ),
      ],
    );
  }

  Widget _buildSlotsList(List<AvailabilitySlot> slots, WidgetRef ref) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(34),
        child: Center(
          child: Text(
            'No slots available',
            style: TextStyle(
              color: MedDocTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: slots
          .map(
            (slot) => SlotCard(
              slot: slot,
              onTap: () => _showSlotDetails(context, slot),
              onEdit: () => _showEditSlotDialog(context, ref, slot),
              onDelete: () => _deleteSlot(context, ref, slot),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    color: MedDocTheme.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MedDocTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MedDocTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MedDocTheme.border),
        boxShadow: [MedDocTheme.subtleShadow],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MedDocTheme.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MedDocTheme.border),
                ),
                child: Icon(icon, color: MedDocTheme.primaryDark, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: MedDocTheme.text,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: MedDocTheme.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MedDocTheme.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String err) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          'Error: $err',
          style: const TextStyle(
            color: Color(0xFF991B1B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddSlotDialog(
        doctorId: widget.doctorId,
        initialDate: ref.read(selectedDateProvider),
        onSlotAdded: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slot added successfully')),
          );
        },
      ),
    );
  }

  void _showEditSlotDialog(
    BuildContext context,
    WidgetRef ref,
    AvailabilitySlot slot,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditSlotDialog(
        doctorId: widget.doctorId,
        slot: slot,
        onSlotUpdated: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slot updated successfully')),
          );
        },
      ),
    );
  }

  void _deleteSlot(BuildContext context, WidgetRef ref, AvailabilitySlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Slot?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to delete this slot?',
          style: TextStyle(color: MedDocTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(
                  deleteSlotProvider((
                    doctorId: widget.doctorId,
                    slotId: slot.id,
                  )).future,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: MedDocTheme.blocked),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlotDetails(BuildContext context, AvailabilitySlot slot) {}
  void _showAppointmentDetails(BuildContext context, Appointment appointment) {}
}

/// ===============================
/// ✅ Compact Month Calendar
/// - Today highlight ✅
/// - Booked count badge ✅
/// - Status dots ✅
/// ===============================
class CompactMonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final List<AvailabilitySlot> slots;
  final ValueChanged<DateTime> onDateSelected;

  const CompactMonthCalendar({
    super.key,
    required this.selectedDate,
    required this.slots,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon
    const totalCells = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4, // ✅ smaller spacing
        crossAxisSpacing: 4, // ✅ smaller spacing
        childAspectRatio: 1.05, // ✅ makes it smaller vertically
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - (startWeekday - 1) + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          dayNumber,
        );

        final isSelected = DateUtils.isSameDay(dayDate, selectedDate);
        final isToday = DateUtils.isSameDay(dayDate, DateTime.now());

        final daySlots = slots.where(
          (s) =>
              s.startTime.year == dayDate.year &&
              s.startTime.month == dayDate.month &&
              s.startTime.day == dayDate.day,
        );

        final bookedCount = daySlots
            .where((s) => s.status == SlotStatus.booked)
            .length;

        final hasAvailable = daySlots.any(
          (s) => s.status == SlotStatus.available,
        );
        final hasBooked = bookedCount > 0;
        final hasBlocked = daySlots.any((s) => s.status == SlotStatus.blocked);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onDateSelected(dayDate),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? MedDocTheme.primary
                  : isToday
                  ? MedDocTheme.primarySoft
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : isToday
                    ? MedDocTheme.primary.withOpacity(0.55)
                    : MedDocTheme.border,
                width: isToday ? 1.2 : 1,
              ),
            ),
            child: Stack(
              children: [
                /// ✅ smaller badge
                if (bookedCount > 0)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: _miniBadge(
                      text: bookedCount.toString(),
                      color: isSelected ? Colors.white : MedDocTheme.booked,
                      bg: isSelected
                          ? Colors.black.withOpacity(0.20)
                          : MedDocTheme.booked.withOpacity(0.12),
                    ),
                  ),

                /// main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$dayNumber",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12, // ✅ smaller font
                          height: 1,
                          color: isSelected ? Colors.white : MedDocTheme.text,
                        ),
                      ),

                      const SizedBox(height: 3),

                      /// ✅ smaller dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasAvailable)
                            _dot(
                              isSelected ? Colors.white : MedDocTheme.available,
                            ),
                          if (hasBooked)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: _dot(
                                isSelected ? Colors.white : MedDocTheme.booked,
                              ),
                            ),
                          if (hasBlocked)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: _dot(
                                isSelected ? Colors.white : MedDocTheme.blocked,
                              ),
                            ),
                        ],
                      ),

                      /// ✅ Today dot smaller
                      if (isToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : MedDocTheme.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dot(Color color) => Container(
    width: 4, // ✅ smaller dots
    height: 4,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _miniBadge({
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, // ✅ smaller badge text
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

/// Simple loading shimmer placeholder (top-level)
class _PremiumLoading extends StatelessWidget {
  const _PremiumLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerBar(width: 120),
          SizedBox(height: 12),
          _ShimmerBar(width: double.infinity),
          SizedBox(height: 8),
          _ShimmerBar(width: 220),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  const _ShimmerBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: MedDocTheme.primarySoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// ==================== Add Slot Dialog (Clean Time Range) ====================

class AddSlotDialog extends ConsumerStatefulWidget {
  final String doctorId;
  final DateTime initialDate;
  final VoidCallback onSlotAdded;

  const AddSlotDialog({
    Key? key,
    required this.doctorId,
    required this.initialDate,
    required this.onSlotAdded,
  }) : super(key: key);

  @override
  ConsumerState<AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends ConsumerState<AddSlotDialog> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late ConsultationType consultationType;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    startTime = const TimeOfDay(hour: 9, minute: 0);
    endTime = const TimeOfDay(hour: 10, minute: 0);
    consultationType = ConsultationType.inPerson;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: MedDocTheme.border),
              boxShadow: [MedDocTheme.softShadow],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Availability Slot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _dateTile(
                    context,
                    title: "Date",
                    subtitle: CalendarUtils.formatDate(selectedDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: MedDocTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Time Range',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _timePickerTile(
                          context: context,
                          label: "Start",
                          value: startTime.format(context),
                          icon: Icons.schedule_rounded,
                          initial: startTime,
                          onPick: (t) => setState(() => startTime = t),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timePickerTile(
                          context: context,
                          label: "End",
                          value: endTime.format(context),
                          icon: Icons.timer_outlined,
                          initial: endTime,
                          onPick: (t) => setState(() => endTime = t),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Consultation Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SegmentedButton<ConsultationType>(
                    segments: const <ButtonSegment<ConsultationType>>[
                      ButtonSegment(
                        value: ConsultationType.inPerson,
                        label: Text('In-Person'),
                      ),
                      ButtonSegment(
                        value: ConsultationType.video,
                        label: Text('Video'),
                      ),
                    ],
                    selected: <ConsultationType>{consultationType},
                    onSelectionChanged: (Set<ConsultationType> value) {
                      setState(() => consultationType = value.first);
                    },
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: MedDocTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedDocTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _addSlot(),
                        child: const Text(
                          'Add Slot',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MedDocTheme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedDocTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MedDocTheme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: MedDocTheme.primaryDark,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: MedDocTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: MedDocTheme.disabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: MedDocTheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MedDocTheme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedDocTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MedDocTheme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: MedDocTheme.primaryDark, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: MedDocTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: MedDocTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSlot() async {
    try {
      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      final slot = AvailabilitySlot(
        id: '',
        doctorId: widget.doctorId,
        startTime: startDateTime,
        endTime: endDateTime,
        status: SlotStatus.available,
        type: consultationType,
        createdAt: DateTime.now(),
      );

      await ref.read(
        addSlotProvider((doctorId: widget.doctorId, slot: slot)).future,
      );

      widget.onSlotAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

/// ==================== Edit Slot Dialog (same UI as Add but keeps update logic) ====================

class EditSlotDialog extends ConsumerStatefulWidget {
  final String doctorId;
  final AvailabilitySlot slot;
  final VoidCallback onSlotUpdated;

  const EditSlotDialog({
    Key? key,
    required this.doctorId,
    required this.slot,
    required this.onSlotUpdated,
  }) : super(key: key);

  @override
  ConsumerState<EditSlotDialog> createState() => _EditSlotDialogState();
}

class _EditSlotDialogState extends ConsumerState<EditSlotDialog> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late ConsultationType consultationType;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.slot.startTime;
    startTime = TimeOfDay.fromDateTime(widget.slot.startTime);
    endTime = TimeOfDay.fromDateTime(widget.slot.endTime);
    consultationType = widget.slot.type;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: MedDocTheme.border),
              boxShadow: [MedDocTheme.softShadow],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Availability Slot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: MedDocTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MedDocTheme.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MedDocTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: MedDocTheme.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: MedDocTheme.primaryDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Date",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: MedDocTheme.text,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CalendarUtils.formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: MedDocTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: MedDocTheme.disabled,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Time Range',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _timePickerTile(
                          context: context,
                          label: "Start",
                          value: startTime.format(context),
                          icon: Icons.schedule_rounded,
                          initial: startTime,
                          onPick: (t) => setState(() => startTime = t),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timePickerTile(
                          context: context,
                          label: "End",
                          value: endTime.format(context),
                          icon: Icons.timer_outlined,
                          initial: endTime,
                          onPick: (t) => setState(() => endTime = t),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Consultation Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: MedDocTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SegmentedButton<ConsultationType>(
                    segments: const <ButtonSegment<ConsultationType>>[
                      ButtonSegment(
                        value: ConsultationType.inPerson,
                        label: Text('In-Person'),
                      ),
                      ButtonSegment(
                        value: ConsultationType.video,
                        label: Text('Video'),
                      ),
                    ],
                    selected: <ConsultationType>{consultationType},
                    onSelectionChanged: (Set<ConsultationType> value) {
                      setState(() => consultationType = value.first);
                    },
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: MedDocTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedDocTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _updateSlot(),
                        child: const Text(
                          'Update Slot',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timePickerTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: MedDocTheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MedDocTheme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedDocTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MedDocTheme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: MedDocTheme.primaryDark, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: MedDocTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: MedDocTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateSlot() async {
    try {
      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      final updatedSlot = AvailabilitySlot(
        id: widget.slot.id,
        doctorId: widget.doctorId,
        startTime: startDateTime,
        endTime: endDateTime,
        status: widget.slot.status,
        type: consultationType,
        createdAt: widget.slot.createdAt,
        updatedAt: DateTime.now(),
        patientId: widget.slot.patientId,
      );

      await ref.read(
        updateSlotProvider((
          doctorId: widget.doctorId,
          slotId: widget.slot.id,
          updates: updatedSlot,
        )).future,
      );

      widget.onSlotUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
