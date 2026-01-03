import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/video_consultation.dart';

class VideoCallPage extends StatefulWidget {
  final VideoConsultation consultation;
  final bool isDoctor;

  const VideoCallPage({
    Key? key,
    required this.consultation,
    required this.isDoctor,
  }) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _startCallDurationTimer();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startCallDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main video feed
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: Colors.white.withOpacity(0.5),
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isDoctor
                            ? widget.consultation.patientName
                            : 'Dr. ${widget.consultation.doctorName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_callDuration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Self video preview
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 60 : -200,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                ),
                child: Center(
                  child: Icon(
                    _isVideoOff ? Icons.videocam_off : Icons.person,
                    color: Colors.white.withOpacity(0.7),
                    size: 40,
                  ),
                ),
              ),
            ),

            // Top bar with info
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.isDoctor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.consultation.patientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -150,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      isActive: !_isMuted,
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                    ),
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      label: _isVideoOff ? 'Turn On' : 'Turn Off',
                      isActive: !_isVideoOff,
                      onPressed: () {
                        setState(() {
                          _isVideoOff = !_isVideoOff;
                        });
                      },
                    ),
                    _buildEndCallButton(),
                    if (widget.isDoctor)
                      _buildControlButton(
                        icon: Icons.note_add,
                        label: 'Notes',
                        isActive: true,
                        onPressed: _showNotesDialog,
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
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.2)
                : Colors.red.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.white : Colors.red,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, size: 28),
            color: isActive ? Colors.white : Colors.red,
            onPressed: onPressed,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.call_end, size: 32),
            color: Colors.white,
            onPressed: _endCall,
            padding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End Call',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showNotesDialog() {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your notes here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('videoConsultations')
                  .doc(widget.consultation.id)
                  .update({
                    'notes': notesController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Notes saved')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _endCall() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Consultation?'),
        content: const Text(
          'Are you sure you want to end this video consultation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      // Update consultation status
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update({
            'status': 'completed',
            'callEndedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        if (widget.isDoctor) {
          _showPostCallDialog();
        }
      }
    }
  }

  void _showPostCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Completed'),
        content: const Text(
          'Would you like to add notes or prescription for this consultation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to prescription/notes page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prescription feature coming soon'),
                ),
              );
            },
            child: const Text('Add Details'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours != '00' ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
