import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';

import '../../../app/theme_config.dart';
import '../data/doctor_search_datasource.dart';
import '../domain/entities/doctor.dart';
import '../../agenda/data/models/availability_slot.dart';
import '../../../shared/pages/chat_page.dart';

final _datasourceProvider = Provider((ref) => DoctorSearchDatasource());

final _doctorProvider = StreamProvider.family<Doctor?, String>((ref, doctorId) {
  return FirebaseFirestore.instance
      .collection('doctors')
      .doc(doctorId)
      .snapshots()
      .asyncMap((snapshot) async {
        if (!snapshot.exists) return null;

        final datasource = ref.watch(_datasourceProvider);
        return datasource.getDoctorById(doctorId);
      });
});

final doctorSlotsProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlot>, String>((ref, doctorId) async {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('slots')
          .where('status', isEqualTo: 'AVAILABLE')
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startTime')
          .limit(20)
          .get();
      return snapshot.docs
          .map((d) => AvailabilitySlot.fromFirestore(d))
          .toList();
    });

/// ✅ Premium Medical UI constants
const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E8F0);

const _primary = Color(0xFF2D9CDB);
const _primaryDark = Color(0xFF1B6CA8);

const _text = Color(0xFF0F172A);
const _subText = Color(0xFF475569);
const _disabled = Color(0xFF94A3B8);

final _cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
];

class DoctorDetailPage extends ConsumerStatefulWidget {
  final String doctorId;
  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends ConsumerState<DoctorDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  int? _uniquePatientCount;
  Position? _userLocation;
  GoogleMapController? _mapController;
  fm.MapController? _flutterMapController;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _fetchUniquePatientCount();
    _flutterMapController = fm.MapController();
    _getUserLocation();
  }

  /// Fetch the real number of unique patients from appointments
  Future<void> _fetchUniquePatientCount() async {
    try {
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('status', whereIn: ['completed', 'confirmed'])
          .get();

      // Get unique patient IDs
      final uniquePatientIds = <String>{};
      for (final doc in appointmentsSnapshot.docs) {
        final patientId = doc.data()['patientId'];
        if (patientId != null) {
          uniquePatientIds.add(patientId as String);
        }
      }

      if (mounted) {
        setState(() {
          _uniquePatientCount = uniquePatientIds.length;
        });
      }
    } catch (e) {
      // If error, fall back to completedAppointments
      if (mounted) {
        setState(() {
          _uniquePatientCount = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _flutterMapController?.dispose();
    super.dispose();
  }

  /// Get user's current location
  Future<void> _getUserLocation() async {
    if (!mounted) return;

    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(_doctorProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: _bg,
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return const Center(child: Text('Practitioner not found'));
          }
          return _buildDoctorDetail(doctor);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildDoctorDetail(Doctor doctor) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(doctor),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(doctor),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildTabContent(doctor),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Premium AppBar (Hero, glass buttons)
  Widget _buildAppBar(Doctor doctor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: _surface,
      leading: _glassIconButton(
        icon: Icons.arrow_back_ios_new,
        onTap: () => context.pop(),
      ),
      actions: [
        _glassIconButton(icon: Icons.share_outlined, onTap: () {}),
        _glassIconButton(icon: Icons.favorite_border, onTap: () {}),
        const SizedBox(width: 10),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'doctor_${doctor.id}',
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: doctor.profile.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(doctor.profile.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: doctor.profile.photoUrl == null
                            ? Center(
                                child: Text(
                                  _initials(doctor),
                                  style: const TextStyle(
                                    color: _primaryDark,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (doctor.specialty.name.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Text(
                          doctor.specialty.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
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
  }

  /// ✅ Profile header with premium stats + actions
  Widget _buildProfileHeader(Doctor doctor) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doctor.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
              if (doctor.searchMetadata.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _primary.withOpacity(0.22)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 18, color: _primary),
                      SizedBox(width: 6),
                      Text(
                        "Verified",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            doctor.specialty.name.isNotEmpty
                ? doctor.specialty.name
                : "Specialty coming soon",
            style: const TextStyle(
              fontSize: 15,
              color: _subText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: _disabled,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  doctor.location.fullAddress.isNotEmpty
                      ? doctor.location.fullAddress
                      : "Address not provided",
                  style: const TextStyle(color: _subText, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  value: doctor.ratings.count > 0
                      ? doctor.ratings.average.toStringAsFixed(1)
                      : "New",
                  label: doctor.ratings.count > 0
                      ? "${doctor.ratings.count} avis"
                      : "No reviews yet",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.work_outline_rounded,
                  color: _primary,
                  value: "${doctor.statistics.experienceYears}",
                  label: "ans d’exp.",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.people_alt_outlined,
                  color: const Color(0xFF22C55E),
                  value: _uniquePatientCount != null
                      ? "$_uniquePatientCount"
                      : "${doctor.statistics.completedAppointments}",
                  label: "patients",
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          _buildQuickActions(doctor),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _subText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Doctor doctor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _bookAppointment(doctor),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Book Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _miniAction(Icons.phone_outlined, () => _callPhone(doctor.phone)),
        const SizedBox(width: 10),
        _miniAction(
          Icons.chat_bubble_outline,
          () => _startConversation(doctor),
        ),
      ],
    );
  }

  Widget _miniAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: _primary),
      ),
    );
  }

  /// ✅ Premium pill tabs
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: _cardShadow,
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _subText,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "About"),
            Tab(text: "Horaires"),
            Tab(text: "Avis"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Doctor doctor) {
    switch (_selectedTab) {
      case 0:
        return _buildAboutTab(doctor);
      case 1:
        return _buildScheduleTab(doctor);
      case 2:
        return _buildReviewsTab(doctor);
      default:
        return const SizedBox.shrink();
    }
  }

  /// ✅ About tab (premium section cards)
  Widget _buildAboutTab(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Presentation',
            Icons.person_outline,
            Text(
              doctor.profile.bio.isNotEmpty
                  ? doctor.profile.bio
                  : 'The practitioner will complete this section soon.',
              style: const TextStyle(
                fontSize: 14,
                color: _subText,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoCard(
            'Contact',
            Icons.call_outlined,
            Column(
              children: [
                _buildInfoRow(
                  Icons.email_outlined,
                  doctor.email.isNotEmpty ? doctor.email : "Email not provided",
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.phone_outlined,
                  doctor.phone.isNotEmpty ? doctor.phone : "Phone not provided",
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoCard(
            'Modes de consultation',
            Icons.health_and_safety_outlined,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: doctor.consultationModes.availableModes.map((mode) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _primary.withOpacity(0.22)),
                  ),
                  child: Text(
                    mode,
                    style: const TextStyle(
                      color: _primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoCard(
            'Tarifs',
            Icons.euro_rounded,
            Column(
              children: [
                _buildPriceRow(
                  'Consultation au cabinet',
                  '${doctor.pricing.inPersonFee.toStringAsFixed(0)}€',
                ),
                if (doctor.consultationModes.video) ...[
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Video Consultation',
                    '${doctor.pricing.videoFee.toStringAsFixed(0)}€',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildLocationCard(doctor),
        ],
      ),
    );
  }

  /// ✅ Schedule tab (same logic, better UI)
  Widget _buildScheduleTab(Doctor doctor) {
    final slotsAsync = ref.watch(doctorSlotsProvider(doctor.id));
    final dayLabel = DateFormat('EEEE d MMMM', 'fr_FR');
    final hourLabel = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: slotsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => _buildInfoCard(
          'Disponibilités',
          Icons.error_outline,
          Text('Erreur de chargement: $e'),
        ),
        data: (slots) {
          if (slots.isEmpty) {
            return _buildInfoCard(
              'Disponibilités',
              Icons.schedule_outlined,
              const Text(
                'No time slots available at the moment. Try again soon.',
                style: TextStyle(fontSize: 14, color: _subText),
              ),
            );
          }

          final grouped = <String, List<AvailabilitySlot>>{};
          for (final slot in slots) {
            final key = DateTime(
              slot.startTime.year,
              slot.startTime.month,
              slot.startTime.day,
            ).toIso8601String();
            grouped.putIfAbsent(key, () => []).add(slot);
          }

          final nextSlot = slots.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _primary.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Prochain créneau: ${hourLabel.format(nextSlot.startTime)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              ...grouped.entries.map((entry) {
                final dayDate = DateTime.parse(entry.key);
                final daySlots = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                    boxShadow: _cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayLabel.format(dayDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: daySlots.map((slot) {
                          final label =
                              '${hourLabel.format(slot.startTime)} - ${hourLabel.format(slot.endTime)}';

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _primary.withOpacity(0.20),
                              ),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: _primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// Call doctor's phone number
  Future<void> _callPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le composeur téléphonique'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _startConversation(Doctor doctor) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous pour envoyer un message.'),
          ),
        );
        context.push('/login');
      }
      return;
    }

    try {
      // Get patient name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(userId)
          .get();
      final patientName =
          patientDoc.data()?['name'] ?? userDoc.data()?['name'] ?? 'Patient';

      // Check if conversation already exists
      final existingConversation = await FirebaseFirestore.instance
          .collection('conversations')
          .where('doctorId', isEqualTo: doctor.id)
          .where('patientId', isEqualTo: userId)
          .limit(1)
          .get();

      String conversationId;
      if (existingConversation.docs.isNotEmpty) {
        conversationId = existingConversation.docs.first.id;
      } else {
        // Create new conversation
        final docRef = await FirebaseFirestore.instance
            .collection('conversations')
            .add({
              'doctorId': doctor.id,
              'doctorName': doctor.fullName,
              'patientId': userId,
              'patientName': patientName,
              'lastMessage': '',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'lastSenderId': '',
              'doctorUnreadCount': 0,
              'patientUnreadCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
            });
        conversationId = docRef.id;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId,
              otherPersonId: doctor.id,
              otherPersonName: doctor.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _bookAppointment(Doctor doctor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to book an appointment.'),
          ),
        );
        context.push('/login');
      }
      return;
    }

    try {
      // resolve patient display name from users collection
      String patientName = user.displayName ?? '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        if (data != null) {
          patientName = (data['name'] ?? data['fullName'] ?? patientName ?? '')
              .toString()
              .trim();
        }
      } catch (_) {}
      if (patientName.isEmpty) {
        patientName = user.email ?? user.uid;
      }

      final slots = await ref.read(doctorSlotsProvider(doctor.id).future);
      if (slots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun créneau disponible pour le moment.'),
            ),
          );
        }
        return;
      }

      final selected = await _showSlotPicker(slots);
      if (selected == null) return;

      final appointments = FirebaseFirestore.instance.collection(
        'appointments',
      );
      final slotRef = FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .collection('slots')
          .doc(selected.id);

      final patientDoctorRef = FirebaseFirestore.instance
          .collection('patientDoctors')
          .doc(user.uid)
          .collection('doctors')
          .doc(doctor.id);
      final doctorPatientRef = FirebaseFirestore.instance
          .collection('doctorPatients')
          .doc(doctor.id)
          .collection('patients')
          .doc(user.uid);

      final now = FieldValue.serverTimestamp();

      String? appointmentIdForNotification;
      final consultationType = selected.type == ConsultationType.inPerson
          ? 'in-person'
          : 'video';

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final aptRef = appointments.doc();
        appointmentIdForNotification = aptRef.id; // Store appointment ID

        txn.set(aptRef, {
          'doctorId': doctor.id,
          'doctorName': doctor.fullName,
          'doctorSpecialty': doctor.specialty.name,
          'doctorCity': doctor.location.city,
          'patientId': user.uid,
          'patientName': patientName,
          'slotId': selected.id,
          'startTime': Timestamp.fromDate(selected.startTime),
          'endTime': Timestamp.fromDate(selected.endTime),
          'mode': selected.type == ConsultationType.inPerson
              ? 'IN_PERSON'
              : 'VIDEO',
          'status': 'CONFIRMED',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        txn.update(slotRef, {
          'status': 'BOOKED',
          'patientId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Include link documents in the same transaction
        txn.set(patientDoctorRef, {
          'doctorId': doctor.id,
          'doctorName': doctor.fullName,
          'doctorSpecialty': doctor.specialty.name,
          'doctorCity': doctor.location.city,
          'linkedAt': now,
        }, SetOptions(merge: true));

        txn.set(doctorPatientRef, {
          'patientId': user.uid,
          'patientName': patientName,
          'lastAppointment': Timestamp.fromDate(selected.startTime),
          'lastStatus': 'CONFIRMED',
          'linkedAt': now,
        }, SetOptions(merge: true));

        // Create video consultation if it's a VIDEO appointment
        if (selected.type == ConsultationType.video) {
          final videoConsultRef = FirebaseFirestore.instance
              .collection('videoConsultations')
              .doc();
          txn.set(videoConsultRef, {
            'appointmentId': aptRef.id,
            'doctorId': doctor.id,
            'doctorName': doctor.fullName,
            'doctorSpecialty': doctor.specialty.name,
            'patientId': user.uid,
            'patientName': patientName,
            'scheduledTime': Timestamp.fromDate(selected.startTime),
            'endTime': Timestamp.fromDate(selected.endTime),
            'status': 'scheduled',
            'patientInWaitingRoom': false,
            'doctorReady': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Create notifications AFTER transaction completes
      // This avoids transaction limitations with cross-collection writes
      try {
        final notificationsRef = FirebaseFirestore.instance.collection(
          'notifications',
        );

        // 1. Immediate notification to doctor
        try {
          await notificationsRef.add({
            'recipientId': doctor.id,
            'type': 'new_appointment',
            'title': 'New Appointment Booked',
            'message':
                '$patientName has booked a $consultationType appointment on ${_formatDateTime(selected.startTime)}',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'appointmentTime': Timestamp.fromDate(selected.startTime),
            'patientName': patientName,
          });
        } catch (e) {
          print('Error creating doctor notification: $e');
        }

        // 2. Schedule patient reminders (1h, 30min, 15min, and 5min before)
        final oneHourBefore = selected.startTime.subtract(
          const Duration(hours: 1),
        );
        final thirtyMinsBefore = selected.startTime.subtract(
          const Duration(minutes: 30),
        );
        final fifteenMinsBefore = selected.startTime.subtract(
          const Duration(minutes: 15),
        );
        final fiveMinsBefore = selected.startTime.subtract(
          const Duration(minutes: 5),
        );
        final nowTime = DateTime.now();

        // 1 hour reminder
        if (oneHourBefore.isAfter(nowTime) &&
            appointmentIdForNotification != null) {
          try {
            await notificationsRef.add({
              'recipientId': user.uid,
              'type': 'appointment_reminder',
              'title': 'Appointment Reminder',
              'message':
                  'Your appointment with Dr. ${doctor.fullName} is in 1 hour at ${_formatTime(selected.startTime)}',
              'createdAt': FieldValue.serverTimestamp(),
              'scheduledFor': Timestamp.fromDate(oneHourBefore),
              'read': false,
              'sent': false,
              'appointmentId': appointmentIdForNotification!,
              'appointmentTime': Timestamp.fromDate(selected.startTime),
              'doctorName': doctor.fullName,
              'reminderType': '1_hour',
            });
            print(
              '✅ Created 1h reminder for ${_formatTime(selected.startTime)} (scheduled: ${oneHourBefore.toString()})',
            );
          } catch (e) {
            print('Error creating 1h reminder: $e');
          }
        } else {
          print(
            '⏭️ Skipped 1h reminder (time already passed or no appointmentId)',
          );
        }

        // 30 minutes reminder
        if (thirtyMinsBefore.isAfter(nowTime) &&
            appointmentIdForNotification != null) {
          try {
            await notificationsRef.add({
              'recipientId': user.uid,
              'type': 'appointment_reminder',
              'title': 'Appointment Reminder',
              'message':
                  'Your appointment with Dr. ${doctor.fullName} is in 30 minutes at ${_formatTime(selected.startTime)}',
              'createdAt': FieldValue.serverTimestamp(),
              'scheduledFor': Timestamp.fromDate(thirtyMinsBefore),
              'read': false,
              'sent': false,
              'appointmentId': appointmentIdForNotification!,
              'appointmentTime': Timestamp.fromDate(selected.startTime),
              'doctorName': doctor.fullName,
              'reminderType': '30_minutes',
            });
            print(
              '✅ Created 30min reminder (scheduled: ${thirtyMinsBefore.toString()})',
            );
          } catch (e) {
            print('Error creating 30min reminder: $e');
          }
        } else {
          print('⏭️ Skipped 30min reminder (time already passed)');
        }

        // 15 minutes reminder
        if (fifteenMinsBefore.isAfter(nowTime) &&
            appointmentIdForNotification != null) {
          try {
            await notificationsRef.add({
              'recipientId': user.uid,
              'type': 'appointment_reminder',
              'title': 'Appointment Reminder',
              'message':
                  'Your appointment with Dr. ${doctor.fullName} is in 15 minutes at ${_formatTime(selected.startTime)}',
              'createdAt': FieldValue.serverTimestamp(),
              'scheduledFor': Timestamp.fromDate(fifteenMinsBefore),
              'read': false,
              'sent': false,
              'appointmentId': appointmentIdForNotification!,
              'appointmentTime': Timestamp.fromDate(selected.startTime),
              'doctorName': doctor.fullName,
              'reminderType': '15_minutes',
            });
            print(
              '✅ Created 15min reminder (scheduled: ${fifteenMinsBefore.toString()})',
            );
          } catch (e) {
            print('Error creating 15min reminder: $e');
          }
        } else {
          print('⏭️ Skipped 15min reminder (time already passed)');
        }

        // 5 minutes reminder
        if (fiveMinsBefore.isAfter(nowTime) &&
            appointmentIdForNotification != null) {
          try {
            await notificationsRef.add({
              'recipientId': user.uid,
              'type': 'appointment_reminder',
              'title': 'Appointment Reminder',
              'message':
                  'Your appointment with Dr. ${doctor.fullName} is starting in 5 minutes at ${_formatTime(selected.startTime)}',
              'createdAt': FieldValue.serverTimestamp(),
              'scheduledFor': Timestamp.fromDate(fiveMinsBefore),
              'read': false,
              'sent': false,
              'appointmentId': appointmentIdForNotification!,
              'appointmentTime': Timestamp.fromDate(selected.startTime),
              'doctorName': doctor.fullName,
              'reminderType': '5_minutes',
            });
            print(
              '✅ Created 5min reminder (scheduled: ${fiveMinsBefore.toString()})',
            );
          } catch (e) {
            print('Error creating 5min reminder: $e');
          }
        } else {
          print('⏭️ Skipped 5min reminder (time already passed)');
        }
      } catch (notifError) {
        // Log but don't fail the booking if notifications fail
        print('Warning: Could not create notifications: $notifError');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment confirmed.')));
        ref.invalidate(doctorSlotsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de réservation: $e')));
      }
    }
  }

  Future<AvailabilitySlot?> _showSlotPicker(List<AvailabilitySlot> slots) {
    final hour = DateFormat('HH:mm');
    return showModalBottomSheet<AvailabilitySlot>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final slot = slots[i];
            final label =
                '${hour.format(slot.startTime)} - ${hour.format(slot.endTime)}';
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _primary.withOpacity(0.2)),
              ),
              leading: const Icon(Icons.schedule, color: _primary),
              title: Text(label),
              subtitle: Text(
                slot.type == ConsultationType.inPerson
                    ? 'Au cabinet'
                    : 'Téléconsultation',
              ),
              onTap: () => Navigator.pop(context, slot),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: slots.length,
        ),
      ),
    );
  }

  /// Format DateTime for notification display
  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month $day at $hour:$minute';
  }

  /// Format time only for notification display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// ✅ Reviews tab with real data and add review button
  Widget _buildReviewsTab(Doctor doctor) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data?.docs ?? [];
        final average = _calculateAverageRating(reviews);
        final count = reviews.length;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                "Avis patients",
                Icons.star_rounded,
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      count > 0
                          ? "${average.toStringAsFixed(1)}  •  $count avis"
                          : "Aucun avis",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Add Review Button
              if (userId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddReviewDialog(doctor),
                    icon: const Icon(Icons.add_comment_rounded),
                    label: const Text('Laisser un avis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // Reviews List
              if (reviews.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun avis pour le moment',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...reviews.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final patientId = data['patientId'] ?? '';
                  final isOwnReview = patientId == userId;
                  final patientName = data['patientName'] ?? 'Patient';
                  final rating = (data['rating'] ?? 0.0).toDouble();
                  final comment = data['comment'] ?? '';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                      boxShadow: _cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _primary.withOpacity(0.12),
                              child: Text(
                                patientName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _text,
                                    ),
                                  ),
                                  if (createdAt != null)
                                    Text(
                                      DateFormat(
                                        'd MMM yyyy',
                                        'fr_FR',
                                      ).format(createdAt),
                                      style: const TextStyle(
                                        color: _subText,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildStarRating(rating),
                            if (isOwnReview) ...[
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditReviewDialog(
                                      doctor,
                                      doc.id,
                                      rating,
                                      comment,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteReview(doctor, doc.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Modifier'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Supprimer',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            comment,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  double _calculateAverageRating(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) return 0.0;

    double total = 0.0;
    for (final doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['rating'] ?? 0.0).toDouble();
    }

    return total / reviews.length;
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800, color: _text),
        ),
      ],
    );
  }

  Future<void> _showAddReviewDialog(Doctor doctor) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Check if user already reviewed
    final existingReview = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctor.id)
        .collection('reviews')
        .where('patientId', isEqualTo: userId)
        .get();

    if (existingReview.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez déjà laissé un avis')),
        );
      }
      return;
    }

    double selectedRating = 5.0;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.amber.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and gradient background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFCD34D),
                        Color(0xFFF59E0B),
                        Color(0xFFD97706),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Évaluez votre expérience',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.15),
                        Colors.orange.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Dr. ${doctor.fullName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Rating stars with enhanced design
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.08),
                        Colors.orange.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Votre évaluation',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedRating = index + 1.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: AnimatedScale(
                                scale: index < selectedRating ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: index < selectedRating
                                      ? BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        )
                                      : null,
                                  child: Icon(
                                    index < selectedRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: index < selectedRating
                                        ? const Color(0xFFF59E0B)
                                        : Colors.grey[400],
                                    size: 46,
                                    shadows: index < selectedRating
                                        ? [
                                            Shadow(
                                              color: const Color(
                                                0xFFF59E0B,
                                              ).withOpacity(0.6),
                                              blurRadius: 12,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFCD34D).withOpacity(0.2),
                              const Color(0xFFF59E0B).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedRating == 5.0
                              ? '🌟 Excellent!'
                              : selectedRating == 4.0
                              ? '😊 Très bien!'
                              : selectedRating == 3.0
                              ? '👍 Bien'
                              : selectedRating == 2.0
                              ? '😐 Moyen'
                              : '😕 Insatisfait',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comment field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre commentaire (optionnel)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons with enhanced design
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          backgroundColor: Colors.grey[50],
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Publier l\'avis',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        // Get patient name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(userId)
            .get();

        final patientName =
            patientDoc.data()?['name'] ?? userDoc.data()?['name'] ?? 'Patient';

        // Save review
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctor.id)
            .collection('reviews')
            .add({
              'patientId': userId,
              'patientName': patientName,
              'rating': selectedRating,
              'comment': commentController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Update doctor's average rating
        await _updateDoctorAverageRating(doctor.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Merci pour votre avis!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  Future<void> _updateDoctorAverageRating(String doctorId) async {
    final reviews = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .collection('reviews')
        .get();

    if (reviews.docs.isEmpty) return;

    double total = 0.0;
    for (final doc in reviews.docs) {
      total += (doc.data()['rating'] ?? 0.0).toDouble();
    }

    final average = total / reviews.docs.length;

    await FirebaseFirestore.instance.collection('doctors').doc(doctorId).update(
      {'averageRating': average, 'reviewCount': reviews.docs.length},
    );
  }

  /// ✅ Premium section card
  Widget _buildInfoCard(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _disabled),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _subText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _subText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _primaryDark,
          ),
        ),
      ],
    );
  }

  /// ✅ glass icon button for appbar
  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // Edit review dialog
  Future<void> _showEditReviewDialog(
    Doctor doctor,
    String reviewId,
    double currentRating,
    String currentComment,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    double selectedRating = currentRating;
    final commentController = TextEditingController(text: currentComment);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier votre avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre note:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        // Update review
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctor.id)
            .collection('reviews')
            .doc(reviewId)
            .update({
              'rating': selectedRating,
              'comment': commentController.text.trim(),
            });

        // Update doctor's average rating
        await _updateDoctorAverageRating(doctor.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis mis à jour!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  // Delete review
  Future<void> _deleteReview(Doctor doctor, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet avis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctor.id)
            .collection('reviews')
            .doc(reviewId)
            .delete();

        // Update doctor's average rating
        await _updateDoctorAverageRating(doctor.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis supprimé!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  String _initials(Doctor doctor) {
    final first = doctor.firstName.isNotEmpty ? doctor.firstName[0] : '';
    final last = doctor.lastName.isNotEmpty ? doctor.lastName[0] : '';
    final combo = '$first$last';
    return combo.isNotEmpty ? combo.toUpperCase() : '?';
  }

  /// 🗺️ Location card with map and directions
  Widget _buildLocationCard(Doctor doctor) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
          // Map preview with web-friendly fallback
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildMapPreview(doctor),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: _disabled,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor.location.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_city_outlined,
                      size: 18,
                      color: _disabled,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${doctor.location.postalCode} ${doctor.location.city}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(
                  doctor.location.coordinates.latitude,
                  doctor.location.coordinates.longitude,
                  doctor.fullName,
                ),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Obtenir l\'itinéraire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(Doctor doctor) {
    final lat = doctor.location.coordinates.latitude;
    final lng = doctor.location.coordinates.longitude;

    // Guard: if coordinates are missing or invalid, show a friendly message
    final hasCoords = lat.abs() > 0.0001 && lng.abs() > 0.0001;
    if (!hasCoords) {
      return Container(
        height: 250,
        color: const Color(0xFFF1F5F9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: _disabled),
              const SizedBox(height: 12),
              const Text(
                'Localisation indisponible',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  doctor.location.fullAddress,
                  style: const TextStyle(color: _subText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      // Interactive OpenStreetMap view for web
      return Stack(
        children: [
          fm.FlutterMap(
            key: ValueKey('map_${doctor.id}_${lat}_${lng}'),
            mapController: _flutterMapController,
            options: fm.MapOptions(
              initialCenter: latlng.LatLng(lat, lng),
              initialZoom: 15,
              interactionOptions: const fm.InteractionOptions(
                flags: fm.InteractiveFlag.pinchZoom | fm.InteractiveFlag.drag,
              ),
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'meddoc',
              ),
              fm.MarkerLayer(
                markers: [
                  // Doctor location marker
                  fm.Marker(
                    point: latlng.LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.location_on,
                      color: _primary,
                      size: 34,
                    ),
                  ),
                  // User location marker
                  if (_userLocation != null)
                    fm.Marker(
                      point: latlng.LatLng(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Loading indicator for location
          if (_isLoadingLocation)
            Positioned(
              left: 12,
              bottom: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_primary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Localisation...',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // My location button
          if (_userLocation != null)
            Positioned(
              left: 12,
              bottom: 60,
              child: InkWell(
                onTap: () {
                  if (_userLocation != null && _flutterMapController != null) {
                    _flutterMapController!.move(
                      latlng.LatLng(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                      ),
                      15,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    size: 20,
                    color: _primary,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  color: _subText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: InkWell(
              onTap: () => _openInMaps(lat, lng, doctor.fullName),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: _primary),
                    SizedBox(width: 6),
                    Text(
                      'Ouvrir dans Maps',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GoogleMap(
      key: ValueKey('gmap_${doctor.id}_${lat}_${lng}'),
      initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
      markers: {
        // Doctor location marker
        Marker(
          markerId: MarkerId(doctor.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: doctor.fullName,
            snippet: doctor.location.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
        // User location marker
        if (_userLocation != null)
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
            infoWindow: const InfoWindow(title: 'Ma position'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
      },
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      compassEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        debugPrint('Map loaded successfully');
      },
    );
  }

  /// Open location in Google Maps or Apple Maps
  Future<void> _openInMaps(
    double latitude,
    double longitude,
    String label,
  ) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la carte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
