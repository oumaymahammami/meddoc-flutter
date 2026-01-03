import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/auth/auth_service.dart';
import '../features/patient/pages/patient_home_page.dart';
import '../features/doctor/presentation/pages/doctor_complete_profile_screen.dart';
import '../features/doctor/presentation/pages/doctor_dashboard_screen.dart';
import '../features/auth/pages/login_page.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();

        return FutureBuilder<String?>(
          future: _auth.getCurrentUserRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnap.data;
            if (role == 'doctor') {
              // Check if doctor has completed their profile
              return FutureBuilder<bool>(
                future: _checkDoctorProfileCompletion(),
                builder: (context, profileSnap) {
                  if (profileSnap.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final profileCompleted = profileSnap.data ?? false;
                  if (profileCompleted) {
                    // Profile complete → Show dashboard
                    return const DoctorDashboardScreen();
                  } else {
                    // Profile incomplete → Show complete profile form
                    return const DoctorCompleteProfileScreen();
                  }
                },
              );
            }
            return const PatientHomePage();
          },
        );
      },
    );
  }

  /// Check if doctor profile is completed
  Future<bool> _checkDoctorProfileCompletion() async {
    try {
      final uid = _auth.getCurrentUid();
      if (uid == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data()?['profileCompleted'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      return false;
    }
  }
}
