import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _orderNumberController = TextEditingController();
  File? _proofImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // Fetch the doctor's profile from Firestore
      final profile =
          await fetchDoctorProfile(); // Replace with actual Firestore call
      if (profile != null) {
        setState(() {
          _specialtyController.text = profile['specialty'];
          _addressController.text = profile['address'];
          _orderNumberController.text = profile['orderNumber'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_specialtyController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _orderNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fields are required!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Save the updated profile to Firestore
      await saveDoctorProfile(
        specialty: _specialtyController.text,
        address: _addressController.text,
        orderNumber: _orderNumberController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/doctor/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, size: 50, color: Colors.teal),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Complete your profile to continue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildTextField(_specialtyController, 'Specialty', Icons.work),
              SizedBox(height: 20),
              _buildTextField(_addressController, 'Address', Icons.location_on),
              SizedBox(height: 20),
              _buildTextField(
                _orderNumberController,
                'Order Number',
                Icons.numbers,
              ),
              SizedBox(height: 20),
              Text(
                'Upload Proof (optional):',
                style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _proofImage != null && _proofImage!.path.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _proofImage!.path,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            'Tap to upload image',
                            style: TextStyle(color: Colors.teal.shade700),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Future<Map<String, dynamic>?> fetchDoctorProfile() async {
    // Simulate fetching the doctor's profile from Firestore
    // Replace this with actual Firestore logic
    await Future.delayed(Duration(seconds: 1));
    return {
      'specialty': 'Cardiology',
      'address': '123 Main Street',
      'orderNumber': 'ORD12345',
    };
  }

  Future<void> saveDoctorProfile({
    required String specialty,
    required String address,
    required String orderNumber,
  }) async {
    // Simulate saving the doctor's profile to Firestore
    // Replace this with actual Firestore logic
    await Future.delayed(Duration(seconds: 1));
    if (specialty.isEmpty || address.isEmpty || orderNumber.isEmpty) {
      throw ArgumentError('All fields must be non-empty.');
    }
    print('Profile saved: $specialty, $address, $orderNumber');
  }
}
