import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple Complete Doctor Profile Screen
///
/// Shows after login if profileCompleted=false
/// Collects minimal required info:
/// - Full Name
/// - Phone
/// - Specialty
///
/// On submit:
/// 1. Updates /doctors/{uid} with profile data
/// 2. Sets /users/{uid}.profileCompleted=true
/// 3. Redirects to Dashboard
class DoctorCompleteProfilePage extends StatefulWidget {
  final String uid;
  final String email;

  const DoctorCompleteProfilePage({
    required this.uid,
    required this.email,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorCompleteProfilePage> createState() =>
      _DoctorCompleteProfilePageState();
}

class _DoctorCompleteProfilePageState extends State<DoctorCompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  String? _selectedSpecialty;
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();

      print('💾 Updating /doctors/${widget.uid} with profile data...');

      // STEP 1: Upsert /doctors/{uid} with profile information (create if missing)
      await _firestore.collection('doctors').doc(widget.uid).set(
        {
          'fullName': fullName,
          'contacts': {'phone': phone, 'email': widget.email},
          'specialtyId': _selectedSpecialty,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ Upserted /doctors/${widget.uid}');

      // STEP 2: Set profileCompleted=true on /users/{uid}
      print('🔄 Setting profileCompleted=true on /users/${widget.uid}...');
      await _firestore.collection('users').doc(widget.uid).update({
        'profileCompleted': true,
        'lastProfileUpdateAt': FieldValue.serverTimestamp(),
      });
      print('✅ Set profileCompleted=true');

      if (!mounted) return;

      // STEP 3: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile completed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // STEP 4: Redirect to Dashboard
      print('➡️  Navigating to dashboard...');
      Navigator.of(context).pushReplacementNamed('/doctor/dashboard');
    } catch (e) {
      print('❌ Error completing profile: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // No back button
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'Welcome Doctor!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile to access the dashboard',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 30),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Dr. Ahmed Hassan',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.length < 2) {
                    return 'Full name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+216 21 123 456',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Specialty
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                decoration: InputDecoration(
                  labelText: 'Specialty *',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cardiology',
                    child: Text('Cardiology'),
                  ),
                  DropdownMenuItem(
                    value: 'dermatology',
                    child: Text('Dermatology'),
                  ),
                  DropdownMenuItem(
                    value: 'general_medicine',
                    child: Text('General Medicine'),
                  ),
                  DropdownMenuItem(
                    value: 'psychiatry',
                    child: Text('Psychiatry'),
                  ),
                  DropdownMenuItem(
                    value: 'dentistry',
                    child: Text('Dentistry'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _selectedSpecialty = value);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a specialty';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Complete Profile Button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Complete Profile',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'After completing your profile, you\'ll have access to the dashboard and can manage your consultations.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
