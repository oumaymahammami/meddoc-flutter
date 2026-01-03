import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../presentation/providers/doctor_providers.dart';
import '../presentation/pages/doctor_profile_edit_screen.dart';

class DoctorDashboardPage extends ConsumerWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MedDoc - Médecin')),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    final profileAsync = ref.watch(doctorProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('MedDoc - Médecin'), elevation: 0),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(doctorProfileProvider(uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No profile found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorProfileEditScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(doctorProfileProvider(uid).future),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue[100],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.specialty.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  if (profile.searchMetadata.isVerified)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Verified',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DoctorProfileEditScreen(),
                                ),
                              ).then((_) {
                                // Trigger provider refresh after edit
                                // (result is not used)
                              });
                            },
                            child: const Text('Edit Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Real-time Statistics Section
                _StatisticsSection(doctorId: uid),
                const SizedBox(height: 16),

                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Consultations',
                        value: profile.statistics.totalAppointments.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Rating',
                        value: profile.ratings.average.toStringAsFixed(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Reviews',
                        value: profile.ratings.count.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Info
                _SectionCard(
                  title: 'Contact Information',
                  children: [
                    _InfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: profile.phone,
                    ),
                    _InfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: profile.email,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Clinic Info
                _SectionCard(
                  title: 'Clinic Information',
                  children: [
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: profile.location.address,
                    ),
                    _InfoRow(
                      icon: Icons.location_city,
                      label: 'City',
                      value: profile.location.city,
                    ),
                    _InfoRow(
                      icon: Icons.mail,
                      label: 'Postal Code',
                      value: profile.location.postalCode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Consultation Modes & Pricing
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In-Person',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.consultationModes.inPerson
                                    ? '✓ Available'
                                    : '✗ Not available',
                                style: TextStyle(
                                  color: profile.consultationModes.inPerson
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              if (profile.consultationModes.inPerson)
                                Text(
                                  '${profile.pricing.inPersonFee} TND',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Video',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.consultationModes.video
                                    ? '✓ Available'
                                    : '✗ Not available',
                                style: TextStyle(
                                  color: profile.consultationModes.video
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              if (profile.consultationModes.video)
                                Text(
                                  '${profile.pricing.videoFee} TND',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Languages
                if (profile.credentials.languages.isNotEmpty)
                  _SectionCard(
                    title: 'Languages',
                    children: [
                      Wrap(
                        spacing: 8,
                        children: profile.credentials.languages
                            .map(
                              (lang) => Chip(
                                label: Text(lang),
                                backgroundColor: Colors.blue[100],
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Bio
                if (profile.profile.bio.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bio',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(profile.profile.bio),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final String doctorId;

  const _StatisticsSection({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots(),
      builder: (context, appointmentsSnapshot) {
        // Show error if any
        if (appointmentsSnapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error: ${appointmentsSnapshot.error}'),
                  const SizedBox(height: 8),
                  Text('Doctor ID: $doctorId'),
                ],
              ),
            ),
          );
        }

        if (appointmentsSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text('Loading statistics for doctor: $doctorId'),
                ],
              ),
            ),
          );
        }

        final appointments = appointmentsSnapshot.data?.docs ?? [];

        // Show message if no appointments
        if (appointments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 48),
                  const SizedBox(height: 8),
                  const Text('No appointments found yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Doctor ID: $doctorId',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Statistics will appear once you have appointments',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate statistics
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        int totalAppointments = appointments.length;
        int completedAppointments = 0;
        int pendingAppointments = 0;
        int confirmedAppointments = 0;
        int cancelledAppointments = 0;
        int todayAppointments = 0;
        int thisWeekAppointments = 0;
        int thisMonthAppointments = 0;
        Set<String> uniquePatients = {};
        double totalRevenue = 0;
        double thisMonthRevenue = 0;

        for (var doc in appointments) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
          final patientId = data['patientId'] as String?;
          final fee = (data['fee'] as num?)?.toDouble() ?? 0;

          // Count by status
          if (status == 'completed') {
            completedAppointments++;
            totalRevenue += fee;
            if (dateTime != null && dateTime.isAfter(monthStart)) {
              thisMonthRevenue += fee;
            }
          } else if (status == 'pending') {
            pendingAppointments++;
          } else if (status == 'confirmed') {
            confirmedAppointments++;
          } else if (status == 'cancelled') {
            cancelledAppointments++;
          }

          // Unique patients
          if (patientId != null) {
            uniquePatients.add(patientId);
          }

          // Time-based counts
          if (dateTime != null) {
            if (dateTime.isAfter(todayStart)) {
              todayAppointments++;
            }
            if (dateTime.isAfter(weekStart)) {
              thisWeekAppointments++;
            }
            if (dateTime.isAfter(monthStart)) {
              thisMonthAppointments++;
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity & Statistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalAppointments total visits',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _AnimatedStatCard(
                    title: 'Total Visits',
                    value: totalAppointments.toString(),
                    icon: Icons.event,
                    color: Colors.blue,
                    trend: '+${thisMonthAppointments}',
                    trendLabel: 'this month',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnimatedStatCard(
                    title: 'Patients',
                    value: uniquePatients.length.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                    trend: 'Unique',
                    trendLabel: 'total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _AnimatedStatCard(
                    title: 'Completed',
                    value: completedAppointments.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    trend:
                        '${totalAppointments > 0 ? ((completedAppointments / totalAppointments) * 100).toStringAsFixed(0) : 0}%',
                    trendLabel: 'rate',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AnimatedStatCard(
                    title: 'Revenue',
                    value: '${totalRevenue.toStringAsFixed(0)} TND',
                    icon: Icons.attach_money,
                    color: Colors.amber[700]!,
                    trend: '${thisMonthRevenue.toStringAsFixed(0)} TND',
                    trendLabel: 'this month',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Appointment Status Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4FD1C5), Color(0xFF38B2AC)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Appointment Status',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A202C),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      _StatusRow(
                        label: 'Pending',
                        count: pendingAppointments,
                        total: totalAppointments,
                        color: Colors.orange,
                        icon: Icons.pending,
                      ),
                      _StatusRow(
                        label: 'Confirmed',
                        count: confirmedAppointments,
                        total: totalAppointments,
                        color: Colors.blue,
                        icon: Icons.check_circle_outline,
                      ),
                      _StatusRow(
                        label: 'Completed',
                        count: completedAppointments,
                        total: totalAppointments,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                      _StatusRow(
                        label: 'Cancelled',
                        count: cancelledAppointments,
                        total: totalAppointments,
                        color: Colors.red,
                        icon: Icons.cancel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Time-based Activity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.timeline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Activity Timeline',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A202C),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      _TimelineRow(
                        label: 'Today',
                        count: todayAppointments,
                        icon: Icons.today,
                        color: Colors.purple,
                      ),
                      _TimelineRow(
                        label: 'This Week',
                        count: thisWeekAppointments,
                        icon: Icons.view_week,
                        color: Colors.indigo,
                      ),
                      _TimelineRow(
                        label: 'This Month',
                        count: thisMonthAppointments,
                        icon: Icons.calendar_month,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final String trendLabel;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendLabel,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.85 + (animValue * 0.15),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
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
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _TimelineRow({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'visits',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
