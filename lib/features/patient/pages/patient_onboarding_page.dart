import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme_config.dart';
import '../../patient/data/datasources/patient_firestore_datasource.dart';
import '../../patient/data/repositories/patient_repository_impl.dart';
import '../../patient/domain/entities/patient_profile.dart';

class PatientOnboardingPage extends StatefulWidget {
  const PatientOnboardingPage({super.key});

  @override
  State<PatientOnboardingPage> createState() => _PatientOnboardingPageState();
}

class _PatientOnboardingPageState extends State<PatientOnboardingPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();

  int _currentStep = 0;
  DateTime? _dateOfBirth;
  String? _sex;
  bool _loading = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _patientRepo = PatientRepositoryImpl(PatientFirestoreDatasource());

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Tell us about yourself',
      subtitle: 'Help us personalize your healthcare experience',
      icon: Icons.person_outline,
      gradient: AppTheme.primaryGradient,
    ),
    OnboardingStep(
      title: 'Where can we reach you?',
      subtitle: 'Your location helps us find nearby care',
      icon: Icons.location_on_outlined,
      gradient: AppTheme.calmGradient,
    ),
    OnboardingStep(
      title: 'Health & Allergies',
      subtitle: 'Keep your care team informed for safer treatment',
      icon: Icons.health_and_safety_outlined,
      gradient: AppTheme.warmGradient,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: AppAnimations.pageTransition,
        curve: Curves.easeInOutCubic,
      );
      _animateTransition();
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: AppAnimations.pageTransition,
        curve: Curves.easeInOutCubic,
      );
      _animateTransition();
    }
  }

  void _animateTransition() {
    _scaleController.reset();
    _scaleController.forward();
  }

  Future<void> _complete() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final profile = PatientProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        dateOfBirth: _dateOfBirth,
        sex: _sex,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
      );

      await _patientRepo.createProfile(profile);

      if (!mounted) return;
      context.go('/patient');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  double get _progress => (_currentStep + 1) / _steps.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _previousStep,
                color: const Color(0xFF2D3748),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => context.go('/patient'),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalInfoStep(),
                    _buildLocationStep(),
                    _buildHealthStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _steps.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: index <= _currentStep
                        ? _steps[index].gradient
                        : null,
                    color: index > _currentStep ? Colors.grey.shade200 : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF718096),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}% completed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(0),
            const SizedBox(height: AppSpacing.xl),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSexSelector(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMotivationalMessage(
              '🎉 Almost there! Just two more quick steps.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(1),
            const SizedBox(height: AppSpacing.xl),
            _buildGlassCard(
              child: TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Your Address',
                  hintText: 'Street, City, Postal Code',
                  prefixIcon: Icon(
                    Icons.home_outlined,
                    color: AppTheme.primaryTeal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  labelStyle: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMotivationalMessage(
              '🏠 Optional but helpful for local healthcare providers',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStep() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(2),
            const SizedBox(height: AppSpacing.xl),
            _buildGlassCard(
              child: TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Known Allergies',
                  hintText: 'e.g., Penicillin, Pollen, Peanuts',
                  prefixIcon: Icon(
                    Icons.medical_information_outlined,
                    color: AppTheme.warmPeach,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  labelStyle: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                maxLines: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMotivationalMessage(
              '⚕️ This helps your doctors provide safer, better care',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(int stepIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _steps[stepIndex].gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.glowEffect(
              stepIndex == 0
                  ? AppTheme.primaryTeal
                  : stepIndex == 1
                  ? AppTheme.skyBlue
                  : AppTheme.warmPeach,
            ),
          ),
          child: Icon(_steps[stepIndex].icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _steps[stepIndex].title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _steps[stepIndex].subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF718096),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow(),
      ),
      child: child,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cake_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateOfBirth == null
                        ? 'Tap to select'
                        : DateFormat('MMMM dd, yyyy').format(_dateOfBirth!),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _dateOfBirth == null
                          ? const Color(0xFF718096)
                          : const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF718096)),
          ],
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sex (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 12,
          children: [
            _buildSexChip('Male', 'M', Icons.male),
            _buildSexChip('Female', 'F', Icons.female),
            _buildSexChip('Other', 'O', Icons.transgender),
          ],
        ),
      ],
    );
  }

  Widget _buildSexChip(String label, String value, IconData icon) {
    final isSelected = _sex == value;
    return AnimatedContainer(
      duration: AppAnimations.fast,
      child: InkWell(
        onTap: () => setState(() => _sex = isSelected ? null : value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? AppTheme.glowEffect(AppTheme.primaryTeal)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF718096),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.mintGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryTeal.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _currentStep == _steps.length - 1
                      ? AppTheme.warmGradient
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowEffect(
                    _currentStep == _steps.length - 1
                        ? AppTheme.warmPeach
                        : AppTheme.primaryTeal,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _steps.length - 1
                                  ? 'Complete Setup'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
