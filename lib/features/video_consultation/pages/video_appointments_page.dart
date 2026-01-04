import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_consultation.dart';
import '../widgets/video_consultation_card.dart';

class VideoAppointmentsPage extends StatefulWidget {
  final bool isDoctor;

  const VideoAppointmentsPage({super.key, required this.isDoctor});

  @override
  State<VideoAppointmentsPage> createState() => _VideoAppointmentsPageState();
}

class _VideoAppointmentsPageState extends State<VideoAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Consultations')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Consultations',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videoConsultations')
            .where(
              widget.isDoctor ? 'doctorId' : 'patientId',
              isEqualTo: userId,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_call_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Video Consultations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isDoctor
                        ? 'Your patients haven\'t scheduled any consultations yet'
                        : 'You haven\'t scheduled any video consultations',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final allConsultations = snapshot.data!.docs
              .map((doc) => VideoConsultation.fromFirestore(doc))
              .toList();

          // Separate consultations into three categories based on date/time
          final activeConsultations = allConsultations.where((c) {
            return (c.status == VideoConsultationStatus.inProgress ||
                c.status == VideoConsultationStatus.patientWaiting);
          }).toList();

          final upcomingConsultations = allConsultations.where((c) {
            // Upcoming: scheduled status AND scheduled time is in the future
            return c.status == VideoConsultationStatus.scheduled &&
                c.scheduledTime.isAfter(now);
          }).toList();

          final completedConsultations = allConsultations.where((c) {
            // Completed: either marked as completed OR (scheduled with both scheduled time and end time in the past)
            if (c.status == VideoConsultationStatus.completed) return true;

            // Only mark as completed if it's scheduled but BOTH scheduled time and end time have passed
            if (c.status == VideoConsultationStatus.scheduled) {
              return c.scheduledTime.isBefore(now) && c.endTime.isBefore(now);
            }

            return false;
          }).toList();

          // Sort each category
          activeConsultations.sort(
            (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
          );
          upcomingConsultations.sort(
            (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
          );
          completedConsultations.sort(
            (a, b) => b.scheduledTime.compareTo(a.scheduledTime),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeConsultations.isNotEmpty) ...[
                _buildSectionHeader(
                  'Active Now',
                  Icons.videocam_rounded,
                  const Color(0xFFEF4444),
                  activeConsultations.length,
                ),
                const SizedBox(height: 12),
                ...activeConsultations.map(
                  (consultation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationCard(consultation),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (upcomingConsultations.isNotEmpty) ...[
                _buildSectionHeader(
                  'Upcoming',
                  Icons.schedule_rounded,
                  const Color(0xFF7C3AED),
                  upcomingConsultations.length,
                ),
                const SizedBox(height: 12),
                ...upcomingConsultations.map(
                  (consultation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationCard(consultation),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (completedConsultations.isNotEmpty) ...[
                _buildSectionHeader(
                  'Completed',
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                  completedConsultations.length,
                ),
                const SizedBox(height: 12),
                ...completedConsultations.map(
                  (consultation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConsultationCard(consultation),
                  ),
                ),
              ],
              if (activeConsultations.isEmpty &&
                  upcomingConsultations.isEmpty &&
                  completedConsultations.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.video_call_rounded,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Video Consultations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationCard(VideoConsultation consultation) {
    final isCompleted =
        consultation.status == VideoConsultationStatus.completed;
    final isActive =
        consultation.status == VideoConsultationStatus.inProgress ||
        consultation.status == VideoConsultationStatus.patientWaiting;

    return Stack(
      children: [
        VideoConsultationCard(
          consultation: consultation,
          isPatient: !widget.isDoctor,
        ),
        // Delete button only for completed
        if (isCompleted)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              onPressed: () => _showDeleteDialog(consultation),
            ),
          ),
        // Active indicator for live consultations
        if (isActive)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeleteDialog(VideoConsultation consultation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Consultation'),
        content: const Text(
          'Are you sure you want to delete this completed consultation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteConsultation(consultation.id);
    }
  }

  Future<void> _deleteConsultation(String consultationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(consultationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting consultation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
