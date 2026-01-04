import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'auth_gate.dart';
import '../features/auth/pages/role_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/patient/pages/patient_home_page.dart';
import '../features/patient/pages/patient_onboarding_page.dart';
import '../features/patient/pages/patient_profile_edit_page.dart';
import '../features/patient/pages/appointments_page.dart';
import '../features/patient/pages/doctor_search_page.dart';
import '../features/patient/pages/doctor_detail_page.dart';
import '../features/doctor/presentation/pages/doctor_complete_profile_screen.dart';
import '../features/doctor/presentation/pages/doctor_edit_profile_screen.dart';
import '../features/doctor/presentation/pages/doctor_dashboard_screen.dart';
import '../features/doctor/presentation/pages/doctor_appointments_page.dart';
import '../features/doctor/presentation/pages/doctor_patient_detail_page.dart';
import '../features/agenda/presentation/pages/agenda_screen.dart';
import '../shared/pages/geocoding_utility_page.dart';
import '../shared/pages/geocoding_admin_page.dart';
import '../shared/pages/quick_coordinate_fix_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => AuthGate()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
    GoRoute(path: '/role', builder: (c, s) => const RolePage()),
    GoRoute(path: '/patient', builder: (c, s) => const PatientHomePage()),
    GoRoute(
      path: '/patient/onboarding',
      builder: (c, s) => const PatientOnboardingPage(),
    ),
    GoRoute(
      path: '/patient/profile/edit',
      builder: (c, s) => const PatientProfileEditPage(),
    ),
    GoRoute(
      path: '/patient/appointments',
      builder: (c, s) => const AppointmentsPage(),
    ),
    GoRoute(
      path: '/patient/search',
      builder: (c, s) => const DoctorSearchPage(),
    ),
    GoRoute(
      path: '/patient/doctor/:id',
      builder: (c, s) => DoctorDetailPage(doctorId: s.pathParameters['id']!),
    ),
    // Doctor routes (after login with role=doctor)
    GoRoute(
      path: '/doctor/complete-profile',
      builder: (c, s) => const DoctorCompleteProfileScreen(),
    ),
    GoRoute(
      path: '/doctor/edit-profile',
      builder: (c, s) => const DoctorEditProfileScreen(),
    ),
    GoRoute(
      path: '/doctor/dashboard',
      builder: (c, s) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/doctor/agenda',
      builder: (c, s) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        return AgendaScreen(doctorId: uid);
      },
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (c, s) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        return DoctorAppointmentsPage(doctorId: uid);
      },
    ),
    GoRoute(
      path: '/doctor/patient/:id',
      builder: (c, s) =>
          DoctorPatientDetailPage(patientId: s.pathParameters['id']!),
    ),
    // Admin/Utility routes
    GoRoute(
      path: '/admin/geocoding',
      builder: (c, s) => const GeocodingUtilityPage(),
    ),
    GoRoute(
      path: '/admin/locations',
      builder: (c, s) => const GeocodingAdminPage(),
    ),
    GoRoute(
      path: '/admin/fix-coordinates',
      builder: (c, s) => const QuickCoordinateFixPage(),
    ),
  ],
);
