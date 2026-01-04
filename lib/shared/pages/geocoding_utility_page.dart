import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/geocoding_service.dart';

/// Admin utility page to geocode doctor addresses
class GeocodingUtilityPage extends StatefulWidget {
  const GeocodingUtilityPage({super.key});

  @override
  State<GeocodingUtilityPage> createState() => _GeocodingUtilityPageState();
}

class _GeocodingUtilityPageState extends State<GeocodingUtilityPage> {
  final _geocodingService = GeocodingService();
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _results;
  final _testAddressController = TextEditingController();
  Map<String, dynamic>? _testResult;

  @override
  void dispose() {
    _testAddressController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAllDoctors() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing doctors...';
      _results = null;
    });

    final results = await _geocodingService.geocodeAllDoctors();

    setState(() {
      _isProcessing = false;
      _results = results;
      _statusMessage = 'Completed!';
    });
  }

  Future<void> _testAddress() async {
    final address = _testAddressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _testResult = null;
    });

    final result = await _geocodingService.testGeocoding(address);

    setState(() {
      _isProcessing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geocoding Utility'),
        backgroundColor: const Color(0xFF2D9CDB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Address Geocoding',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _testAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Enter full address',
                        hintText: 'e.g., 123 Rue Example, 75001 Paris, France',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _testAddress,
                      icon: const Icon(Icons.location_searching),
                      label: const Text('Test Geocoding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D9CDB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '✅ Success!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Latitude: ${_testResult!['latitude']}'),
                            Text('Longitude: ${_testResult!['longitude']}'),
                          ],
                        ),
                      ),
                    ] else if (_testResult == null &&
                        _testAddressController.text.isNotEmpty &&
                        !_isProcessing) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          '❌ Could not geocode this address',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Batch Process All Doctors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This will geocode all doctors who have addresses but missing or invalid coordinates (0, 0).',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _geocodeAllDoctors,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        _isProcessing ? 'Processing...' : 'Start Geocoding',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D9CDB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    if (_results != null) ...[
                      const SizedBox(height: 16),
                      Container(
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
                              'Results:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildResultRow(
                              'Total doctors',
                              _results!['total']?.toString() ?? '0',
                            ),
                            _buildResultRow(
                              '✅ Successfully geocoded',
                              _results!['success']?.toString() ?? '0',
                              Colors.green,
                            ),
                            _buildResultRow(
                              '⏭️ Skipped (already have coords)',
                              _results!['skipped']?.toString() ?? '0',
                              Colors.orange,
                            ),
                            _buildResultRow(
                              '❌ Failed',
                              _results!['failed']?.toString() ?? '0',
                              Colors.red,
                            ),
                            if (_results!.containsKey('error'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Error: ${_results!['error']}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sample Doctors (First 10)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final location =
                              data['location'] as Map<String, dynamic>?;
                          final coords =
                              location?['coordinates'] as Map<String, dynamic>?;
                          final lat = coords?['latitude'] ?? 0.0;
                          final lng = coords?['longitude'] ?? 0.0;
                          final hasValidCoords = lat != 0.0 && lng != 0.0;

                          return ListTile(
                            leading: Icon(
                              hasValidCoords
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: hasValidCoords
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: Text(
                              data['fullName']?.toString() ?? 'Unknown',
                            ),
                            subtitle: Text(
                              '${location?['address'] ?? 'No address'}\n'
                              'Coords: $lat, $lng',
                            ),
                            dense: true,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
