import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/geocoding_service.dart';

/// Geocoding utility page accessible through the main app (requires auth)
class GeocodingAdminPage extends StatefulWidget {
  const GeocodingAdminPage({super.key});

  @override
  State<GeocodingAdminPage> createState() => _GeocodingAdminPageState();
}

class _GeocodingAdminPageState extends State<GeocodingAdminPage> {
  final _geocodingService = GeocodingService();
  bool _isProcessing = false;
  Map<String, dynamic>? _results;
  List<DoctorData> _doctors = [];
  bool _isLoading = true;

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

      final doctors = <DoctorData>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final locationMap = data['location'] as Map<String, dynamic>?;
        final coordsMap = locationMap?['coordinates'] as Map<String, dynamic>?;

        final lat = (coordsMap?['latitude'] ?? 0.0) as num;
        final lng = (coordsMap?['longitude'] ?? 0.0) as num;
        final hasValidCoords = lat.abs() > 0.0001 && lng.abs() > 0.0001;

        doctors.add(
          DoctorData(
            id: doc.id,
            name: data['fullName']?.toString() ?? 'Unknown',
            address: locationMap?['address']?.toString() ?? 'No address',
            city: locationMap?['city']?.toString() ?? '',
            postalCode: locationMap?['postalCode']?.toString() ?? '',
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
            hasValidCoords: hasValidCoords,
          ),
        );
      }

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _geocodeAllDoctors({bool forceReGeocode = false}) async {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to geocode doctors'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _results = null;
    });

    try {
      final results = await _geocodingService.geocodeAllDoctors(
        forceReGeocode: forceReGeocode,
      );

      setState(() {
        _isProcessing = false;
        _results = results;
      });

      // Reload doctors to see updates
      await _loadDoctors();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Geocoded ${results['success']} doctors successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setManualCoordinates(DoctorData doctor) async {
    final latController = TextEditingController(
      text: doctor.latitude.toString(),
    );
    final lngController = TextEditingController(
      text: doctor.longitude.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Coordinates for ${doctor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Address: ${doctor.address}, ${doctor.city}'),
            const SizedBox(height: 16),
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
              'Tip: Find coordinates on Google Maps',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);

              if (lat != null && lng != null) {
                try {
                  await _geocodingService.setDoctorCoordinates(
                    doctor.id,
                    lat,
                    lng,
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final validCount = _doctors.where((d) => d.hasValidCoords).length;
    final missingCount = _doctors.length - validCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Locations Manager'),
        backgroundColor: const Color(0xFF2D9CDB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDoctors),
        ],
      ),
      body: Column(
        children: [
          // Auth status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: user != null ? Colors.green.shade50 : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  user != null ? Icons.check_circle : Icons.warning,
                  color: user != null ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user != null
                        ? 'Signed in as: ${user.email}'
                        : 'Not signed in - please sign in first',
                    style: TextStyle(
                      color: user != null
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total',
                  _doctors.length.toString(),
                  Colors.blue,
                ),
                _buildStatCard('Valid', validCount.toString(), Colors.green),
                _buildStatCard(
                  'Missing',
                  missingCount.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          // Geocode buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || user == null)
                        ? null
                        : () => _geocodeAllDoctors(forceReGeocode: true),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_outlined),
                    label: const Text(
                      'Force Re-Geocode All Doctors (Fix Duplicates)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will convert each doctor\'s address to real GPS coordinates',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_results != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Geocoding Results:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('✅ Success: ${_results!['success']}'),
                    Text('⏭️ Skipped: ${_results!['skipped']}'),
                    Text('❌ Failed: ${_results!['failed']}'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Doctors list
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            doctor.hasValidCoords
                                ? Icons.check_circle
                                : Icons.warning,
                            color: doctor.hasValidCoords
                                ? Colors.green
                                : Colors.orange,
                            size: 32,
                          ),
                          title: Text(
                            doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${doctor.address}, ${doctor.city}\n'
                            'Coords: ${doctor.latitude.toStringAsFixed(4)}, '
                            '${doctor.longitude.toStringAsFixed(4)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_location),
                            onPressed: () => _setManualCoordinates(doctor),
                            tooltip: 'Set manual coordinates',
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

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

class DoctorData {
  final String id;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final bool hasValidCoords;

  DoctorData({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.hasValidCoords,
  });
}
