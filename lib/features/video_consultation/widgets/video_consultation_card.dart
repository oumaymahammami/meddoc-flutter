import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/video_consultation.dart';
import '../pages/waiting_room_page.dart';
import '../pages/video_call_page.dart';
import '../pages/consultation_documents_page.dart';

class VideoConsultationCard extends StatelessWidget {
  final VideoConsultation consultation;
  final bool isPatient;

  const VideoConsultationCard({
    Key? key,
    required this.consultation,
    this.isPatient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.video_call_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video Consultation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            isPatient
                                ? consultation.doctorName
                                : consultation.patientName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isPatient) _buildSpecialtyChip(),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  isPatient ? consultation.doctorSpecialty : 'Patient',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  DateFormat('MMM dd, yyyy').format(consultation.scheduledTime),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  '${DateFormat('HH:mm').format(consultation.scheduledTime)} - ${DateFormat('HH:mm').format(consultation.endTime)}',
                ),
                if (consultation.status ==
                        VideoConsultationStatus.patientWaiting &&
                    !isPatient) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Colors.black87,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Patient is waiting',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: _buildActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color color;

    switch (consultation.status) {
      case VideoConsultationStatus.scheduled:
        label = 'Scheduled';
        color = Colors.white;
        break;
      case VideoConsultationStatus.patientWaiting:
        label = 'Waiting';
        color = Colors.amber;
        break;
      case VideoConsultationStatus.inProgress:
        label = 'In Progress';
        color = Colors.green;
        break;
      case VideoConsultationStatus.completed:
        label = 'Completed';
        color = Colors.grey;
        break;
      default:
        label = 'Scheduled';
        color = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSpecialtyChip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        consultation.doctorSpecialty,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    VoidCallback? onPressed;
    IconData icon;
    Color buttonColor = Colors.white;
    Color textColor = const Color(0xFF7C3AED);

    final now = DateTime.now();
    final canEnter = consultation.canEnterWaitingRoom;

    if (consultation.status == VideoConsultationStatus.completed) {
      buttonText = isPatient ? 'View Summary' : 'View Details';
      icon = Icons.description_outlined;
      onPressed = () => _viewSummary(context);
    } else if (consultation.status == VideoConsultationStatus.inProgress) {
      buttonText = 'Join Call';
      icon = Icons.video_call_rounded;
      buttonColor = Colors.green;
      textColor = Colors.white;
      onPressed = () => _joinCall(context);
    } else if (!isPatient &&
        consultation.status == VideoConsultationStatus.patientWaiting) {
      buttonText = 'Start Call';
      icon = Icons.play_arrow_rounded;
      buttonColor = Colors.green;
      textColor = Colors.white;
      onPressed = () => _startCall(context);
    } else if (isPatient &&
        consultation.status == VideoConsultationStatus.patientWaiting) {
      buttonText = 'In Waiting Room';
      icon = Icons.hourglass_empty_rounded;
      onPressed = () => _openWaitingRoom(context);
    } else if (isPatient &&
        consultation.status == VideoConsultationStatus.scheduled) {
      // Always allow entry for scheduled consultations
      buttonText = 'Enter Waiting Room';
      icon = Icons.video_call_rounded;
      buttonColor = const Color(0xFF10B981);
      textColor = Colors.white;
      onPressed = () => _enterWaitingRoom(context);
    } else {
      final minutesUntil = consultation.scheduledTime.difference(now).inMinutes;
      if (minutesUntil > 60) {
        buttonText =
            'Starts in ${(minutesUntil / 60).ceil()}h ${minutesUntil % 60}m';
      } else if (minutesUntil > 0) {
        buttonText = 'Starts in $minutesUntil minutes';
      } else {
        buttonText = 'Starting soon';
      }
      icon = Icons.schedule_rounded;
      onPressed = null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          buttonText,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _enterWaitingRoom(BuildContext context) async {
    // Update status to patientWaiting
    await FirebaseFirestore.instance
        .collection('videoConsultations')
        .doc(consultation.id)
        .update({
          'status': 'patient_waiting',
          'patientInWaitingRoom': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomPage(consultation: consultation),
        ),
      );
    }
  }

  void _startCall(BuildContext context) async {
    // Update status to inProgress
    await FirebaseFirestore.instance
        .collection('videoConsultations')
        .doc(consultation.id)
        .update({
          'status': 'in_progress',
          'callStartedAt': FieldValue.serverTimestamp(),
          'doctorReady': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoCallPage(consultation: consultation, isDoctor: true),
        ),
      );
    }
  }

  void _joinCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCallPage(consultation: consultation, isDoctor: !isPatient),
      ),
    );
  }

  void _viewSummary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationDocumentsPage(
          consultation: consultation,
          isDoctor: !isPatient,
        ),
      ),
    );
  }

  void _openWaitingRoom(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingRoomPage(consultation: consultation),
      ),
    );
  }
}
