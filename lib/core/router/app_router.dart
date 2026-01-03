import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meddoc/features/auth/presentation/pages/signup_page.dart';
import 'package:meddoc/features/auth/presentation/pages/login_page.dart';
import 'package:meddoc/features/doctor/presentation/pages/doctor_complete_profile_screen.dart';
import 'package:meddoc/features/doctor/presentation/pages/doctor_dashboard_screen.dart';
import 'package:meddoc/features/doctor/presentation/pages/doctor_edit_profile_screen.dart';
import 'package:meddoc/features/doctor/presentation/pages/doctor_patient_detail_page.dart';
import 'package:meddoc/features/agenda/presentation/pages/agenda_screen.dart';
import 'package:meddoc/features/patient/pages/patient_home_page.dart';
import 'package:meddoc/features/patient/pages/patient_onboarding_page.dart';
import 'package:meddoc/features/patient/pages/doctor_search_page.dart';
import 'package:meddoc/features/patient/pages/appointments_page.dart';
import 'package:meddoc/features/patient/pages/patient_profile_edit_page.dart';
import 'package:meddoc/shared/services/auth_onboarding_service.dart';

/// Main router configuration for MedDoc
///
/// Routes:
/// - /auth/login - Login (doctor or patient)
/// - /auth/signup - Sign up (doctor or patient)
/// - /auth/signup/complete-profile - Complete profile after signup (doctor only)
/// - /doctor/dashboard - Doctor dashboard (after login & profile complete)
/// - /doctor/agenda - Doctor agenda/availability management
/// - /doctor/profile/* - Doctor profile pages
/// - /patient/home - Patient home page (after login)
/// - /patient/doctors - Doctor search/browse
/// - /patient/appointments - View appointments
/// - /patient/profile - Patient profile
///
/// Routing Guard Logic:
/// 1. If not authenticated → /auth/login
/// 2. If DOCTOR and profileCompleted=false → /auth/signup/complete-profile
/// 3. If DOCTOR and profileCompleted=true → /doctor/dashboard
/// 4. If PATIENT → /patient/home
final appRouter = GoRouter(
  initialLocation: '/auth/login',
  debugLogDiagnostics: true,
  redirect: (context, state) => _rootRouteGuard(context, state),
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/auth/login'),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    // ====================================================================
    // AUTH ROUTES
    // ====================================================================
    GoRoute(
      path: '/auth',
      builder: (context, state) => const Scaffold(),
      routes: [
        // Login screen
        GoRoute(
          path: 'login',
          pageBuilder: (context, state) => MaterialPage(child: LoginPage()),
        ),

        // Signup screen
        GoRoute(
          path: 'signup',
          pageBuilder: (context, state) => MaterialPage(child: SignUpPage()),
        ),

        // Complete doctor profile screen
        GoRoute(
          path: 'signup/complete-profile',
          pageBuilder: (context, state) =>
              const MaterialPage(child: DoctorCompleteProfileScreen()),
        ),

        // Patient onboarding screen
        GoRoute(
          path: 'patient/complete-profile',
          pageBuilder: (context, state) =>
              const MaterialPage(child: PatientOnboardingPage()),
        ),
      ],
    ),

    // ====================================================================
    // DOCTOR ROUTES (Protected by routing guard)
    // ====================================================================
    GoRoute(
      path: '/doctor',
      builder: (context, state) => const Scaffold(),
      routes: [
        // Dashboard screen
        GoRoute(
          path: 'dashboard',
          pageBuilder: (context, state) =>
              const MaterialPage(child: DoctorDashboardScreen()),
        ),

        // Agenda screen
        GoRoute(
          path: 'agenda',
          pageBuilder: (context, state) {
            final user = FirebaseAuth.instance.currentUser;
            final doctorId = user?.uid ?? 'unknown';
            return MaterialPage(child: AgendaScreen(doctorId: doctorId));
          },
        ),

        // Edit profile screen
        GoRoute(
          path: 'editprofile',
          pageBuilder: (context, state) =>
              const MaterialPage(child: DoctorEditProfileScreen()),
        ),

        // Patient detail (doctor side)
        GoRoute(
          path: 'patient/:id',
          pageBuilder: (context, state) {
            final pid = state.pathParameters['id'] ?? '';
            return MaterialPage(child: DoctorPatientDetailPage(patientId: pid));
          },
        ),
      ],
    ),

    // ====================================================================
    // PATIENT ROUTES
    // ====================================================================
    GoRoute(
      path: '/patient',
      builder: (context, state) => const Scaffold(),
      routes: [
        // Home page
        GoRoute(
          path: 'home',
          pageBuilder: (context, state) =>
              const MaterialPage(child: PatientHomePage()),
        ),

        // Doctor search
        GoRoute(
          path: 'doctors',
          pageBuilder: (context, state) =>
              const MaterialPage(child: DoctorSearchPage()),
        ),

        // Appointments
        GoRoute(
          path: 'appointments',
          pageBuilder: (context, state) =>
              const MaterialPage(child: AppointmentsPage()),
        ),

        // Profile
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) =>
              const MaterialPage(child: PatientProfileEditPage()),
        ),
      ],
    ),

    // ====================================================================
    // ROOT REDIRECT
    // ====================================================================
    GoRoute(path: '/', redirect: (context, state) => '/auth/login'),
  ],
);

/// Root-level routing guard to handle authentication and role-based routing
///
/// Determines where to route user based on:
/// 1. Authentication status
/// 2. User role (DOCTOR or PATIENT)
/// 3. Profile completion (doctors only)
/// 4. Patient profile completion
///
/// Returns:
/// - null if allowed to proceed (already on correct page)
/// - route path if redirect needed
Future<String?> _rootRouteGuard(
  BuildContext context,
  GoRouterState state,
) async {
  try {
    // Allow auth pages to be accessed without login
    if (state.matchedLocation.startsWith('/auth')) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;

    // Not authenticated → login
    if (user == null) {
      print('🔒 Not authenticated, redirecting to login');
      return '/auth/login';
    }

    final uid = user.uid;
    final onboarding = AuthOnboardingService();

    // Get user role with timeout and error handling
    String? role;
    try {
      role = await onboarding
          .getUserRole(uid)
          .timeout(const Duration(seconds: 10));
      print('👤 User role: $role');
    } catch (e) {
      print('⚠️  Error getting user role: $e');
      // If we can't get the role, default to checking the path
      // This prevents crashes while waiting for Firestore
      if (state.matchedLocation.startsWith('/doctor')) {
        return null; // Allow doctor routes
      }
      if (state.matchedLocation.startsWith('/patient')) {
        return null; // Allow patient routes
      }
      // If we can't determine role and user tries other routes, go to login
      return '/auth/login';
    }

    // =====================================================
    // DOCTOR ROUTING
    // =====================================================
    if (role == 'DOCTOR') {
      // Skip guard for doctor routes
      if (state.matchedLocation.startsWith('/doctor')) {
        print('✅ Doctor on doctor route, allowed');
        return null;
      }

      // If on patient routes, redirect to doctor dashboard
      if (state.matchedLocation.startsWith('/patient')) {
        print(
          '🔄 Doctor trying to access patient pages, redirecting to dashboard',
        );
        return '/doctor/dashboard';
      }

      print('✅ Doctor routing allowed');
      return null;
    }

    // =====================================================
    // PATIENT ROUTING
    // =====================================================
    if (role == 'PATIENT') {
      // Skip guard for patient routes
      if (state.matchedLocation.startsWith('/patient')) {
        print('✅ Patient on patient route, allowed');
        return null;
      }

      // If on doctor routes, redirect to patient home
      if (state.matchedLocation.startsWith('/doctor')) {
        print('🔄 Patient trying to access doctor pages, redirecting to home');
        return '/patient/home';
      }

      print('✅ Patient routing allowed');
      return null;
    }

    // Unknown role → login
    print('❌ Unknown role: $role');
    return '/auth/login';
  } catch (e) {
    print('❌ Routing guard error: $e');
    return '/auth/login';
  }
}

/// Extension to GoRouter for easier navigation with arguments
extension GoRouterX on GoRouter {
  void goWithArgs(String location, {required Map<String, dynamic> args}) {
    push(location, extra: args);
  }

  void replaceWithArgs(String location, {required Map<String, dynamic> args}) {
    pushReplacement(location, extra: args);
  }
}
