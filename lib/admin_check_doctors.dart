import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Script to check and display all doctor addresses and their current coordinates
/// Run with: flutter run -t lib/admin_check_doctors.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CheckDoctorsApp());
}

class CheckDoctorsApp extends StatelessWidget {
  const CheckDoctorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check Doctor Addresses',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CheckDoctorsScreen(),
    );
  }
}

class CheckDoctorsScreen extends StatefulWidget {
  const CheckDoctorsScreen({super.key});

  @override
  State<CheckDoctorsScreen> createState() => _CheckDoctorsScreenState();
}

class _CheckDoctorsScreenState extends State<CheckDoctorsScreen> {
  List<DoctorInfo> _doctors = [];
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

      final doctors = <DoctorInfo>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final locationMap = data['location'] as Map<String, dynamic>?;
        final coordsMap = locationMap?['coordinates'] as Map<String, dynamic>?;

        doctors.add(
          DoctorInfo(
            id: doc.id,
            name: data['fullName']?.toString() ?? 'Unknown',
            address: locationMap?['address']?.toString() ?? 'No address',
            city: locationMap?['city']?.toString() ?? 'No city',
            postalCode:
                locationMap?['postalCode']?.toString() ?? 'No postal code',
            country: locationMap?['country']?.toString() ?? 'No country',
            latitude: (coordsMap?['latitude'] ?? 0.0) as num,
            longitude: (coordsMap?['longitude'] ?? 0.0) as num,
          ),
        );
      }

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Addresses & Coordinates'),
        backgroundColor: const Color(0xFF2D9CDB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDoctors),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
          ? const Center(child: Text('No doctors found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                final hasValidCoords =
                    doctor.latitude.abs() > 0.0001 &&
                    doctor.longitude.abs() > 0.0001;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Icon(
                      hasValidCoords ? Icons.check_circle : Icons.warning,
                      color: hasValidCoords ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    title: Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      hasValidCoords
                          ? 'Has valid coordinates ✓'
                          : 'Missing coordinates ⚠️',
                      style: TextStyle(
                        color: hasValidCoords ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('ID', doctor.id, Icons.fingerprint),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Address',
                              doctor.address,
                              Icons.home,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'City',
                              doctor.city,
                              Icons.location_city,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Postal Code',
                              doctor.postalCode,
                              Icons.markunread_mailbox,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Country',
                              doctor.country,
                              Icons.flag,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              'Latitude',
                              doctor.latitude.toString(),
                              Icons.map,
                              doctor.latitude == 0.0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Longitude',
                              doctor.longitude.toString(),
                              Icons.map,
                              doctor.longitude == 0.0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Full Address: ${doctor.address}, ${doctor.postalCode} ${doctor.city}, ${doctor.country}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Total',
                  _doctors.length.toString(),
                  Colors.blue,
                ),
                _buildStatChip(
                  'Valid Coords',
                  _doctors
                      .where(
                        (d) =>
                            d.latitude.abs() > 0.0001 &&
                            d.longitude.abs() > 0.0001,
                      )
                      .length
                      .toString(),
                  Colors.green,
                ),
                _buildStatChip(
                  'Missing Coords',
                  _doctors
                      .where(
                        (d) =>
                            d.latitude.abs() <= 0.0001 ||
                            d.longitude.abs() <= 0.0001,
                      )
                      .length
                      .toString(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
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
  final String country;
  final num latitude;
  final num longitude;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}
