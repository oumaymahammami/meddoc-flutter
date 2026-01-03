import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:meddoc/shared/services/auth_onboarding_service.dart';
import 'package:meddoc/features/doctor/data/datasources/doctor_storage_service.dart';

/// Doctor Profile Edit Screen - Edit existing profile
///
/// Allows editing of safe fields only:
/// - fullName, bio, specialtyId
/// - contacts.*, clinic.*, consultationModes.*, pricing.*
/// - languages[], acceptingNewPatients, photo
///
/// Prevents editing of admin-only fields:
/// - ownerUid, createdAt, profileCompleted
/// - verification.*, visibility.*, metrics.*
class DoctorProfileEditScreen extends ConsumerStatefulWidget {
  const DoctorProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState
    extends ConsumerState<DoctorProfileEditScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicCityController;
  late TextEditingController _consultationFeeController;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _specialtyId;
  List<String> _languages = [];
  bool _acceptingNewPatients = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadProfile();
  }

  void _initControllers() {
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _clinicNameController = TextEditingController();
    _clinicCityController = TextEditingController();
    _consultationFeeController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clinicNameController.dispose();
    _clinicCityController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
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

      // Populate controllers with current data
      setState(() {
        _fullNameController.text = doctorDoc['fullName'] as String? ?? '';
        _bioController.text = doctorDoc['bio'] as String? ?? '';
        _specialtyId = doctorDoc['specialtyId'] as String?;
        _acceptingNewPatients =
            doctorDoc['acceptingNewPatients'] as bool? ?? false;

        final contacts = doctorDoc['contacts'] as Map<String, dynamic>? ?? {};
        _phoneController.text = contacts['phone'] as String? ?? '';
        _emailController.text = contacts['email'] as String? ?? '';

        final clinic = doctorDoc['clinic'] as Map<String, dynamic>? ?? {};
        _clinicNameController.text = clinic['name'] as String? ?? '';
        _clinicCityController.text = clinic['city'] as String? ?? '';

        final pricing = doctorDoc['pricing'] as Map<String, dynamic>? ?? {};
        final fee = pricing['consultationFee'] as num?;
        _consultationFeeController.text = fee != null
            ? fee.toStringAsFixed(2)
            : '';

        _languages = (doctorDoc['languages'] as List?)?.cast<String>() ?? [];

        _loading = false;
      });
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No authenticated user');

      final storageService = DoctorStorageService();

      // Upload image if selected
      String? photoStoragePath;
      if (_selectedImage != null) {
        print('📷 Uploading profile photo...');
        photoStoragePath = await storageService.uploadProfilePhoto(
          doctorId: uid,
          imageFile: _selectedImage!,
        );
        print('✅ Photo uploaded: $photoStoragePath');
      }

      // Build safe fields map
      final safeFields = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'acceptingNewPatients': _acceptingNewPatients,
        'languages': _languages,
        'contacts': {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        'clinic': {
          'name': _clinicNameController.text.trim(),
          'city': _clinicCityController.text.trim(),
        },
        'pricing': {
          'consultationFee':
              double.tryParse(_consultationFeeController.text) ?? 0.0,
        },
        'updatedAt': DateTime.now(),
      };

      if (_specialtyId != null) {
        safeFields['specialtyId'] = _specialtyId;
      }

      if (photoStoragePath != null) {
        safeFields['photo'] = {
          'storagePath': photoStoragePath,
          'uploadedAt': DateTime.now(),
        };
      }

      print('💾 Updating doctor profile with safe fields...');

      // Add uid field to ensure document can be created if it doesn't exist
      safeFields['uid'] = uid;

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .set(
            safeFields.map(
              (k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v),
            ),
            SetOptions(merge: true),
          );

      print('✅ Profile updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _validateForm() {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty || fullName.length < 2) {
      setState(() => _error = 'Full name must be at least 2 characters');
      return false;
    }

    if (phone.isEmpty && email.isEmpty) {
      setState(() => _error = 'Please enter at least phone or email');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Photo section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Change Photo'),
                    onPressed: _saving ? null : _pickImage,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Basic info section
            Text(
              'Basic Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Full name
            TextField(
              controller: _fullNameController,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Dr. Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            TextField(
              controller: _bioController,
              enabled: !_saving,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell patients about your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Contact info section
            Text(
              'Contact Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Phone
            TextField(
              controller: _phoneController,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: '+1-555-0123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'doctor@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 32),

            // Clinic info section
            Text(
              'Clinic Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Clinic name
            TextField(
              controller: _clinicNameController,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'Clinic Name',
                hintText: 'Heart Care Clinic',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.business_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // Clinic city
            TextField(
              controller: _clinicCityController,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'City',
                hintText: 'New York',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),

            const SizedBox(height: 32),

            // Pricing section
            Text(
              'Pricing',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Consultation fee
            TextField(
              controller: _consultationFeeController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Consultation Fee',
                hintText: '100.00',
                prefix: const Text('\$ '),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Accepting new patients
            CheckboxListTile(
              value: _acceptingNewPatients,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() => _acceptingNewPatients = value ?? false);
                    },
              title: const Text('Accepting New Patients'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
