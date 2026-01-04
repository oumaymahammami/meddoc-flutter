import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

/// Doctor Edit Profile Screen - Premium Design
/// Real edit functionality for doctor profile data
class DoctorEditProfileScreen extends StatefulWidget {
  final String? uid;

  const DoctorEditProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  late Map<String, dynamic> _doctorData = {};

  // Form Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _specialtyController;
  late TextEditingController _phoneController;
  late TextEditingController _clinicNumberController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _clinicCityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _priceInPersonController;
  late TextEditingController _priceVideoController;

  bool _acceptInPerson = true;
  bool _acceptVideo = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _initializeControllers();
    _loadDoctorProfile();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
    _specialtyController = TextEditingController();
    _phoneController = TextEditingController();
    _clinicNumberController = TextEditingController();
    _clinicAddressController = TextEditingController();
    _clinicCityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _priceInPersonController = TextEditingController();
    _priceVideoController = TextEditingController();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();
      final profile = doc.data();
      setState(() {
        _doctorData = profile ?? {};
        _populateControllers();
        _loading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _loading = false;
      });
    }
  }

  void _populateControllers() {
    // Build full name from firstName and lastName
    final firstName = _doctorData['firstName'] ?? '';
    final lastName = _doctorData['lastName'] ?? '';
    _fullNameController.text = '$firstName $lastName'.trim();

    _bioController.text = _doctorData['bio'] ?? '';

    // Get specialty name from specialty object or fallback to string field
    if (_doctorData['specialty'] is Map) {
      _specialtyController.text = _doctorData['specialty']['name'] ?? '';
    } else {
      _specialtyController.text =
          _doctorData['specialtyName'] ?? _doctorData['specialty'] ?? '';
    }

    _phoneController.text = _doctorData['phone'] ?? '';
    _clinicNumberController.text = _doctorData['clinicNumber'] ?? '';

    // Get address from location object or fallback to string fields
    if (_doctorData['location'] is Map) {
      final location = _doctorData['location'] as Map<String, dynamic>;
      _clinicAddressController.text = location['address'] ?? '';
      _clinicCityController.text = location['city'] ?? '';
      _postalCodeController.text = location['postalCode'] ?? '';
    } else {
      _clinicAddressController.text = _doctorData['clinicAddress'] ?? '';
      _clinicCityController.text = _doctorData['clinicCity'] ?? '';
      _postalCodeController.text = _doctorData['clinicPostalCode'] ?? '';
    }

    // Get pricing
    if (_doctorData['pricing'] is Map) {
      final pricing = _doctorData['pricing'] as Map<String, dynamic>;
      _priceInPersonController.text = (pricing['inPerson'] ?? 0).toString();
      _priceVideoController.text = (pricing['video'] ?? 0).toString();
    } else {
      _priceInPersonController.text = (_doctorData['priceInPerson'] ?? 0)
          .toString();
      _priceVideoController.text = (_doctorData['priceVideo'] ?? 0).toString();
    }

    // Get consultation modes
    if (_doctorData['consultationModes'] is Map) {
      final modes = _doctorData['consultationModes'] as Map<String, dynamic>;
      _acceptInPerson = modes['inPerson'] ?? true;
      _acceptVideo = modes['video'] ?? true;
    } else {
      _acceptInPerson = _doctorData['acceptInPerson'] ?? true;
      _acceptVideo = _doctorData['acceptVideo'] ?? true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _clinicNumberController.dispose();
    _clinicAddressController.dispose();
    _clinicCityController.dispose();
    _postalCodeController.dispose();
    _priceInPersonController.dispose();
    _priceVideoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Split full name into first and last name
      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Get current doctor data to preserve existing nested object structure
      final currentDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();

      // If document doesn't exist, we'll create it with basic structure
      final currentData = currentDoc.exists ? (currentDoc.data() ?? {}) : {};

      // Preserve existing specialty object structure
      final currentSpecialty = currentData['specialty'] is Map
          ? Map<String, dynamic>.from(currentData['specialty'])
          : {};
      currentSpecialty['name'] = _specialtyController.text;

      // Preserve existing location object structure
      final currentLocation = currentData['location'] is Map
          ? Map<String, dynamic>.from(currentData['location'])
          : {};
      currentLocation['address'] = _clinicAddressController.text;
      currentLocation['city'] = _clinicCityController.text;
      if (_postalCodeController.text.isNotEmpty) {
        currentLocation['postalCode'] = _postalCodeController.text;
      }

      // Ensure coordinates are preserved - critical for map functionality
      if (!currentLocation.containsKey('coordinates') ||
          currentLocation['coordinates'] == null ||
          (currentLocation['coordinates'] is Map &&
              (currentLocation['coordinates']['latitude'] == null ||
                  currentLocation['coordinates']['longitude'] == null ||
                  currentLocation['coordinates']['latitude'] == 0 ||
                  currentLocation['coordinates']['longitude'] == 0))) {
        // Set default coordinates based on city for Tunisia
        // TODO: Implement proper geocoding service to get accurate coordinates from address
        Map<String, double> defaultCoords = {
          'latitude': 36.8065, // Default to Tunis
          'longitude': 10.1815,
        };

        // City-specific coordinates for major Tunisian cities
        final city = _clinicCityController.text.toLowerCase();
        if (city.contains('tunis')) {
          defaultCoords = {'latitude': 36.8065, 'longitude': 10.1815};
        } else if (city.contains('sfax')) {
          defaultCoords = {'latitude': 34.7406, 'longitude': 10.7603};
        } else if (city.contains('sousse')) {
          defaultCoords = {'latitude': 35.8256, 'longitude': 10.6369};
        } else if (city.contains('kairouan')) {
          defaultCoords = {'latitude': 35.6781, 'longitude': 10.0963};
        } else if (city.contains('bizerte')) {
          defaultCoords = {'latitude': 37.2746, 'longitude': 9.8739};
        } else if (city.contains('gabès') || city.contains('gabes')) {
          defaultCoords = {'latitude': 33.8815, 'longitude': 10.0982};
        } else if (city.contains('ariana')) {
          defaultCoords = {'latitude': 36.8625, 'longitude': 10.1956};
        } else if (city.contains('monastir')) {
          defaultCoords = {'latitude': 35.7772, 'longitude': 10.8267};
        } else if (city.contains('ben arous')) {
          defaultCoords = {'latitude': 36.7525, 'longitude': 10.2175};
        } else if (city.contains('manouba')) {
          defaultCoords = {'latitude': 36.8081, 'longitude': 10.0965};
        }

        currentLocation['coordinates'] = defaultCoords;
        print(
          'Setting default coordinates for ${_clinicCityController.text}: $defaultCoords',
        );
      }

      // Preserve existing consultation modes object structure
      final currentModes = currentData['consultationModes'] is Map
          ? Map<String, dynamic>.from(currentData['consultationModes'])
          : {};
      currentModes['inPerson'] = _acceptInPerson;
      currentModes['video'] = _acceptVideo;

      // Preserve existing pricing object structure
      final currentPricing = currentData['pricing'] is Map
          ? Map<String, dynamic>.from(currentData['pricing'])
          : {};
      currentPricing['inPerson'] =
          _acceptInPerson && _priceInPersonController.text.isNotEmpty
          ? double.tryParse(_priceInPersonController.text)
          : null;
      currentPricing['video'] =
          _acceptVideo && _priceVideoController.text.isNotEmpty
          ? double.tryParse(_priceVideoController.text)
          : null;
      currentPricing['currency'] = 'TND';

      // Update with complete objects to avoid breaking nested structure
      // Use set with merge to create document if it doesn't exist
      final updateData = {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName, // Add fullName for easier querying
        'bio': _bioController.text.isEmpty ? null : _bioController.text,
        'phone': _phoneController.text,
        'specialty': currentSpecialty,
        'location': currentLocation,
        'consultationModes': currentModes,
        'pricing': currentPricing,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If creating new document, add createdAt and verified fields
      if (!currentDoc.exists) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['verified'] = false;
        updateData['averageRating'] = 0.0;
        updateData['reviewCount'] = 0;
      }

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      // Update doctor name in all appointments if name changed
      if (fullName != (currentData['fullName'] ?? '')) {
        final appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: uid)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in appointmentsSnapshot.docs) {
          batch.update(doc.reference, {'doctorName': fullName});
        }

        // Commit batch update
        if (appointmentsSnapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }

      setState(() {
        _successMessage = 'Profile updated successfully!';
        _saving = false;
      });

      // Navigate back after 1.5 seconds
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/doctor/dashboard');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving profile: $e';
        _saving = false;
      });
    }
  }

  bool _validateForm() {
    return _fullNameController.text.isNotEmpty &&
        _specialtyController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _clinicAddressController.text.isNotEmpty &&
        _clinicCityController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E63D9).withOpacity(0.8),
                      const Color(0xFF8B5CF6).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildProfessionalSection(),
                const SizedBox(height: 24),
                _buildClinicSection(),
                const SizedBox(height: 24),
                _buildServicesSection(),
                const SizedBox(height: 28),
                _buildSaveButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildSuccessMessage(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => context.go('/doctor/dashboard'),
          borderRadius: BorderRadius.circular(8),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ),
      ),
      title: const Text(
        'Edit Your Profile',
        style: TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E63D9).withOpacity(0.95),
            const Color(0xFF8B5CF6).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E63D9).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Your Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your profile up-to-date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E63D9).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E63D9).withOpacity(0.15),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF2E63D9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Basic Information',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Dr. John Doe',
            icon: Icons.person_outline,
            required: true,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _specialtyController,
            label: 'Medical Specialty',
            hint: 'Cardiology, Dentistry, etc.',
            icon: Icons.medical_services_outlined,
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.15),
                      const Color(0xFF2E63D9).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.phone_in_talk_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Professional Details',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+216 XX XXX XXXX',
            icon: Icons.phone_outlined,
            required: true,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _bioController,
            label: 'Professional Bio',
            hint: 'Tell patients about yourself...',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.15),
                      const Color(0xFF059669).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Clinic Information',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: _clinicNumberController,
            label: 'Cabinet Number',
            hint: 'E.g., 101 or Room A',
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _clinicAddressController,
            label: 'Address',
            hint: '123 Medical Avenue',
            icon: Icons.location_on_outlined,
            required: true,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _clinicCityController,
                  label: 'City',
                  hint: 'Tunis',
                  icon: Icons.location_city_outlined,
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: '1001',
                  icon: Icons.mail_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.15),
                      const Color(0xFFF97316).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Consultation Services',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildServiceToggle(
            'In-Person Consultations',
            'Patients can visit your clinic',
            _acceptInPerson,
            (value) => setState(() => _acceptInPerson = value),
            Icons.location_on_outlined,
          ),
          if (_acceptInPerson) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildTextField(
                controller: _priceInPersonController,
                label: 'Price (TND)',
                hint: '0.00',
                icon: Icons.attach_money,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildServiceToggle(
            'Video Consultations',
            'Offer remote consultations',
            _acceptVideo,
            (value) => setState(() => _acceptVideo = value),
            Icons.video_call_outlined,
          ),
          if (_acceptVideo) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildTextField(
                controller: _priceVideoController,
                label: 'Price (TND)',
                hint: '0.00',
                icon: Icons.attach_money,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF2E63D9).withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF2E63D9).withOpacity(0.2)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF2E63D9).withOpacity(0.1)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF2E63D9) : const Color(0xFF6B7280),
              size: 20,
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
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E63D9),
            inactiveThumbColor: const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFF2E63D9), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E63D9),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E63D9).withOpacity(_saving ? 0.7 : 0.95),
            const Color(0xFF8B5CF6).withOpacity(_saving ? 0.7 : 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E63D9).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saving ? null : _saveProfile,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saving)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                const SizedBox(width: 12),
                Text(
                  _saving ? 'Saving Changes...' : 'Save Changes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDEF7EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage ?? '',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
