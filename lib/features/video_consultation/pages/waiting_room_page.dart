import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_consultation.dart';
import 'video_call_page.dart';

class WaitingRoomPage extends StatefulWidget {
  final VideoConsultation consultation;

  const WaitingRoomPage({Key? key, required this.consultation})
    : super(key: key);

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  bool _cameraEnabled = true;
  bool _micEnabled = true;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Waiting Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => _exitWaitingRoom(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videoConsultations')
            .doc(widget.consultation.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final status = data?['status'] as String?;

            // If call has started, automatically join
            if (status == 'in_progress' && mounted) {
              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallPage(
                      consultation: widget.consultation,
                      isDoctor: false,
                    ),
                  ),
                );
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Video Preview Area
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7C3AED),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _cameraEnabled
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cameraEnabled ? 'Camera Preview' : 'Camera Off',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consultation with',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dr. ${widget.consultation.doctorName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.consultation.doctorSpecialty,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Waiting Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waiting for doctor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'The doctor will start the call soon',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Test Equipment Button
                OutlinedButton.icon(
                  onPressed: _testEquipment,
                  icon: Icon(
                    _isTesting ? Icons.stop_circle : Icons.play_circle_outline,
                    size: 20,
                  ),
                  label: Text(
                    _isTesting ? 'Stop Test' : 'Test Camera & Microphone',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tips for a better consultation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('Find a quiet place with good lighting'),
                      _buildTip('Test your camera and microphone'),
                      _buildTip('Have your medical documents ready'),
                      _buildTip('Write down your questions beforehand'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            ? Colors.white.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : Colors.red,
          width: 2,
        ),
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
        const SnackBar(
          content: Text('Testing equipment... Speak to test your microphone'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _exitWaitingRoom() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Waiting Room?'),
        content: const Text(
          'You will need to re-enter the waiting room to join the consultation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // Update status back to scheduled
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update({
            'status': 'scheduled',
            'patientInWaitingRoom': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
