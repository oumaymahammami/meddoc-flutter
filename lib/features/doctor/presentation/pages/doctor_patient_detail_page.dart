import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorPatientDetailPage extends StatefulWidget {
  final String patientId;
  const DoctorPatientDetailPage({super.key, required this.patientId});

  @override
  State<DoctorPatientDetailPage> createState() =>
      _DoctorPatientDetailPageState();
}

class _DoctorPatientDetailPageState extends State<DoctorPatientDetailPage> {
  late final String _doctorId;

  @override
  void initState() {
    super.initState();
    _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_doctorId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Premium App Bar with Patient Info
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2E63D9),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E63D9), Color(0xFF1E40AF)],
                  ),
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.patientId)
                      .get(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final name =
                        data?['name'] ?? data?['fullName'] ?? 'Patient';
                    final email = data?['email'] ?? '';
                    final initials = name
                        .toString()
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                        .join('');

                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF2E63D9),
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (email.toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppointmentHistory(),
                  const SizedBox(height: 24),
                  _buildMedications(),
                  const SizedBox(height: 24),
                  _buildMedicalReports(),
                  const SizedBox(height: 24),
                  _buildNotes(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistory() {
    final query = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: widget.patientId)
        .orderBy('startTime', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        // Show loading only on first load
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final docs = snap.data?.docs ?? [];

        return _AppointmentHistorySection(
          appointments: docs,
          doctorId: _doctorId,
          patientId: widget.patientId,
        );
      },
    );
  }

  Widget _buildMedications() {
    final medicationsRef = FirebaseFirestore.instance
        .collection('doctorPatients')
        .doc(_doctorId)
        .collection('patients')
        .doc(widget.patientId)
        .collection('medications')
        .orderBy('prescribedAt', descending: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Medications Prescribed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: medicationsRef.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const _CardContainer(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              return _CardContainer(
                child: Center(child: Text('Error: ${snap.error}')),
              );
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No medications prescribed yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown';
                final dosage = data['dosage'] ?? '';
                final frequency = data['frequency'] ?? '';
                final duration = data['duration'] ?? '';
                final instructions = data['instructions'] ?? '';
                final prescribedAt = (data['prescribedAt'] as Timestamp?)
                    ?.toDate();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF34D399),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  if (dosage.isNotEmpty)
                                    Text(
                                      dosage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => d.reference.delete(),
                            ),
                          ],
                        ),
                        if (frequency.isNotEmpty || duration.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (frequency.isNotEmpty) ...[
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    frequency,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (frequency.isNotEmpty && duration.isNotEmpty)
                                  const SizedBox(width: 16),
                                if (duration.isNotEmpty) ...[
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    duration,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (instructions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            instructions,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (prescribedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Prescribed: ${DateFormat('MMM d, yyyy').format(prescribedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addMedication,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Prescribe Medication'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addMedication() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final frequencyCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Gradient Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescribe Medication',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fill in prescription details',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: nameCtrl,
                        label: 'Medication Name *',
                        hint: 'e.g., Amoxicillin',
                        icon: Icons.medication_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: dosageCtrl,
                        label: 'Dosage',
                        hint: 'e.g., 500mg',
                        icon: Icons.speed_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: frequencyCtrl,
                        label: 'Frequency',
                        hint: 'e.g., 3 times daily',
                        icon: Icons.access_time_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: durationCtrl,
                        label: 'Duration',
                        hint: 'e.g., 7 days',
                        icon: Icons.calendar_today_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: instructionsCtrl,
                        label: 'Instructions',
                        hint: 'Special instructions for the patient',
                        icon: Icons.subject_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Color(0xFF10B981),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Please enter medication name'),
                                  ],
                                ),
                                backgroundColor: Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final ref = FirebaseFirestore.instance
                              .collection('doctorPatients')
                              .doc(_doctorId)
                              .collection('patients')
                              .doc(widget.patientId)
                              .collection('medications')
                              .doc();

                          // Get doctor name from doctors collection
                          final doctorDoc = await FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(_doctorId)
                              .get();

                          print('🔍 Doctor doc exists: ${doctorDoc.exists}');
                          print('🔍 Doctor data: ${doctorDoc.data()}');

                          String doctorName = 'Doctor';
                          if (doctorDoc.exists && doctorDoc.data() != null) {
                            final data = doctorDoc.data()!;
                            doctorName =
                                data['fullName'] ?? data['name'] ?? 'Doctor';
                            print('✅ Doctor name found: $doctorName');
                          } else {
                            print('❌ No doctor document found for $_doctorId');
                          }

                          await ref.set({
                            'name': nameCtrl.text.trim(),
                            'dosage': dosageCtrl.text.trim(),
                            'frequency': frequencyCtrl.text.trim(),
                            'duration': durationCtrl.text.trim(),
                            'instructions': instructionsCtrl.text.trim(),
                            'prescribedAt': FieldValue.serverTimestamp(),
                            'prescribedBy': _doctorId,
                            'prescribedByName': doctorName,
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Prescribed ${nameCtrl.text.trim()} successfully',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Prescribe',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== MEDICAL REPORTS SECTION =====
  Widget _buildMedicalReports() {
    final reportsRef = FirebaseFirestore.instance
        .collection('medicalReports')
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: widget.patientId);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical Reports',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Patient documents and reports',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddReportDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'New Report',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF10B981),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: reportsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Sort in memory to avoid composite index requirement
                final sortedDocs = docs.toList();
                sortedDocs.sort((a, b) {
                  final aTime =
                      (a.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  final bTime =
                      (b.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;

                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.compareTo(
                    aTime,
                  ); // descending order (newest first)
                });

                if (sortedDocs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Medical Reports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a medical report for this patient',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDocs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data =
                        sortedDocs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled Report';
                    final content = data['content'] ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();
                    final reportType = data['reportType'] ?? 'General';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  reportType,
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (createdAt != null)
                                Text(
                                  DateFormat('MMM d, yyyy').format(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (content.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _viewReport(sortedDocs[index]),
                                  icon: const Icon(
                                    Icons.visibility_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'View',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF10B981),
                                    side: const BorderSide(
                                      color: Color(0xFF10B981),
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () =>
                                    _deleteReport(sortedDocs[index].id),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: Colors.red[400],
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReportDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String reportType = 'General';
    final reportTypes = [
      'General',
      'Consultation',
      'Lab Results',
      'Imaging',
      'Prescription',
      'Follow-up',
      'Discharge Summary',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'New Medical Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: reportType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        items: reportTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => reportType = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Routine Checkup Report',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Report Content',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter detailed medical report...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                try {
                  // Get doctor name and specialty from doctors collection
                  final doctorDoc = await FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(_doctorId)
                      .get();

                  print('🔍 Report - Doctor doc exists: ${doctorDoc.exists}');
                  print('🔍 Report - Doctor data: ${doctorDoc.data()}');

                  String doctorName = 'Doctor';
                  String specialty = '';

                  if (doctorDoc.exists && doctorDoc.data() != null) {
                    final data = doctorDoc.data()!;
                    doctorName = data['fullName'] ?? data['name'] ?? 'Doctor';
                    specialty = data['specialty'] ?? '';
                    print(
                      '✅ Report - Doctor name: $doctorName, Specialty: $specialty',
                    );
                  } else {
                    print('❌ Report - No doctor document found for $_doctorId');
                  }

                  await FirebaseFirestore.instance
                      .collection('medicalReports')
                      .add({
                        'doctorId': _doctorId,
                        'doctorName': doctorName,
                        'doctorSpecialty': specialty,
                        'patientId': widget.patientId,
                        'title': titleController.text.trim(),
                        'content': contentController.text.trim(),
                        'reportType': reportType,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Medical report created successfully',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Create Report',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewReport(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled Report';
    final content = data['content'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final reportType = data['reportType'] ?? 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      DateFormat('MMMM d, yyyy').format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reportType,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.isEmpty ? 'No content' : content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Report?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('medicalReports')
                    .doc(reportId)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report deleted')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    final notesRef = FirebaseFirestore.instance
        .collection('doctorPatients')
        .doc(_doctorId)
        .collection('patients')
        .doc(widget.patientId)
        .collection('notes')
        .orderBy('createdAt', descending: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes médicales (privées)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: notesRef.snapshots(),
          builder: (context, snap) {
            // Show loading only on first load
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const _CardContainer(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Handle errors
            if (snap.hasError) {
              return _CardContainer(
                child: Center(child: Text('Error: ${snap.error}')),
              );
            }

            final docs = snap.data?.docs ?? [];
            return _CardContainer(
              child: Column(
                children: [
                  if (docs.isEmpty) const Text('Aucune note.'),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['title'] ?? 'Note'),
                      subtitle: Text(data['content'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => d.reference.delete(),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addNote,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une note'),
        ),
      ],
    );
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final titleCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Contenu'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ref = FirebaseFirestore.instance
                  .collection('doctorPatients')
                  .doc(_doctorId)
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('notes')
                  .doc();
              await ref.set({
                'title': titleCtrl.text.trim().isEmpty
                    ? 'Note'
                    : titleCtrl.text.trim(),
                'content': controller.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ========== APPOINTMENT HISTORY SECTION (COLLAPSIBLE) ==========
class _AppointmentHistorySection extends StatefulWidget {
  final List<QueryDocumentSnapshot> appointments;
  final String doctorId;
  final String patientId;

  const _AppointmentHistorySection({
    required this.appointments,
    required this.doctorId,
    required this.patientId,
  });

  @override
  State<_AppointmentHistorySection> createState() =>
      _AppointmentHistorySectionState();
}

class _AppointmentHistorySectionState
    extends State<_AppointmentHistorySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E63D9).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E63D9).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E63D9), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E63D9).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appointment History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.appointments.length} total appointment${widget.appointments.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E63D9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Hide' : 'View',
                          style: const TextStyle(
                            color: Color(0xFF2E63D9),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: const Color(0xFF2E63D9),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.appointments.isEmpty
                  ? _buildEmptyState()
                  : _buildAppointmentsList(),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No appointments yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      key: ValueKey('appointments_${widget.appointments.length}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.appointments.length,
      itemBuilder: (context, index) {
        final doc = widget.appointments[index];
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['startTime'] as Timestamp?;
        final endTs = data['endTime'] as Timestamp?;
        final status = (data['status'] ?? 'pending').toString().toUpperCase();
        final mode = (data['mode'] ?? 'video').toString();
        final notes = (data['notes'] ?? '').toString();

        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'CONFIRMED':
            statusColor = const Color(0xFF10B981);
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'CANCELLED':
            statusColor = const Color(0xFFEF4444);
            statusIcon = Icons.cancel_rounded;
            break;
          case 'COMPLETED':
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.task_alt_rounded;
            break;
          default:
            statusColor = const Color(0xFFF59E0B);
            statusIcon = Icons.schedule_rounded;
        }

        final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
        final timeFormat = DateFormat('HH:mm');

        return Container(
          key: ValueKey(doc.id),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ts != null
                                ? dateFormat.format(ts.toDate())
                                : 'Date unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ts != null && endTs != null
                                    ? '${timeFormat.format(ts.toDate())} - ${timeFormat.format(endTs.toDate())}'
                                    : 'Time unknown',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode.toUpperCase() == 'VIDEO'
                            ? Icons.videocam_rounded
                            : Icons.local_hospital_rounded,
                        size: 20,
                        color: const Color(0xFF2E63D9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.toUpperCase() == 'VIDEO'
                            ? 'Video Consultation'
                            : 'In-Person Visit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.note_rounded,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
