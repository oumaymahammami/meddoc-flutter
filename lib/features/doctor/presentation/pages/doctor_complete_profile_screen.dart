import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

// 🎨 Design System Colors
class MedDocColors {
  static const Color primaryBlue = Color(0xFF2E63D9);
  static const Color primaryBlueDark = Color(0xFF1A47B5);
  static const Color primaryBlueLight = Color(0xFFEBF2FF);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedLight = Color(0xFFFEE2E2);
  static const Color successGreen = Color(0xFF10B981);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFFAFAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = neutral50;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// 📝 Typography
class MedDocTypography {
  static const TextStyle titleLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: MedDocColors.neutral900,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: MedDocColors.neutral900,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: MedDocColors.neutral900,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: MedDocColors.neutral900,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: MedDocColors.neutral900,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: MedDocColors.neutral700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: MedDocColors.neutral700,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: MedDocColors.neutral900,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: MedDocColors.neutral500,
  );

  static const TextStyle helperText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: MedDocColors.neutral500,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: Colors.white,
    letterSpacing: 0.2,
  );
}

// 📐 Spacing
class MedDocSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 28;
  static const double xl4 = 32;
  static const double xl5 = 40;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double buttonRadius = radiusLarge;
}

// ⏱️ Animation Duration
class MedDocDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

// 🌫️ Shadows
class MedDocShadows {
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
}

/// Premium Multi-Step Doctor Profile Wizard
/// Inspired by Doctolib/ZocDoc design
class DoctorCompleteProfileScreen extends StatefulWidget {
  const DoctorCompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorCompleteProfileScreen> createState() =>
      _DoctorCompleteProfileScreenState();
}

class _DoctorCompleteProfileScreenState
    extends State<DoctorCompleteProfileScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _loading = false;
  String? _errorMessage;

  late AnimationController _slideAnimation;
  late AnimationController _fadeAnimation;

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicNumberController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicCityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _priceInPersonController = TextEditingController();
  final _priceVideoController = TextEditingController();

  bool _acceptInPerson = false;
  bool _acceptVideo = true;
  bool _acceptingNewPatients = true;

  @override
  void initState() {
    super.initState();
    _slideAnimation = AnimationController(
      duration: MedDocDuration.normal,
      vsync: this,
    );
    _fadeAnimation = AnimationController(
      duration: MedDocDuration.normal,
      vsync: this,
    );
    // Start animations immediately for initial content visibility
    _fadeAnimation.forward();
    _slideAnimation.forward();
  }

  @override
  void dispose() {
    _slideAnimation.dispose();
    _fadeAnimation.dispose();
    _fullNameController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _clinicNumberController.dispose();
    _clinicAddressController.dispose();
    _clinicCityController.dispose();
    _postalCodeController.dispose();
    _priceInPersonController.dispose();
    _priceVideoController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      if (!_isStepValid()) {
        setState(() => _errorMessage = 'Please complete required fields');
        return;
      }
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
      _animateStepChange();
    } else {
      await _submitProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _animateStepChange();
    }
  }

  void _animateStepChange() {
    _slideAnimation.forward(from: 0);
    _fadeAnimation.forward(from: 0);
  }

  Future<void> _submitProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!_isStepValid()) {
      setState(() => _errorMessage = 'Please complete required fields');
      return;
    }

    setState(() => _loading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Use set with merge to create/update the doctor document
      await firestore.collection('doctors').doc(uid).set({
        'uid': uid,
        'firstName': _fullNameController.text,
        'fullName': _fullNameController.text, // Add fullName for consistency
        'bio': _bioController.text.isEmpty ? null : _bioController.text,
        'specialty': _specialtyController.text,
        'phone': _phoneController.text,
        'clinicNumber': _clinicNumberController.text.isEmpty
            ? null
            : _clinicNumberController.text,
        'clinicAddress': _clinicAddressController.text,
        'clinicCity': _clinicCityController.text,
        'clinicPostalCode': _postalCodeController.text.isEmpty
            ? null
            : _postalCodeController.text,
        'acceptInPerson': _acceptInPerson,
        'acceptVideo': _acceptVideo,
        'priceInPerson':
            _acceptInPerson && _priceInPersonController.text.isNotEmpty
            ? double.tryParse(_priceInPersonController.text)
            : null,
        'priceVideo': _acceptVideo && _priceVideoController.text.isNotEmpty
            ? double.tryParse(_priceVideoController.text)
            : null,
        'currency': 'TND',
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update users collection
      await firestore.collection('users').doc(uid).set({
        'profileCompleted': true,
      }, SetOptions(merge: true));

      if (mounted) {
        context.go('/doctor/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _fullNameController.text.isNotEmpty &&
            _specialtyController.text.isNotEmpty;
      case 1: // Professional Details
        return _phoneController.text.isNotEmpty;
      case 2: // Clinic Info
        return _clinicAddressController.text.isNotEmpty &&
            _clinicCityController.text.isNotEmpty;
      case 3: // Services
        return true; // All optional
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: MedDocColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
                color: MedDocColors.neutral900,
              )
            : null,
        title: Text(
          'MedDoc Profile',
          style: MedDocTypography.titleSmall.copyWith(
            color: MedDocColors.neutral900,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: MedDocSpacing.lg),
                child: Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: MedDocTypography.labelLarge.copyWith(
                    color: MedDocColors.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? MedDocSpacing.lg : MedDocSpacing.xl,
            vertical: MedDocSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Progress Bar
              _buildProgressBar(),
              const SizedBox(height: 40),

              /// Step Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: _buildStepContent(),
                ),
              ),

              const SizedBox(height: 40),

              /// Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedDocSpacing.lg,
                    vertical: MedDocSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: MedDocColors.errorRedLight,
                    border: Border.all(color: MedDocColors.errorRed),
                    borderRadius: BorderRadius.circular(
                      MedDocSpacing.radiusMedium,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: MedDocTypography.bodySmall.copyWith(
                      color: MedDocColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              /// Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MedDocSpacing.radiusSmall),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            minHeight: 4,
            backgroundColor: MedDocColors.neutral300,
            valueColor: AlwaysStoppedAnimation<Color>(MedDocColors.primaryBlue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${((_currentStep + 1) / _totalSteps * 100).toStringAsFixed(0)}% Complete',
          style: MedDocTypography.labelSmall.copyWith(
            color: MedDocColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2ProfessionalDetails();
      case 2:
        return _buildStep3ClinicInfo();
      case 3:
        return _buildStep4Services();
      case 4:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1 of $_totalSteps: Basic Information',
          style: MedDocTypography.headingSmall.copyWith(
            color: MedDocColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Let\'s start with your basic information',
          style: MedDocTypography.titleMedium,
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name',
          hint: 'Dr. John Doe',
          icon: Icons.person_outline,
          helper: 'This will appear on your doctor profile',
          required: true,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _specialtyController,
          label: 'Specialty',
          hint: 'Cardiology, Dentistry, etc.',
          icon: Icons.medical_services_outlined,
          helper: 'Select your primary medical specialization',
          required: true,
        ),
      ],
    );
  }

  Widget _buildStep2ProfessionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2 of $_totalSteps: Professional Details',
          style: MedDocTypography.headingSmall.copyWith(
            color: MedDocColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tell us more about your professional background',
          style: MedDocTypography.titleMedium,
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+216 XX XXX XXXX',
          icon: Icons.phone_outlined,
          helper: 'Patients will use this to contact you',
          required: true,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _bioController,
          label: 'Professional Bio',
          hint: 'Tell patients about yourself...',
          icon: Icons.description_outlined,
          helper: 'Highlight your experience and qualifications',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildStep3ClinicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3 of $_totalSteps: Clinic Information',
          style: MedDocTypography.headingSmall.copyWith(
            color: MedDocColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Text('Where do you practice?', style: MedDocTypography.titleMedium),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _clinicNumberController,
          label: 'Cabinet Number',
          hint: 'E.g., 101 or Room A',
          icon: Icons.home_work_outlined,
          helper: 'Your clinic/office number or identifier',
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _clinicAddressController,
          label: 'Address',
          hint: '123 Medical Avenue, Tunis',
          icon: Icons.location_on_outlined,
          helper: 'Street address of your clinic location',
          required: true,
        ),
        const SizedBox(height: 24),
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
            const SizedBox(width: 16),
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
    );
  }

  Widget _buildStep4Services() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4 of $_totalSteps: Consultation Services',
          style: MedDocTypography.headingSmall.copyWith(
            color: MedDocColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'How do you prefer to consult?',
          style: MedDocTypography.titleMedium,
        ),
        const SizedBox(height: 40),
        _buildServiceOption(
          label: 'In-Person Consultations',
          subtitle: 'Patients can visit you at your clinic',
          value: _acceptInPerson,
          onChanged: (value) => setState(() => _acceptInPerson = value),
          icon: Icons.location_on_outlined,
          priceController: _acceptInPerson ? _priceInPersonController : null,
        ),
        const SizedBox(height: 24),
        _buildServiceOption(
          label: 'Video Consultations',
          subtitle: 'Offer remote consultations via video call',
          value: _acceptVideo,
          onChanged: (value) => setState(() => _acceptVideo = value),
          icon: Icons.video_call_outlined,
          priceController: _acceptVideo ? _priceVideoController : null,
        ),
        const SizedBox(height: 24),
        _buildServiceOption(
          label: 'Accepting New Patients',
          subtitle: 'Receive new patient requests',
          value: _acceptingNewPatients,
          onChanged: (value) => setState(() => _acceptingNewPatients = value),
          icon: Icons.people_outline,
        ),
      ],
    );
  }

  Widget _buildStep5Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5 of $_totalSteps: Review & Confirm',
          style: MedDocTypography.headingSmall.copyWith(
            color: MedDocColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Everything looks good! Let\'s review',
          style: MedDocTypography.titleMedium,
        ),
        const SizedBox(height: 40),
        _buildReviewSection('Professional Info', [
          ('Full Name', _fullNameController.text),
          ('Specialty', _specialtyController.text),
          ('Phone', _phoneController.text),
        ]),
        const SizedBox(height: 24),
        _buildReviewSection('Clinic Details', [
          ('Cabinet', _clinicNumberController.text),
          ('Address', _clinicAddressController.text),
          (
            'City / Code',
            '${_clinicCityController.text} ${_postalCodeController.text}',
          ),
        ]),
        const SizedBox(height: 24),
        _buildReviewSection('Services', [
          (
            'In-Person',
            _acceptInPerson
                ? '${_priceInPersonController.text} TND'
                : 'Not offered',
          ),
          (
            'Video Call',
            _acceptVideo ? '${_priceVideoController.text} TND' : 'Not offered',
          ),
          (
            'New Patients',
            _acceptingNewPatients ? 'Accepting' : 'Not accepting',
          ),
        ]),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
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
                TextSpan(text: label, style: MedDocTypography.labelLarge),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: MedDocColors.errorRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: MedDocColors.primaryBlue),
              filled: true,
              fillColor: MedDocColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MedDocSpacing.radiusMedium),
                borderSide: const BorderSide(
                  color: MedDocColors.neutral300,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MedDocSpacing.radiusMedium),
                borderSide: const BorderSide(
                  color: MedDocColors.neutral300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MedDocSpacing.radiusMedium),
                borderSide: const BorderSide(
                  color: MedDocColors.primaryBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MedDocSpacing.lg,
                vertical: MedDocSpacing.md,
              ),
              hintStyle: MedDocTypography.bodyMedium.copyWith(
                color: MedDocColors.neutral500,
              ),
            ),
            style: MedDocTypography.bodyMedium.copyWith(
              color: MedDocColors.neutral900,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper, style: MedDocTypography.helperText),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceOption({
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    TextEditingController? priceController,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MedDocColors.white,
        border: Border.all(
          color: value ? MedDocColors.primaryBlue : MedDocColors.neutral300,
          width: value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(MedDocSpacing.radiusLarge),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return MedDocColors.primaryBlue;
                  }
                  return MedDocColors.white;
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: value
                      ? MedDocColors.primaryBlue
                      : MedDocColors.neutral300,
                  width: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: MedDocTypography.headingMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: MedDocTypography.bodySmall.copyWith(
                        color: MedDocColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (value && priceController != null) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: priceController,
              label: 'Consultation Fee (TND)',
              hint: '0.00',
              icon: Icons.attach_money,
              helper: 'Price in Tunisian Dinar',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<(String, String)> items) {
    return Container(
      decoration: BoxDecoration(
        color: MedDocColors.white,
        border: Border.all(color: MedDocColors.neutral300),
        borderRadius: BorderRadius.circular(MedDocSpacing.radiusLarge),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedDocColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: MedDocColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: MedDocTypography.headingMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? MedDocSpacing.md : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: MedDocTypography.bodyMedium.copyWith(
                      color: MedDocColors.neutral700,
                    ),
                  ),
                  Text(
                    item.$2,
                    style: MedDocTypography.bodyMedium.copyWith(
                      color: MedDocColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: MedDocColors.primaryBlue,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '← Back',
                style: MedDocTypography.buttonMedium.copyWith(
                  color: MedDocColors.primaryBlue,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: MedDocColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [MedDocShadows.buttonShadow],
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1
                          ? 'Complete Profile'
                          : 'Next Step →',
                      style: MedDocTypography.buttonMedium,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
