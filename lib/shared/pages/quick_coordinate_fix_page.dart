import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple manual coordinate setter for doctors
class QuickCoordinateFixPage extends StatefulWidget {
  const QuickCoordinateFixPage({super.key});

  @override
  State<QuickCoordinateFixPage> createState() => _QuickCoordinateFixPageState();
}

class _QuickCoordinateFixPageState extends State<QuickCoordinateFixPage> {
  List<DoctorInfo> _doctors = [];
  bool _isLoading = true;

  // Common Tunisia locations for quick selection
  final Map<String, Map<String, double>> tunisiaLocations = {
    'Tunis Centre': {'lat': 36.8065, 'lng': 10.1815},
    'La Marsa': {'lat': 36.8785, 'lng': 10.3250},
    'Ariana': {'lat': 36.8625, 'lng': 10.1956},
    'Manouba': {'lat': 36.8081, 'lng': 10.0965},
    'Ben Arous': {'lat': 36.7540, 'lng': 10.2166},
    'Sousse': {'lat': 35.8256, 'lng': 10.6346},
    'Sfax': {'lat': 34.7406, 'lng': 10.7603},
    'Nabeul': {'lat': 36.4561, 'lng': 10.7353},
    'Bizerte': {'lat': 37.2744, 'lng': 9.8739},
    'Hammamet': {'lat': 36.4000, 'lng': 10.6167},
  };

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .get();

      final doctors = <DoctorInfo>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final locationMap = data['location'] as Map<String, dynamic>?;
        final coordsMap = locationMap?['coordinates'] as Map<String, dynamic>?;

        doctors.add(
          DoctorInfo(
            id: doc.id,
            name: data['fullName']?.toString() ?? 'Unknown',
            address: locationMap?['address']?.toString() ?? '',
            city: locationMap?['city']?.toString() ?? '',
            postalCode: locationMap?['postalCode']?.toString() ?? '',
            latitude: (coordsMap?['latitude'] ?? 0.0).toDouble(),
            longitude: (coordsMap?['longitude'] ?? 0.0).toDouble(),
          ),
        );
      }

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setCoordinates(
    DoctorInfo doctor,
    double lat,
    double lng,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .update({
            'location.coordinates': {'latitude': lat, 'longitude': lng},
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Updated ${doctor.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadDoctors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLocationPicker(DoctorInfo doctor) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Location for ${doctor.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address: ${doctor.address}'),
              Text('City: ${doctor.city}'),
              const SizedBox(height: 20),
              const Text(
                'Select nearest city:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tunisiaLocations.length,
                  itemBuilder: (context, index) {
                    final cityName = tunisiaLocations.keys.elementAt(index);
                    final coords = tunisiaLocations[cityName]!;

                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Color(0xFF2D9CDB),
                      ),
                      title: Text(cityName),
                      subtitle: Text('${coords['lat']}, ${coords['lng']}'),
                      onTap: () {
                        Navigator.pop(context);
                        _setCoordinates(doctor, coords['lat']!, coords['lng']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualEntry(doctor);
            },
            child: const Text('Enter Manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualEntry(DoctorInfo doctor) async {
    final latController = TextEditingController(
      text: doctor.latitude.toString(),
    );
    final lngController = TextEditingController(
      text: doctor.longitude.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Coordinates Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text(
              'Find coordinates on Google Maps:\n1. Search the address\n2. Right-click on the location\n3. Click the coordinates to copy',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              if (lat != null && lng != null) {
                Navigator.pop(context);
                _setCoordinates(doctor, lat, lng);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Coordinate Fix'),
        backgroundColor: const Color(0xFF2D9CDB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDoctors),
        ],
      ),
      body: Column(
        children: [
          if (user == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Not signed in - please sign in first',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Signed in as: ${user.email}',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 How to use:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Click on any doctor below'),
                    Text('2. Select the nearest city from the list'),
                    Text('3. Or enter exact coordinates from Google Maps'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                ? const Center(child: Text('No doctors found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _doctors[index];
                      final isDuplicate =
                          _doctors
                              .where(
                                (d) =>
                                    d.latitude == doctor.latitude &&
                                    d.longitude == doctor.longitude,
                              )
                              .length >
                          1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDuplicate ? Colors.orange.shade50 : null,
                        child: ListTile(
                          leading: Icon(
                            isDuplicate ? Icons.warning : Icons.location_on,
                            color: isDuplicate ? Colors.orange : Colors.green,
                            size: 32,
                          ),
                          title: Text(
                            doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${doctor.address}, ${doctor.city}\n'
                            'Current: ${doctor.latitude.toStringAsFixed(4)}, '
                            '${doctor.longitude.toStringAsFixed(4)}',
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: user == null
                                ? null
                                : () => _showLocationPicker(doctor),
                            icon: const Icon(Icons.edit_location, size: 18),
                            label: const Text('Set'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D9CDB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DoctorInfo {
  final String id;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });
}
