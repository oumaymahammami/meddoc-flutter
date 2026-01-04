import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../models/video_consultation.dart';
import 'video_call_page.dart';

class DoctorWaitingRoomPage extends StatefulWidget {
  final VideoConsultation consultation;

  const DoctorWaitingRoomPage({Key? key, required this.consultation})
    : super(key: key);

  @override
  State<DoctorWaitingRoomPage> createState() => _DoctorWaitingRoomPageState();
}

class _DoctorWaitingRoomPageState extends State<DoctorWaitingRoomPage> {
  bool _cameraEnabled = true;
  bool _micEnabled = true;
  bool _isTesting = false;
  html.MediaStream? _mediaStream;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final viewId = 'doctor-camera-preview-${widget.consultation.id}';

      // Check if already registered to prevent "Device in use" error
      try {
        // Register video element
        // ignore: undefined_prefixed_name
        ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
          final video = html.VideoElement()
            ..autoplay = true
            ..muted = true
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover';

          // Request camera and microphone access
          html.window.navigator.mediaDevices!
              .getUserMedia({'video': true, 'audio': true})
              .then((stream) {
                if (mounted) {
                  _mediaStream = stream;
                  video.srcObject = stream;
                }
              })
              .catchError((error) {
                print('Error accessing camera: $error');
              });

          return video;
        });
      } catch (e) {
        // View factory already registered, ignore
        print('View factory already registered: $e');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Test Equipment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Real Video Preview Area with getUserMedia
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981), width: 3),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _cameraEnabled
                        ? HtmlElementView(
                            viewType:
                                'doctor-camera-preview-${widget.consultation.id}',
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Camera Off',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: _cameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          onPressed: () {
                            setState(() {
                              _cameraEnabled = !_cameraEnabled;
                            });
                          },
                          isActive: _cameraEnabled,
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          icon: _micEnabled ? Icons.mic : Icons.mic_off,
                          onPressed: () {
                            setState(() {
                              _micEnabled = !_micEnabled;
                            });
                          },
                          isActive: _micEnabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Consultation Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.consultation.patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Video Consultation',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Patient Status
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('videoConsultations')
                  .doc(widget.consultation.id)
                  .snapshots(),
              builder: (context, consultSnapshot) {
                final consultData =
                    consultSnapshot.data?.data() as Map<String, dynamic>?;
                final patientWaiting =
                    consultData?['patientInWaitingRoom'] ?? false;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: patientWaiting
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (patientWaiting
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF7C3AED))
                                .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          patientWaiting
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_empty_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientWaiting
                                  ? 'Patient is waiting!'
                                  : 'Waiting for patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patientWaiting
                                  ? 'You can start the call now'
                                  : 'Patient will join soon',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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

            const SizedBox(height: 24),

            // Test Equipment Button
            ElevatedButton.icon(
              onPressed: _testEquipment,
              icon: Icon(_isTesting ? Icons.stop : Icons.mic_none_rounded),
              label: Text(_isTesting ? 'Stop Testing' : 'Test Microphone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTesting
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF374151),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Before you start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                    'Make sure your camera and microphone are working properly',
                  ),
                  _buildTip('Find a quiet place with good lighting'),
                  _buildTip('Check your internet connection is stable'),
                  _buildTip('Have patient records ready if needed'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Start Call Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.video_call_rounded, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Start Video Call',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? Colors.white : Colors.red,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _testEquipment() {
    setState(() {
      _isTesting = !_isTesting;
    });

    if (_isTesting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _micEnabled ? Icons.mic : Icons.mic_off,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _micEnabled
                      ? 'Testing microphone... Speak now to test'
                      : 'Microphone is off. Turn it on to test',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _micEnabled
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _startCall() async {
    // Update status to inProgress and set doctorReady
    await FirebaseFirestore.instance
        .collection('videoConsultations')
        .doc(widget.consultation.id)
        .update({
          'status': 'in_progress',
          'callStartedAt': FieldValue.serverTimestamp(),
          'doctorReady': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoCallPage(consultation: widget.consultation, isDoctor: true),
        ),
      );
    }
  }
}
