import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/video_consultation.dart';

class ConsultationDocumentsPage extends StatefulWidget {
  final VideoConsultation consultation;
  final bool isDoctor;

  const ConsultationDocumentsPage({
    super.key,
    required this.consultation,
    required this.isDoctor,
  });

  @override
  State<ConsultationDocumentsPage> createState() =>
      _ConsultationDocumentsPageState();
}

class _ConsultationDocumentsPageState extends State<ConsultationDocumentsPage> {
  bool _uploading = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.consultation.notes ?? '';
    _prescriptionController.text = widget.consultation.prescription ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _uploading = true);

        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes == null) {
          throw Exception('No file data');
        }

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child(
          'consultation_documents/${widget.consultation.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        );

        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: _getContentType(file.extension ?? ''),
            customMetadata: {
              'consultationId': widget.consultation.id,
              'uploadedBy': widget.isDoctor ? 'doctor' : 'patient',
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Add URL to Firestore
        final currentDocs = widget.consultation.documents ?? [];
        await FirebaseFirestore.instance
            .collection('videoConsultations')
            .doc(widget.consultation.id)
            .update({
              'documents': FieldValue.arrayUnion([downloadUrl]),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _saveNotes() async {
    if (!widget.isDoctor) return;

    try {
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update({
            'notes': _notesController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save notes: $e')));
      }
    }
  }

  Future<void> _savePrescription() async {
    if (!widget.isDoctor) return;

    try {
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update({
            'prescription': _prescriptionController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prescription saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save prescription: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(String url) async {
    try {
      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('videoConsultations')
          .doc(widget.consultation.id)
          .update({
            'documents': FieldValue.arrayRemove([url]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Delete from Storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Document deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Details'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videoConsultations')
            .doc(widget.consultation.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final documents = data?['documents'] as List? ?? [];
          final notes = data?['notes'] as String? ?? '';
          final prescription = data?['prescription'] as String? ?? '';

          // Update controllers if data changed
          if (_notesController.text != notes && notes.isNotEmpty) {
            _notesController.text = notes;
          }
          if (_prescriptionController.text != prescription &&
              prescription.isNotEmpty) {
            _prescriptionController.text = prescription;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consultation Info Card
                _buildInfoCard(),
                const SizedBox(height: 24),

                // Doctor Notes Section (only for doctors)
                if (widget.isDoctor) ...[
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                ],

                // Prescription Section (only for doctors)
                if (widget.isDoctor) ...[
                  _buildPrescriptionSection(),
                  const SizedBox(height: 24),
                ],

                // View-only notes and prescription for patients
                if (!widget.isDoctor && notes.isNotEmpty) ...[
                  _buildViewOnlyNotes(notes),
                  const SizedBox(height: 24),
                ],

                if (!widget.isDoctor && prescription.isNotEmpty) ...[
                  _buildViewOnlyPrescription(prescription),
                  const SizedBox(height: 24),
                ],

                // Documents Section
                _buildDocumentsSection(documents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDoctor
                  ? 'Patient: ${widget.consultation.patientName}'
                  : 'Doctor: ${widget.consultation.doctorName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!widget.isDoctor)
              Text('Specialty: ${widget.consultation.doctorSpecialty}'),
            Text('Date: ${_formatDate(widget.consultation.scheduledTime)}'),
            Text(
              'Time: ${_formatTime(widget.consultation.scheduledTime)} - ${_formatTime(widget.consultation.endTime)}',
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (widget.consultation.status) {
      case VideoConsultationStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case VideoConsultationStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case VideoConsultationStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.orange;
        text = 'Scheduled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter consultation notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveNotes,
              icon: const Icon(Icons.save),
              label: const Text('Save Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prescriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter prescription details...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _savePrescription,
              icon: const Icon(Icons.save),
              label: const Text('Save Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOnlyNotes(String notes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(notes),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOnlyPrescription(String prescription) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(prescription),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(List documents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (widget.isDoctor)
                  ElevatedButton.icon(
                    onPressed: _uploading ? null : _pickAndUploadDocument,
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_uploading ? 'Uploading...' : 'Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (documents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No documents uploaded yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final docUrl = documents[index] as String;
                  final fileName = _extractFileName(docUrl);
                  return ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Color(0xFF7C3AED),
                    ),
                    title: Text(fileName),
                    trailing: widget.isDoctor
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(docUrl),
                          )
                        : null,
                    onTap: () => _openDocument(docUrl),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments.last;
      // Remove timestamp prefix if present
      final parts = path.split('_');
      if (parts.length > 1) {
        return parts.sublist(1).join('_');
      }
      return path;
    } catch (e) {
      return 'Document';
    }
  }

  void _openDocument(String url) {
    // Open document in browser
    // For web, you can use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening document...'),
        action: SnackBarAction(
          label: 'Copy Link',
          onPressed: () {
            // Copy to clipboard functionality
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument(url);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
