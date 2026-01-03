import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:meddoc/shared/services/auth_onboarding_service.dart';

/// Doctor Profile View Screen - Read-only profile display
///
/// Displays:
/// - Profile photo
/// - Basic info (name, specialty, clinic)
/// - Contact info
/// - Languages
/// - Consultation modes
/// - Pricing
/// - Action button to edit profile
class DoctorProfileViewScreen extends ConsumerStatefulWidget {
  const DoctorProfileViewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorProfileViewScreen> createState() =>
      _DoctorProfileViewScreenState();
}

class _DoctorProfileViewScreenState
    extends ConsumerState<DoctorProfileViewScreen> {
  late Map<String, dynamic> _doctorData = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No authenticated user');

      final onboarding = AuthOnboardingService();
      final doctorDoc = await onboarding.getDoctorDoc(uid);

      if (doctorDoc == null) {
        throw Exception('Doctor profile not found');
      }

      if (mounted) {
        setState(() {
          _doctorData = doctorDoc;
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading profile: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _doctorData['fullName'] as String? ?? 'Dr. Unknown';
    final specialtyName =
        _doctorData['specialtyName'] as String? ?? 'Specialty not specified';
    final bio = _doctorData['bio'] as String?;
    final clinicData = _doctorData['clinic'] as Map<String, dynamic>? ?? {};
    final contactsData = _doctorData['contacts'] as Map<String, dynamic>? ?? {};
    final languages = (_doctorData['languages'] as List?)?.cast<String>() ?? [];
    final acceptingNewPatients =
        _doctorData['acceptingNewPatients'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/doctor/edit-profile'),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile header
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile photo placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialtyName,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  if (acceptingNewPatients) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Accepting New Patients',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bio section
                  if (bio != null && bio.isNotEmpty) ...[
                    _SectionTitle('About'),
                    const SizedBox(height: 8),
                    Text(bio, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                  ],

                  // Contact information
                  _SectionTitle('Contact Information'),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: contactsData['phone'] as String? ?? 'Not provided',
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: contactsData['email'] as String? ?? 'Not provided',
                  ),
                  const SizedBox(height: 24),

                  // Clinic information
                  if (clinicData.isNotEmpty) ...[
                    _SectionTitle('Clinic Details'),
                    const SizedBox(height: 12),
                    if (clinicData['name'] != null)
                      _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'Clinic Name',
                        value: clinicData['name'] as String,
                      ),
                    if (clinicData['name'] != null) const SizedBox(height: 8),
                    if (clinicData['city'] != null)
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: clinicData['city'] as String,
                      ),
                    if (clinicData['city'] != null) const SizedBox(height: 24),
                  ],

                  // Languages
                  if (languages.isNotEmpty) ...[
                    _SectionTitle('Languages'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages
                          .map(
                            (lang) => Chip(
                              label: Text(lang),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Edit profile button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: () => context.go('/doctor/edit-profile'),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
