import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/datasources/patient_firestore_datasource.dart';
import '../data/repositories/patient_repository_impl.dart';
import '../domain/entities/patient_profile.dart';
import '../../../shared/pages/conversations_page.dart';
import '../../../shared/pages/notifications_page.dart';
import '../../video_consultation/models/video_consultation.dart';
import '../../video_consultation/widgets/video_consultation_card.dart';
import '../../video_consultation/pages/video_appointments_page.dart';

/// ✅ New Creative Premium Palette
class _MedColors {
  static const bg = Color(0xFFF6F7FB);

  static const text = Color(0xFF0F172A);
  static const subText = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);

  static const blue = Color(0xFF1D9BF0);
  static const violet = Color(0xFF7C6CF2);
  static const mint = Color(0xFF18D2B6);
  static const orange = Color(0xFFFF8A4C);
  static const pink = Color(0xFFFF5CA8);
  static const emerald = Color(0xFF22C55E);
  static const red = Color(0xFFFF4D4D);

  static const border = Color(0xFFE8EEF6);
}

final _headerGradient = const LinearGradient(
  colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2), Color(0xFF18D2B6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final _fabGradient = const LinearGradient(
  colors: [_MedColors.blue, Color(0xFF0F6AD9)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final _cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 24,
    offset: const Offset(0, 14),
  ),
];

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage>
    with TickerProviderStateMixin {
  final _patientRepo = PatientRepositoryImpl(PatientFirestoreDatasource());
  PatientProfile? _profile;
  bool _loading = true;
  bool _loadingDoctors = true;
  List<_DoctorLink> _myDoctors = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final profile = await _patientRepo.getProfile(uid);
        await _loadMyDoctors(uid);
        if (!mounted) return;
        setState(() {
          _profile = profile;
          _loading = false;
        });
        _fadeController.forward();
        _slideController.forward();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _loadMyDoctors(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patientDoctors')
          .doc(uid)
          .collection('doctors')
          .orderBy('linkedAt', descending: true)
          .limit(6)
          .get();

      final items = snap.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '') as String;
        return _DoctorLink(
          id: doc.id,
          name: name,
          specialty: (data['specialty'] ?? 'Spécialité') as String,
          city: (data['city'] ?? '') as String,
          avatarInitial: name.trim().isNotEmpty
              ? name.trim()[0].toUpperCase()
              : '?',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _myDoctors = items;
        _loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
      debugPrint('Error loading my doctors: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MedColors.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_MedColors.blue),
                strokeWidth: 2.8,
              ),
            )
          : _profile == null
          ? _buildEmptyState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: _MedColors.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildMiniInfoRow(),
                        const SizedBox(height: 16),
                        _buildActiveVideoConsultationSection(),
                        const SizedBox(height: 16),
                        _buildQuickActionsCarousel(),
                        const SizedBox(height: 18),
                        _buildMyDoctorsSection(),
                        const SizedBox(height: 18),
                        _buildMedicalStatsSection(),
                        const SizedBox(height: 22),
                        _buildUpcomingTimeline(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: _profile != null ? _buildFAB() : null,
    );
  }

  // =========================================================
  // ✅ APPBAR
  // =========================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "Health Hub",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where(
                'recipientId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            // Count only notifications that would be visible (same filter as notifications page)
            int unreadCount = 0;
            if (snapshot.hasData) {
              final now = DateTime.now();
              unreadCount = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] ?? '';
                final sent = data['sent'] ?? false;

                // For reminders, only count if sent is true
                if (type == 'appointment_reminder') {
                  return sent == true;
                }
                return true;
              }).length;
            }
            return _glassIconWithBadge(
              Icons.notifications_outlined,
              unreadCount,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
        _glassIcon(Icons.logout_outlined, () async {
          final router = GoRouter.of(context);
          await FirebaseAuth.instance.signOut();
          router.go('/login');
        }),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _glassIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _glassIconWithBadge(IconData icon, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Ink(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // ✅ HEADER (NEW CREATIVE)
  // =========================================================
  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 22),
        decoration: BoxDecoration(
          gradient: _headerGradient,
          boxShadow: _cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -60,
              child: _blurCircle(160, Colors.white.withOpacity(0.14)),
            ),
            Positioned(
              bottom: -40,
              left: -50,
              child: _blurCircle(180, Colors.white.withOpacity(0.12)),
            ),
            Row(
              children: [
                _profileAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bienvenue 👋",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile!.name.isNotEmpty ? _profile!.name : "Patient",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _profile!.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/patient/profile/edit'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: const SizedBox(),
      ),
    );
  }

  Widget _profileAvatar() {
    final initial = _profile!.name.isNotEmpty
        ? _profile!.name[0].toUpperCase()
        : "?";

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ✅ MINI INFO PILLS (VERY SMALL / MODERN)
  // =========================================================
  Widget _buildMiniInfoRow() {
    final age = _profile!.dateOfBirth != null
        ? "${DateTime.now().year - _profile!.dateOfBirth!.year} ans"
        : "N/A";

    final pills = [
      ("Age", age, _MedColors.violet, Icons.cake_outlined),
      (
        "Doctors",
        "${_myDoctors.length}",
        _MedColors.blue,
        Icons.medical_services_rounded,
      ),
      ("Tracking", "Active", _MedColors.emerald, Icons.analytics_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: pills.map((p) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: p == pills.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: p.$3.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.$3.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: p.$3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(p.$4, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.$1,
                          style: const TextStyle(
                            fontSize: 10.2,
                            fontWeight: FontWeight.w800,
                            color: _MedColors.subText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.$2,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: p.$3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================
  // ✅ ACTIVE VIDEO CONSULTATION SECTION
  // =========================================================
  Widget _buildActiveVideoConsultationSection() {
    final patientId = FirebaseAuth.instance.currentUser?.uid;
    if (patientId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videoConsultations')
          .where('patientId', isEqualTo: patientId)
          .where(
            'status',
            whereIn: ['scheduled', 'patient_waiting', 'in_progress'],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get active consultations only
        final now = DateTime.now();
        final activeConsultations = snapshot.data!.docs
            .map((doc) => VideoConsultation.fromFirestore(doc))
            .where((c) {
              return c.endTime.isAfter(now) ||
                  c.status == VideoConsultationStatus.inProgress ||
                  c.status == VideoConsultationStatus.patientWaiting;
            })
            .toList();

        if (activeConsultations.isEmpty) {
          return const SizedBox.shrink();
        }

        activeConsultations.sort(
          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.video_call_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Active Video Consultation',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _MedColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            VideoConsultationCard(
              consultation: activeConsultations.first,
              isPatient: true,
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // ✅ VIDEO CONSULTATION SECTION (OLD - KEEP FOR REFERENCE)
  // =========================================================
  Widget _buildVideoConsultationSection() {
    final patientId = FirebaseAuth.instance.currentUser?.uid;
    if (patientId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videoConsultations')
          .where('patientId', isEqualTo: patientId)
          .where(
            'status',
            whereIn: [
              'scheduled',
              'patient_waiting',
              'in_progress',
              'completed',
            ],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get all consultations
        final now = DateTime.now();
        final allConsultations = snapshot.data!.docs
            .map((doc) => VideoConsultation.fromFirestore(doc))
            .toList();

        // Separate active and completed consultations
        final activeConsultations = allConsultations.where((c) {
          return (c.endTime.isAfter(now) ||
                  c.status == VideoConsultationStatus.inProgress ||
                  c.status == VideoConsultationStatus.patientWaiting) &&
              c.status != VideoConsultationStatus.completed;
        }).toList();

        final completedConsultations = allConsultations.where((c) {
          return c.status == VideoConsultationStatus.completed;
        }).toList();

        if (activeConsultations.isEmpty && completedConsultations.isEmpty) {
          return const SizedBox.shrink();
        }

        activeConsultations.sort(
          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
        );

        completedConsultations.sort(
          (a, b) => b.scheduledTime.compareTo(a.scheduledTime),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeConsultations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VideoAppointmentsPage(isDoctor: false),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.video_call_rounded,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Video Consultations',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _MedColors.text,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VideoConsultationCard(
                consultation: activeConsultations.first,
                isPatient: true,
              ),
              const SizedBox(height: 24),
            ],
            if (completedConsultations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Completed Consultations',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _MedColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...completedConsultations
                  .take(3)
                  .map(
                    (consultation) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: VideoConsultationCard(
                        consultation: consultation,
                        isPatient: true,
                      ),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }

  // =========================================================
  // ✅ QUICK ACTIONS (HORIZONTAL CAROUSEL)
  // =========================================================
  Widget _buildQuickActionsCarousel() {
    final actions = [
      (
        "Find a Doctor",
        Icons.search_rounded,
        _MedColors.blue,
        () {
          context.push('/patient/search');
        },
      ),
      (
        "Appointment",
        Icons.calendar_month_rounded,
        _MedColors.violet,
        () {
          context.push('/patient/appointments');
        },
      ),
      (
        "Video Consultations",
        Icons.video_call_rounded,
        const Color(0xFF7C3AED),
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const VideoAppointmentsPage(isDoctor: false),
            ),
          );
        },
      ),
      (
        "Messages",
        Icons.chat_bubble_rounded,
        _MedColors.pink,
        () {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConversationsPage(),
              ),
            );
          }
        },
      ),
      (
        "Medications",
        Icons.medication_rounded,
        _MedColors.orange,
        () {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _AllMedicationsPage(patientId: uid),
              ),
            );
          }
        },
      ),
      (
        "Documents",
        Icons.folder_rounded,
        _MedColors.mint,
        () {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _MedicalDocumentsPage(patientId: uid),
              ),
            );
          }
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Actions rapides", "Swipe →"),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = actions[index];
                return _actionPill(
                  title: item.$1,
                  icon: item.$2,
                  color: item.$3,
                  onTap: item.$4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.70)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ✅ HEALTH TILES (STRONG SQUARE TILES)
  // =========================================================
  // =========================================================
  // ✅ MEDICAL STATS SECTION (REAL DATA)
  // =========================================================
  Widget _buildMedicalStatsSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<Map<String, int>>(
        future: _getMedicalStats(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final stats =
              snapshot.data ??
              {
                'appointments': 0,
                'medications': 0,
                'doctors': _myDoctors.length,
                'completed': 0,
              };

          final tiles = [
            (
              "RDV",
              "${stats['appointments']}",
              _MedColors.blue,
              Icons.calendar_today_rounded,
            ),
            (
              "Medications",
              "${stats['medications']}",
              _MedColors.emerald,
              Icons.medication_rounded,
            ),
            (
              "Doctors",
              "${stats['doctors']}",
              _MedColors.violet,
              Icons.medical_services_rounded,
            ),
            (
              "Consultations",
              "${stats['completed']}",
              _MedColors.orange,
              Icons.check_circle_rounded,
            ),
          ];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _MedColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: tiles.map((t) {
                return Expanded(
                  child: _medicalStatTile(t.$1, t.$2, t.$3, t.$4),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getMedicalStats(String patientId) async {
    try {
      // Count total appointments
      final appointmentsQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      final completedAppointments = appointmentsQuery.docs
          .where(
            (doc) =>
                (doc.data()['status'] ?? '').toString().toUpperCase() ==
                'COMPLETED',
          )
          .length;

      // Count medications from all doctors
      final medications = await _getAllPatientMedications(patientId);

      // Count doctors
      final doctorsCount = _myDoctors.length;

      return {
        'appointments': appointmentsQuery.docs.length,
        'medications': medications.length,
        'doctors': doctorsCount,
        'completed': completedAppointments,
      };
    } catch (e) {
      print('Error loading medical stats: $e');
      return {
        'appointments': 0,
        'medications': 0,
        'doctors': _myDoctors.length,
        'completed': 0,
      };
    }
  }

  Widget _medicalStatTile(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _MedColors.subText,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ✅ HEALTH TILES (REMOVED - REPLACED WITH MEDICAL STATS)
  // =========================================================
  Widget _buildHealthTiles() {
    final tiles = [
      ("Fréquence", "78 bpm", _MedColors.red, Icons.monitor_heart_rounded),
      ("Hydratation", "1.8L", _MedColors.blue, Icons.water_drop_rounded),
      ("Sommeil", "7h 12m", _MedColors.violet, Icons.bedtime_rounded),
      ("Activité", "3.2k", _MedColors.emerald, Icons.directions_run_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Résumé santé", "Aujourd’hui"),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final t = tiles[index];
              return _healthTile(t.$1, t.$2, t.$3, t.$4);
            },
          ),
        ],
      ),
    );
  }

  Widget _healthTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _MedColors.subText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ✅ TODAY'S APPOINTMENTS SECTION
  // =========================================================
  Widget _buildUpcomingTimeline() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Today's", "Appointments"),
          const SizedBox(height: 14),

          // Stream TODAY's appointments
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('patientId', isEqualTo: userId)
                .where(
                  'status',
                  whereIn: [
                    'pending',
                    'PENDING',
                    'confirmed',
                    'CONFIRMED',
                    'booked',
                    'BOOKED',
                    'scheduled',
                    'SCHEDULED',
                  ],
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _timelineShimmer();
              }

              // Debug: Check if we have data
              print(
                '📅 Appointments snapshot: hasData=${snapshot.hasData}, error=${snapshot.error}',
              );
              print('📅 Documents count: ${snapshot.data?.docs.length ?? 0}');

              final allAppointments = snapshot.data?.docs ?? [];

              // Filter for TODAY's appointments only
              final now = DateTime.now();
              final startOfDay = DateTime(now.year, now.month, now.day);
              final endOfDay = DateTime(
                now.year,
                now.month,
                now.day,
                23,
                59,
                59,
              );

              print('🕐 NOW: $now');
              print('🌅 START OF DAY: $startOfDay');
              print('🌆 END OF DAY: $endOfDay');

              // Debug: Print ALL appointments with their dates
              for (final doc in allAppointments) {
                final data = doc.data() as Map<String, dynamic>;
                final startTime =
                    (data['startTime'] as Timestamp?)?.toDate().toLocal();
                final dateTime =
                    (data['dateTime'] as Timestamp?)?.toDate().toLocal();
                final actualTime = startTime ?? dateTime;
                final status = data['status'];
                print(
                  '  📋 Raw Appointment: status=$status, startTime=$startTime, dateTime=$dateTime',
                );
              }

              final todayAppointments = allAppointments.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final startTime =
                    (data['startTime'] as Timestamp?)?.toDate().toLocal();
                final dateTime =
                    (data['dateTime'] as Timestamp?)?.toDate().toLocal();
                final actualTime = startTime ?? dateTime;

                if (actualTime == null) {
                  print('  ⚠️ Appointment has NULL startTime and dateTime');
                  return false;
                }

                // Check if appointment is today (inclusive of boundaries)
                final isAfterOrEqualStart = !actualTime.isBefore(startOfDay);
                final isBeforeOrEqualEnd = !actualTime.isAfter(endOfDay);
                final isToday = isAfterOrEqualStart && isBeforeOrEqualEnd;

                print('  🔍 Checking: $actualTime');
                print(
                  '     isAfterOrEqualStart=$isAfterOrEqualStart, isBeforeOrEqualEnd=$isBeforeOrEqualEnd, isToday=$isToday',
                );

                return isToday;
              }).toList();

              print(
                '📅 Today\'s appointments count: ${todayAppointments.length}',
              );

              final todayData = todayAppointments
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              // Next appointment preview (first sorted)
              final nextAppointment =
                  todayData.isNotEmpty ? todayData.first : null;

              // Sort by time
              todayAppointments.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aStartTime =
                    (aData['startTime'] as Timestamp?)?.toDate().toLocal();
                final aDateTime =
                    (aData['dateTime'] as Timestamp?)?.toDate().toLocal();
                final aTime = aStartTime ?? aDateTime ?? now;
                final bStartTime =
                    (bData['startTime'] as Timestamp?)?.toDate().toLocal();
                final bDateTime =
                    (bData['dateTime'] as Timestamp?)?.toDate().toLocal();
                final bTime = bStartTime ?? bDateTime ?? now;
                return aTime.compareTo(bTime);
              });

              return Column(
                children: [
                  _todaySummaryCard(
                    todayData,
                    nextAppointment,
                    onTap: () => _showTodayAppointmentsSheet(todayData),
                  ),
                  const SizedBox(height: 12),
                  if (todayData.isEmpty)
                    _emptyTodayAppointmentCard()
                  else
                    _todayAppointmentCard(todayData.first),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _MedColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _MedColors.text,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _MedColors.subText,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: _MedColors.muted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTodayAppointmentCard() {
    return _timelineItem(
      color: _MedColors.blue,
      icon: Icons.event_available_rounded,
      title: "No appointments today",
      subtitle: "You don't have any appointments scheduled for today.",
      onTap: () => context.push('/patient/search'),
    );
  }

  Widget _reminderCard() {
    return _timelineItem(
      color: _MedColors.emerald,
      icon: Icons.notifications_active_rounded,
      title: "Reminders enabled ✅",
      subtitle:
          "You'll receive notifications 1h, 30min, 15min, and 5min before appointments.",
    );
  }

  Widget _todaySummaryCard(
    List<Map<String, dynamic>> appointments,
    Map<String, dynamic>? nextAppointment, {
    required VoidCallback onTap,
  }) {
    DateTime? nextTime;
    if (nextAppointment != null) {
      final start =
          (nextAppointment['startTime'] as Timestamp?)?.toDate().toLocal();
      final dt =
          (nextAppointment['dateTime'] as Timestamp?)?.toDate().toLocal();
      nextTime = start ?? dt;
    }

    final hasAppointments = appointments.isNotEmpty;
    final badgeText = hasAppointments
        ? '${appointments.length} today'
        : 'No appointments today';
    final timeText =
        hasAppointments && nextTime != null ? DateFormat('HH:mm').format(nextTime) : 'Tap to schedule';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAppointments
                        ? "Today's appointments"
                        : "You're all clear today",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayAppointmentsSheet(
    List<Map<String, dynamic>> appointments,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.event_available_rounded,
                            color: _MedColors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Today's appointments",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _MedColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: appointments.isEmpty
                        ? Center(
                            child: _emptyTodayAppointmentCard(),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final data = appointments[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12.0),
                                child: _todayAppointmentCard(data),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _todayAppointmentCard(Map<String, dynamic> appointmentData) {
    final doctorId = appointmentData['doctorId'] as String?;
    final startTime =
        (appointmentData['startTime'] as Timestamp?)?.toDate().toLocal();
    final dateTime =
        (appointmentData['dateTime'] as Timestamp?)?.toDate().toLocal();
    final actualTime = startTime ?? dateTime;
    final status =
        (appointmentData['status'] as String?)?.toString().toLowerCase();

    if (doctorId == null || actualTime == null) return const SizedBox.shrink();

    // Format time for today
    String timeText = "Today at ${DateFormat('HH:mm').format(actualTime)}";

    Color statusColor = _MedColors.blue;
    IconData statusIcon = Icons.schedule_rounded;

    if (status == 'confirmed') {
      statusColor = _MedColors.emerald;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'pending' ||
        status == 'booked' ||
        status == 'scheduled') {
      statusColor = _MedColors.orange;
      statusIcon = Icons.pending_outlined;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get(),
      builder: (context, snapshot) {
        final doctorData = snapshot.data?.data() as Map<String, dynamic>?;
        final doctorName = doctorData?['fullName'] as String? ?? 'Doctor';
        final specialty =
            doctorData?['specialtyName'] as String? ?? 'Consultation';

        return InkWell(
          onTap: () => context.push('/patient/appointments'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.08),
                  statusColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _MedColors.text,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: _MedColors.subText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _MedColors.subText,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _MedColors.muted,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _upcomingAppointmentCard(Map<String, dynamic> appointmentData) {
    final doctorId = appointmentData['doctorId'] as String?;
    final dateTime = (appointmentData['dateTime'] as Timestamp?)?.toDate();
    final status = appointmentData['status'] as String?;

    if (doctorId == null || dateTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final isToday = difference.inHours < 24 && difference.inHours >= 0;
    final isTomorrow = difference.inHours >= 24 && difference.inHours < 48;

    String timeText;
    if (isToday) {
      timeText = "Today at ${DateFormat('HH:mm').format(dateTime)}";
    } else if (isTomorrow) {
      timeText = "Tomorrow at ${DateFormat('HH:mm').format(dateTime)}";
    } else {
      timeText = DateFormat('dd MMM at HH:mm').format(dateTime);
    }

    Color statusColor = _MedColors.blue;
    IconData statusIcon = Icons.schedule_rounded;

    if (status == 'confirmed') {
      statusColor = _MedColors.emerald;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'pending') {
      statusColor = _MedColors.orange;
      statusIcon = Icons.pending_outlined;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get(),
      builder: (context, snapshot) {
        final doctorData = snapshot.data?.data() as Map<String, dynamic>?;
        final doctorName = doctorData?['fullName'] as String? ?? 'Doctor';
        final specialty =
            doctorData?['specialtyName'] as String? ?? 'Consultation';

        return InkWell(
          onTap: () => context.push('/patient/appointments'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.08),
                  statusColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _MedColors.text,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: _MedColors.subText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _MedColors.subText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _timelineShimmer() {
    return Column(
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ✅ FAB
  // =========================================================
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: _fabGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _MedColors.blue.withOpacity(0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Prendre RDV",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // =========================================================
  // ✅ SECTION TITLE
  // =========================================================
  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _MedColors.text,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _MedColors.muted,
          ),
        ),
      ],
    );
  }

  Future<List<QueryDocumentSnapshot>> _getAllPatientMedications(
    String patientId,
  ) async {
    // Get all doctors linked to this patient
    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection('patientDoctors')
        .doc(patientId)
        .collection('doctors')
        .get();

    final List<QueryDocumentSnapshot> allMedications = [];

    // For each doctor, get their prescribed medications
    for (final doctorDoc in doctorsSnapshot.docs) {
      final doctorId = doctorDoc.id;
      final medicationsSnapshot = await FirebaseFirestore.instance
          .collection('doctorPatients')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .collection('medications')
          .orderBy('prescribedAt', descending: true)
          .get();

      allMedications.addAll(medicationsSnapshot.docs);
    }

    // Sort by prescribed date
    allMedications.sort((a, b) {
      final aTime =
          (a.data() as Map<String, dynamic>)['prescribedAt'] as Timestamp?;
      final bTime =
          (b.data() as Map<String, dynamic>)['prescribedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return allMedications;
  }

  // =========================================================
  // ✅ MY DOCTORS SECTION
  // =========================================================
  Widget _buildMyDoctorsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("My Doctors", "Follow-up"),
          const SizedBox(height: 10),

          // Premium Card with Click to View All
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D9BF0).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadingDoctors ? null : () => _navigateToMyDoctors(),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          if (!_loadingDoctors)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_myDoctors.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'My Doctors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadingDoctors
                            ? 'Loading...'
                            : _myDoctors.isEmpty
                            ? 'No doctors yet'
                            : 'Tap to view all doctors',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_loadingDoctors && _myDoctors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ...(_myDoctors
                                .take(3)
                                .map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        d.avatarInitial,
                                        style: const TextStyle(
                                          color: Color(0xFF1D9BF0),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                            if (_myDoctors.length > 3)
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                child: Text(
                                  '+${_myDoctors.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                      if (_myDoctors.isEmpty && !_loadingDoctors) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/patient/search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D9BF0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Find a Doctor',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMyDoctors() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MyDoctorsListPage(patientId: uid),
      ),
    );
  }

  // =========================================================
  // ✅ EMPTY STATE (KEEP FUNCTIONALITY)
  // =========================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: _fabGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _MedColors.blue.withOpacity(0.20),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              "Complétez votre profil",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _MedColors.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Vos informations améliorent l'expérience médicale et les suggestions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _MedColors.subText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/patient/onboarding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _MedColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Compléter maintenant",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== MEDICAL DOCUMENTS PAGE =====
class _MedicalDocumentsPage extends StatelessWidget {
  final String patientId;

  const _MedicalDocumentsPage({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // Catchy Green Gradient App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF10B981),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.folder_special_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Medical Documents',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Your medical reports & records',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('medicalReports')
                    .where('patientId', isEqualTo: patientId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('Error: ${snapshot.error}'),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Sort in memory instead of using orderBy to avoid index requirement
                  final sortedDocs = docs.toList();
                  sortedDocs.sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>)['createdAt']
                            as Timestamp?;
                    final bTime =
                        (b.data() as Map<String, dynamic>)['createdAt']
                            as Timestamp?;

                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;

                    return bTime.compareTo(aTime); // descending order
                  });

                  if (sortedDocs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: sortedDocs.map((doc) {
                      return _buildDocumentCard(context, doc);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.15),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Medical Documents Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your doctors will add medical reports\nand documents here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled Report';
    final content = data['content'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final reportType = data['reportType'] ?? 'General';
    final doctorName = data['doctorName'] ?? 'Doctor';
    final doctorSpecialty = data['doctorSpecialty'] ?? '';

    // Get report type color
    Color typeColor;
    IconData typeIcon;
    switch (reportType) {
      case 'Consultation':
        typeColor = const Color(0xFF3B82F6);
        typeIcon = Icons.medical_services_rounded;
        break;
      case 'Lab Results':
        typeColor = const Color(0xFFEF4444);
        typeIcon = Icons.science_rounded;
        break;
      case 'Imaging':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.camera_alt_rounded;
        break;
      case 'Prescription':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.medication_rounded;
        break;
      case 'Follow-up':
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.event_repeat_rounded;
        break;
      case 'Discharge Summary':
        typeColor = const Color(0xFF06B6D4);
        typeIcon = Icons.exit_to_app_rounded;
        break;
      default:
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.description_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDocumentDetails(context, data, createdAt),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [typeColor, typeColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(typeIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: typeColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              reportType,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (createdAt != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy').format(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. $doctorName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (doctorSpecialty.isNotEmpty)
                              Text(
                                doctorSpecialty,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
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

  void _showDocumentDetails(
    BuildContext context,
    Map<String, dynamic> data,
    DateTime? createdAt,
  ) {
    final title = data['title'] ?? 'Untitled Report';
    final content = data['content'] ?? '';
    final reportType = data['reportType'] ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              reportType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(createdAt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Report Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        content.isEmpty ? 'No content available' : content,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorLink {
  final String id;
  final String name;
  final String specialty;
  final String city;
  final String avatarInitial;

  _DoctorLink({
    required this.id,
    required this.name,
    required this.specialty,
    required this.city,
    required this.avatarInitial,
  });
}

// ========== MY DOCTORS LIST PAGE ==========
class _MyDoctorsListPage extends StatefulWidget {
  final String patientId;

  const _MyDoctorsListPage({required this.patientId});

  @override
  State<_MyDoctorsListPage> createState() => _MyDoctorsListPageState();
}

class _MyDoctorsListPageState extends State<_MyDoctorsListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1D9BF0),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('patientDoctors')
                          .doc(widget.patientId)
                          .collection('doctors')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'My Doctors',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$count ${count == 1 ? 'doctor' : 'doctors'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search doctors...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1D9BF0),
                      size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Doctors List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patientDoctors')
                .doc(widget.patientId)
                .collection('doctors')
                .orderBy('linkedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // Show loading only on first load
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              // Handle errors
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final filteredDocs = docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['doctorName'] ?? '')
                    .toString()
                    .toLowerCase();
                final specialty = (data['doctorSpecialty'] ?? '')
                    .toString()
                    .toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || specialty.contains(query);
              }).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: filteredDocs.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  docs.isEmpty
                                      ? 'No doctors yet'
                                      : 'No doctors found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (docs.isEmpty) ...[
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/patient/search');
                                    },
                                    icon: const Icon(Icons.search_rounded),
                                    label: const Text('Find a Doctor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D9BF0),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildDoctorCard(filteredDocs[index]),
                          childCount: filteredDocs.length,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['doctorName'] ?? 'Doctor';
    final specialty = data['doctorSpecialty'] ?? 'Specialist';
    final city = data['doctorCity'] ?? '';
    final doctorId = doc.id;

    final initials = name
        .toString()
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/patient/doctor/$doctorId'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D9BF0).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9BF0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              size: 12,
                              color: const Color(0xFF1D9BF0),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                specialty.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF1D9BF0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (city.toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city.toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Rating display with real-time updates
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('doctors')
                            .doc(doctorId)
                            .snapshots(),
                        builder: (context, docSnapshot) {
                          if (!docSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final doctorData =
                              docSnapshot.data!.data() as Map<String, dynamic>?;
                          final averageRating =
                              (doctorData?['averageRating'] ?? 0.0).toDouble();
                          final reviewCount = doctorData?['reviewCount'] ?? 0;

                          if (averageRating > 0) {
                            return Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($reviewCount avis)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Additional doctor details
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('doctors')
                            .doc(doctorId)
                            .get(),
                        builder: (context, docSnapshot) {
                          if (!docSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final doctorData =
                              docSnapshot.data!.data() as Map<String, dynamic>?;
                          final phone = doctorData?['phone'] ?? '';
                          final email = doctorData?['email'] ?? '';
                          final experience = doctorData?['experience'] ?? '';

                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (phone.toString().isNotEmpty)
                                _buildInfoChip(
                                  Icons.phone_outlined,
                                  phone.toString(),
                                  Colors.green,
                                ),
                              if (email.toString().isNotEmpty)
                                _buildInfoChip(
                                  Icons.email_outlined,
                                  email.toString(),
                                  Colors.blue,
                                ),
                              if (experience.toString().isNotEmpty)
                                _buildInfoChip(
                                  Icons.workspace_premium_rounded,
                                  '$experience years',
                                  Colors.orange,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PATIENT NOTIFICATIONS PAGE ==========
class _PatientNotificationsPage extends StatelessWidget {
  final String patientId;

  const _PatientNotificationsPage({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: patientId)
            .where('status', whereIn: ['PENDING', 'CONFIRMED'])
            .orderBy('startTime', descending: false)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final appointments = snapshot.data?.docs ?? [];
          final now = DateTime.now();
          final upcomingAppointments = appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final startTime = (data['startTime'] as Timestamp).toDate();
            return startTime.isAfter(now);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9BF0), Color(0xFF7C6CF2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D9BF0).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming Appointments',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${upcomingAppointments.length} appointment(s) scheduled',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notification Settings Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF7EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive notifications 24h and 2h before your appointments',
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Header
              const Text(
                'Your Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),

              // Appointments List
              if (upcomingAppointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...upcomingAppointments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  final doctorName = data['doctorName'] as String?;
                  final doctorId = data['doctorId'] as String;
                  final status = (data['status'] ?? 'PENDING')
                      .toString()
                      .toUpperCase();
                  final reason = data['reason'] as String?;

                  Color statusColor;
                  if (status == 'CONFIRMED') {
                    statusColor = const Color(0xFF10B981);
                  } else {
                    statusColor = const Color(0xFFF59E0B);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor,
                                  statusColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorName ??
                                      'Dr. ${doctorId.substring(0, 6)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'EEE, MMM d • HH:mm',
                                  ).format(startTime),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                if (reason != null && reason.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    reason,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ========== ALL MEDICATIONS PAGE ==========
class _AllMedicationsPage extends StatelessWidget {
  final String patientId;

  const _AllMedicationsPage({required this.patientId});

  Future<List<QueryDocumentSnapshot>> _getAllPatientMedications() async {
    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection('patientDoctors')
        .doc(patientId)
        .collection('doctors')
        .get();

    final List<QueryDocumentSnapshot> allMedications = [];

    for (final doctorDoc in doctorsSnapshot.docs) {
      final doctorId = doctorDoc.id;
      final medicationsSnapshot = await FirebaseFirestore.instance
          .collection('doctorPatients')
          .doc(doctorId)
          .collection('patients')
          .doc(patientId)
          .collection('medications')
          .orderBy('prescribedAt', descending: true)
          .get();

      allMedications.addAll(medicationsSnapshot.docs);
    }

    allMedications.sort((a, b) {
      final aTime =
          (a.data() as Map<String, dynamic>)['prescribedAt'] as Timestamp?;
      final bTime =
          (b.data() as Map<String, dynamic>)['prescribedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return allMedications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Medications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _getAllPatientMedications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final medications = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Medications',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${medications.length} prescription(s)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (medications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No medications prescribed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...medications.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final dosage = data['dosage'] ?? '';
                  final frequency = data['frequency'] ?? '';
                  final duration = data['duration'] ?? '';
                  final instructions = data['instructions'] ?? '';
                  final prescribedByName = data['prescribedByName'] ?? 'Doctor';
                  final prescribedAt = (data['prescribedAt'] as Timestamp?)
                      ?.toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    if (dosage.isNotEmpty)
                                      Text(
                                        dosage,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (frequency.isNotEmpty || duration.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  if (frequency.isNotEmpty) ...[
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      frequency,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (frequency.isNotEmpty &&
                                      duration.isNotEmpty)
                                    const SizedBox(width: 16),
                                  if (duration.isNotEmpty) ...[
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      duration,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (instructions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              instructions,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[200]),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. $prescribedByName',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (prescribedAt != null)
                                      Text(
                                        DateFormat(
                                          'MMM d, yyyy',
                                        ).format(prescribedAt),
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
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ========== MEDICATION DETAIL PAGE ==========
class _MedicationDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicationData;
  final String medicationId;

  const _MedicationDetailPage({
    required this.medicationData,
    required this.medicationId,
  });

  @override
  Widget build(BuildContext context) {
    final name = medicationData['name'] ?? 'Unknown';
    final dosage = medicationData['dosage'] ?? '';
    final frequency = medicationData['frequency'] ?? '';
    final duration = medicationData['duration'] ?? '';
    final instructions = medicationData['instructions'] ?? '';
    final prescribedByName = medicationData['prescribedByName'] ?? 'Doctor';
    final prescribedAt = (medicationData['prescribedAt'] as Timestamp?)
        ?.toDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medication Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () {
              _showReminderDialog(context, name);
            },
            tooltip: 'Set Reminder',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (dosage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      dosage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dosage Information
            _buildInfoCard(
              icon: Icons.local_pharmacy_rounded,
              title: 'Dosage & Frequency',
              children: [
                if (frequency.isNotEmpty)
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Frequency',
                    frequency,
                  ),
                if (duration.isNotEmpty)
                  _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'Duration',
                    duration,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions
            if (instructions.isNotEmpty) ...[
              _buildInfoCard(
                icon: Icons.description_rounded,
                title: 'Instructions',
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      instructions,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Doctor Information
            _buildInfoCard(
              icon: Icons.person_rounded,
              title: 'Prescribed By',
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prescribedByName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (prescribedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Prescribed on ${DateFormat('MMMM d, yyyy').format(prescribedAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reminder Notice
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alarm_rounded,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set Reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the bell icon to set medication reminders',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context, String medicationName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Set Reminder',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a reminder for:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              medicationName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _reminderOption(Icons.wb_sunny_rounded, 'Morning', '8:00 AM'),
                  const SizedBox(height: 12),
                  _reminderOption(
                    Icons.light_mode_rounded,
                    'Afternoon',
                    '2:00 PM',
                  ),
                  const SizedBox(height: 12),
                  _reminderOption(
                    Icons.nightlight_rounded,
                    'Evening',
                    '8:00 PM',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Reminder set for $medicationName')),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Set Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _reminderOption(IconData icon, String time, String timeValue) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Text(
          timeValue,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
