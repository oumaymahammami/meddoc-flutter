import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../patient/domain/entities/doctor.dart';
import '../data/repositories/doctor_repository_impl.dart';

class DoctorProfileEditPage extends StatefulWidget {
  final Doctor? profile;

  const DoctorProfileEditPage({this.profile, super.key});

  @override
  State<DoctorProfileEditPage> createState() => _DoctorProfileEditPageState();
}

class _DoctorProfileEditPageState extends State<DoctorProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final DoctorRepositoryImpl _repository;

  // Controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cabinetNumberController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _inPersonPriceController = TextEditingController();
  final _videoPriceController = TextEditingController();

  // State
  bool _loading = true;
  bool _saving = false;
  File? _selectedImage;
  List<String> _selectedLanguages = [];
  bool _acceptingPatients = true;
  bool _inPersonConsultation = false;
  bool _videoConsultation = false;
  double? _latitude;
  double? _longitude;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _repository = DoctorRepositoryImpl();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.profile == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = widget.profile!;
      setState(() {
        _fullNameController.text = profile.fullName;
        _bioController.text = profile.profile.bio;
        _phoneController.text = profile.phone;
        _emailController.text = profile.email;
        _addressLineController.text = profile.location.address;
        _cityController.text = profile.location.city;
        _postalCodeController.text = profile.location.postalCode;
        _inPersonPriceController.text = profile.pricing.inPersonFee.toString();
        _videoPriceController.text = profile.pricing.videoFee.toString();
        _selectedLanguages = List.from(profile.credentials.languages);
        _acceptingPatients = profile.searchMetadata.isAcceptingNewPatients;
        _inPersonConsultation = profile.consultationModes.inPerson;
        _videoConsultation = profile.consultationModes.video;
        _latitude = profile.location.coordinates.latitude;
        _longitude = profile.location.coordinates.longitude;
        _loading = false;
      });
    } catch (e) {
      _showError('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _validateAndSave() {
    if (!_formKey.currentState!.validate()) return;
    _save();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      // Update profile - simplified for Doctor entity
      final updates = <String, dynamic>{
        'firstName': _fullNameController.text.trim().split(' ').first,
        'lastName': _fullNameController.text
            .trim()
            .split(' ')
            .skip(1)
            .join(' '),
        'profile.bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'location.address': _addressLineController.text.trim(),
        'location.city': _cityController.text.trim(),
        'location.postalCode': _postalCodeController.text.trim(),
        'consultationModes.inPerson': _inPersonConsultation,
        'consultationModes.video': _videoConsultation,
        'pricing.inPersonFee': _inPersonPriceController.text.isEmpty
            ? 0.0
            : double.parse(_inPersonPriceController.text),
        'pricing.videoFee': _videoPriceController.text.isEmpty
            ? 0.0
            : double.parse(_videoPriceController.text),
        'credentials.languages': _selectedLanguages,
        'searchMetadata.isAcceptingNewPatients': _acceptingPatients,
        if (_latitude != null && _longitude != null)
          'location.coordinates': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
      };
      await _repository.updateProfile(uid, updates);

      if (!mounted) return;
      _showSuccess('Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cabinetNumberController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _inPersonPriceController.dispose();
    _videoPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Info Section
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Full name is required';
                  if (value.length < 2)
                    return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Tell patients about yourself',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10)
                      return 'Bio must be at least 10 characters';
                    if (value.length > 500)
                      return 'Bio must not exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Contact Section
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Clinic Section
              Text(
                'Clinic Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cabinetNumberController,
                decoration: const InputDecoration(
                  labelText: 'Cabinet Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Consultation Modes Section
              Text(
                'Consultation Modes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text('In-Person Consultation'),
                value: _inPersonConsultation,
                onChanged: (value) {
                  setState(() => _inPersonConsultation = value ?? false);
                },
              ),

              if (_inPersonConsultation)
                TextFormField(
                  controller: _inPersonPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (TND)',
                    border: OutlineInputBorder(),
                    prefixText: 'TND ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (_inPersonConsultation &&
                        (value == null || value.isEmpty)) {
                      return 'Price is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text('Video Consultation'),
                value: _videoConsultation,
                onChanged: (value) {
                  setState(() => _videoConsultation = value ?? false);
                },
              ),

              if (_videoConsultation)
                TextFormField(
                  controller: _videoPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (TND)',
                    border: OutlineInputBorder(),
                    prefixText: 'TND ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (_videoConsultation &&
                        (value == null || value.isEmpty)) {
                      return 'Price is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),

              // Additional Options
              CheckboxListTile(
                title: const Text('Accepting New Patients'),
                value: _acceptingPatients,
                onChanged: (value) {
                  setState(() => _acceptingPatients = value ?? true);
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _validateAndSave,
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.profile == null
                              ? 'Create Profile'
                              : 'Save Changes',
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
