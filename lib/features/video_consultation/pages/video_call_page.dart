import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../models/video_consultation.dart';
import 'dart:async';

// Conditional imports for web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

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
  final _jitsiMeetPlugin = JitsiMeet();
  bool _hasJoined = false;
  DateTime? _callStartTime;
  String? _viewId;
  StreamSubscription<DocumentSnapshot>? _consultationListener;
  bool _callEndedByOther = false;
  Timer? _autoCompleteTimer;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _updateConsultationStatus('in_progress');
    _listenToConsultationStatus();
    _startAutoCompleteCheck();

    if (kIsWeb) {
      _initializeWebView();
    } else {
      _joinMeeting();
    }
  }

  void _startAutoCompleteCheck() {
    // Check every 30 seconds if the consultation should be auto-completed
    _autoCompleteTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAutoComplete();
    });
  }

  Future<void> _checkAutoComplete() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final endTime = (data['endTime'] as Timestamp?)?.toDate();

      // If consultation is in progress and current time is past the scheduled end time
      if (status == 'in_progress' &&
          endTime != null &&
          DateTime.now().isAfter(endTime)) {
        print('🔄 Auto-completing consultation (past scheduled end time)');
        await _endCall();
      }
    } catch (e) {
      print('Error checking auto-complete: $e');
    }
  }

  @override
  void dispose() {
    _autoCompleteTimer?.cancel();
    _consultationListener?.cancel();
    if (!kIsWeb) {
      _jitsiMeetPlugin.hangUp();
    }
    super.dispose();
  }

  void _initializeWebView() {
    final roomName =
        'meddoc${widget.consultation.appointmentId.replaceAll('-', '')}';
    final displayName = Uri.encodeComponent(
      widget.isDoctor
          ? 'Dr. ${widget.consultation.doctorName}'
          : widget.consultation.patientName,
    );

    _viewId = 'jitsi-meet-${widget.consultation.id}';

    // Create iframe element with properly formatted Jitsi Meet URL and permissions
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId!, (int viewId) {
      final iframe = html.IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..src =
            'https://meet.jit.si/$roomName#config.prejoinPageEnabled=false&config.startWithAudioMuted=false&config.startWithVideoMuted=false&userInfo.displayName=$displayName'
        ..style.border = 'none'
        ..setAttribute(
          'allow',
          'camera *; microphone *; fullscreen *; display-capture *; autoplay *; clipboard-write',
        )
        ..allowFullscreen = true;

      // Listen for iframe load
      iframe.onLoad.listen((_) {
        setState(() {
          _hasJoined = true;
        });
      });

      return iframe;
    });
  }

  Future<void> _joinMeeting() async {
    try {
      // Generate room name from appointment ID
      final roomName = 'meddoc_${widget.consultation.appointmentId}';

      // Configure Jitsi Meet options
      var options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: roomName,
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': false,
          'subject': widget.isDoctor
              ? 'Consultation with ${widget.consultation.patientName}'
              : 'Consultation with Dr. ${widget.consultation.doctorName}',
        },
        featureFlags: {
          'unsaferoomwarning.enabled': false,
          'prejoinpage.enabled': false,
          'invite.enabled': false,
          'recording.enabled': false,
          'live-streaming.enabled': false,
          'meeting-password.enabled': false,
          'pip.enabled': true,
          'tile-view.enabled': true,
          'toolbox.alwaysVisible': false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: widget.isDoctor
              ? 'Dr. ${widget.consultation.doctorName}'
              : widget.consultation.patientName,
          email: '',
          avatar: '',
        ),
      );

      // Listen to conference events
      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint('Conference joined: $url');
          setState(() {
            _hasJoined = true;
            _callStartTime = DateTime.now();
          });

          // Update Firestore status
          _updateConsultationStatus('in_progress');
        },
        conferenceTerminated: (url, error) {
          debugPrint('Conference terminated: $url, error: $error');
          _endCall();
        },
        conferenceWillJoin: (url) {
          debugPrint('Conference will join: $url');
        },
        participantJoined: (email, name, role, participantId) {
          debugPrint('Participant joined: $name');
        },
        participantLeft: (participantId) {
          debugPrint('Participant left: $participantId');
        },
        audioMutedChanged: (muted) {
          debugPrint('Audio muted: $muted');
        },
        videoMutedChanged: (muted) {
          debugPrint('Video muted: $muted');
        },
        endpointTextMessageReceived: (senderId, message) {
          debugPrint('Message received: $message from $senderId');
        },
        screenShareToggled: (participantId, sharing) {
          debugPrint('Screen share toggled: $sharing by $participantId');
        },
        chatMessageReceived: (senderId, message, isPrivate, timestamp) {
          debugPrint('Chat message received: $message');
        },
        chatToggled: (isOpen) {
          debugPrint('Chat toggled: $isOpen');
        },
        participantsInfoRetrieved: (participantsInfo) {
          debugPrint('Participants info: $participantsInfo');
        },
        readyToClose: () {
          debugPrint('Ready to close');
          _endCall();
        },
      );

      await _jitsiMeetPlugin.join(options, listener);
    } catch (e) {
      debugPrint('Error joining meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _updateConsultationStatus(String status) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'in_progress' && _callStartTime != null) {
        updateData['callStartedAt'] = Timestamp.fromDate(_callStartTime!);
      } else if (status == 'completed') {
        updateData['callEndedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update(updateData);
    } catch (e) {
      debugPrint('Error updating consultation status: $e');
    }
  }

  Future<void> _endCall() async {
    await _updateConsultationStatus('completed');

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show post-call dialog after navigation is complete
      if (widget.isDoctor) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showPostCallDialog();
          }
        });
      }
    }
  }

  void _listenToConsultationStatus() {
    _consultationListener = FirebaseFirestore.instance
        .collection('videoConsultations')
        .doc(widget.consultation.id)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data();
          if (data == null) return;

          // Check if status changed to completed
          if (data['status'] == 'completed' &&
              !_callEndedByOther &&
              _hasJoined) {
            _callEndedByOther = true;
            _showCallEndedByOtherDialog();
          }
        });
  }

  void _showPostCallDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Consultation Completed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Would you like to add notes or prescription for this consultation?',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Later',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNotesDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Add Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    // Only allow doctors to add notes
    if (!widget.isDoctor) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Only doctors can add consultation notes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final notesController = TextEditingController(
      text: widget.consultation.notes ?? '',
    );

    // Use the root navigator context to ensure dialog stays open
    final dialogContext = Navigator.of(context, rootNavigator: true).context;

    showDialog(
      context: dialogContext,
      barrierDismissible: false, // Prevent closing when clicking outside
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Consultation Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${widget.consultation.patientName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'Enter consultation notes, diagnosis, recommendations...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final notes = notesController.text.trim();
                if (notes.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter consultation notes'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('videoConsultations')
                    .doc(widget.consultation.id)
                    .update({
                      'notes': notes,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Notes saved successfully',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving notes: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save Notes',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _showEndCallDialog(context),
        ),
        title: Text(
          widget.isDoctor
              ? widget.consultation.patientName
              : 'Dr. ${widget.consultation.doctorName}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.isDoctor)
            IconButton(
              icon: const Icon(Icons.note_add, color: Colors.white),
              onPressed: _showNotesDialog,
              tooltip: 'Add Notes',
            ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () => _showEndCallDialog(context),
            tooltip: 'End Call',
          ),
        ],
      ),
      body: kIsWeb
          ? _hasJoined
                ? HtmlElementView(viewType: _viewId!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C3AED),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Loading video call...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _hasJoined ? 'Connected' : 'Connecting to video call...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isDoctor
                        ? widget.consultation.patientName
                        : 'Dr. ${widget.consultation.doctorName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showEndCallDialog(BuildContext context) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Consultation?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to end this video consultation?',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'End Call',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      await _endCall();
    }
  }

  void _showCallEndedByOtherDialog() {
    if (!mounted) return;

    final otherPartyName = widget.isDoctor
        ? widget.consultation.patientName
        : 'Dr. ${widget.consultation.doctorName}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Call Ended',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            '$otherPartyName has ended the video consultation.',
            style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
