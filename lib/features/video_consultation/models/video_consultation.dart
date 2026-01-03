import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoConsultationStatus {
  scheduled,
  patientWaiting,
  doctorReady,
  inProgress,
  completed,
  cancelled,
}

class VideoConsultation {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientId;
  final String patientName;
  final DateTime scheduledTime;
  final DateTime endTime;
  final VideoConsultationStatus status;
  final String? roomId;
  final bool patientInWaitingRoom;
  final bool doctorReady;
  final DateTime? callStartedAt;
  final DateTime? callEndedAt;
  final String? notes;
  final String? prescription;
  final List<String>? documents;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoConsultation({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientId,
    required this.patientName,
    required this.scheduledTime,
    required this.endTime,
    required this.status,
    this.roomId,
    this.patientInWaitingRoom = false,
    this.doctorReady = false,
    this.callStartedAt,
    this.callEndedAt,
    this.notes,
    this.prescription,
    this.documents,
    this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoConsultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoConsultation(
      id: doc.id,
      appointmentId: data['appointmentId'] as String,
      doctorId: data['doctorId'] as String,
      doctorName: data['doctorName'] as String,
      doctorSpecialty: data['doctorSpecialty'] as String? ?? 'General',
      patientId: data['patientId'] as String,
      patientName: data['patientName'] as String,
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: _parseStatus(data['status'] as String? ?? 'scheduled'),
      roomId: data['roomId'] as String?,
      patientInWaitingRoom: data['patientInWaitingRoom'] as bool? ?? false,
      doctorReady: data['doctorReady'] as bool? ?? false,
      callStartedAt: data['callStartedAt'] != null
          ? (data['callStartedAt'] as Timestamp).toDate()
          : null,
      callEndedAt: data['callEndedAt'] != null
          ? (data['callEndedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
      prescription: data['prescription'] as String?,
      documents: data['documents'] != null
          ? List<String>.from(data['documents'] as List)
          : null,
      rating: data['rating'] as int?,
      feedback: data['feedback'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'patientId': patientId,
      'patientName': patientName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': _statusToString(status),
      'roomId': roomId,
      'patientInWaitingRoom': patientInWaitingRoom,
      'doctorReady': doctorReady,
      'callStartedAt': callStartedAt != null
          ? Timestamp.fromDate(callStartedAt!)
          : null,
      'callEndedAt': callEndedAt != null
          ? Timestamp.fromDate(callEndedAt!)
          : null,
      'notes': notes,
      'prescription': prescription,
      'documents': documents,
      'rating': rating,
      'feedback': feedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VideoConsultation copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? patientId,
    String? patientName,
    DateTime? scheduledTime,
    DateTime? endTime,
    VideoConsultationStatus? status,
    String? roomId,
    bool? patientInWaitingRoom,
    bool? doctorReady,
    DateTime? callStartedAt,
    DateTime? callEndedAt,
    String? notes,
    String? prescription,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoConsultation(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      patientInWaitingRoom: patientInWaitingRoom ?? this.patientInWaitingRoom,
      doctorReady: doctorReady ?? this.doctorReady,
      callStartedAt: callStartedAt ?? this.callStartedAt,
      callEndedAt: callEndedAt ?? this.callEndedAt,
      notes: notes ?? this.notes,
      prescription: prescription ?? this.prescription,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get canEnterWaitingRoom {
    final now = DateTime.now();
    final timeUntilAppointment = scheduledTime.difference(now);
    return timeUntilAppointment.inMinutes <= 15 &&
        status == VideoConsultationStatus.scheduled;
  }

  bool get isScheduledSoon {
    final now = DateTime.now();
    final timeUntilAppointment = scheduledTime.difference(now);
    return timeUntilAppointment.inMinutes <= 60 &&
        timeUntilAppointment.inMinutes > 0;
  }

  static VideoConsultationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return VideoConsultationStatus.scheduled;
      case 'patient_waiting':
        return VideoConsultationStatus.patientWaiting;
      case 'doctor_ready':
        return VideoConsultationStatus.doctorReady;
      case 'in_progress':
        return VideoConsultationStatus.inProgress;
      case 'completed':
        return VideoConsultationStatus.completed;
      case 'cancelled':
        return VideoConsultationStatus.cancelled;
      default:
        return VideoConsultationStatus.scheduled;
    }
  }

  static String _statusToString(VideoConsultationStatus status) {
    switch (status) {
      case VideoConsultationStatus.scheduled:
        return 'scheduled';
      case VideoConsultationStatus.patientWaiting:
        return 'patient_waiting';
      case VideoConsultationStatus.doctorReady:
        return 'doctor_ready';
      case VideoConsultationStatus.inProgress:
        return 'in_progress';
      case VideoConsultationStatus.completed:
        return 'completed';
      case VideoConsultationStatus.cancelled:
        return 'cancelled';
    }
  }
}
