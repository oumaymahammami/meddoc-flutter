import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shared/services/geocoding_service.dart';

/// Standalone script to geocode all doctor addresses
/// Run with: flutter run -t lib/admin_geocode_doctors.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GeocodingApp());
}

class GeocodingApp extends StatelessWidget {
  const GeocodingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geocode Doctors',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const GeocodingScreen(),
    );
  }
}

class GeocodingScreen extends StatefulWidget {
  const GeocodingScreen({super.key});

  @override
  State<GeocodingScreen> createState() => _GeocodingScreenState();
}

class _GeocodingScreenState extends State<GeocodingScreen> {
  final _geocodingService = GeocodingService();
  bool _isProcessing = false;
  String _statusMessage = 'Ready to geocode doctors';
  Map<String, dynamic>? _results;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    // Automatically start geocoding when the app loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeocoding();
    });
  }

  Future<void> _startGeocoding() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Starting geocoding process...';
      _logs.clear();
    });

    _addLog('🚀 Starting to geocode all doctors...');
    _addLog('This may take a few minutes depending on the number of doctors');
    _addLog('---');

    try {
      final results = await _geocodingService.geocodeAllDoctors();

      setState(() {
        _isProcessing = false;
        _results = results;
        _statusMessage = 'Geocoding completed!';
      });

      _addLog('---');
      _addLog('✅ COMPLETED!');
      _addLog('Total doctors: ${results['total']}');
      _addLog('✅ Successfully geocoded: ${results['success']}');
      _addLog('⏭️ Skipped (already had coordinates): ${results['skipped']}');
      _addLog('❌ Failed: ${results['failed']}');

      if (results.containsKey('error')) {
        _addLog('⚠️ Error: ${results['error']}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error occurred';
      });
      _addLog('❌ Error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geocode All Doctors'),
        backgroundColor: const Color(0xFF2D9CDB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_isProcessing)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        _results != null
                            ? Icons.check_circle
                            : Icons.location_searching,
                        size: 64,
                        color: _results != null
                            ? Colors.green
                            : const Color(0xFF2D9CDB),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_results != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Total Doctors',
                        _results!['total']?.toString() ?? '0',
                        Icons.people,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '✅ Success',
                        _results!['success']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '⏭️ Skipped',
                        _results!['skipped']?.toString() ?? '0',
                        Icons.skip_next,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '❌ Failed',
                        _results!['failed']?.toString() ?? '0',
                        Icons.error,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Process Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isProcessing && _results != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startGeocoding,
                icon: const Icon(Icons.refresh),
                label: const Text('Run Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9CDB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
