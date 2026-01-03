import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Route management for doctor onboarding flow
class DoctorOnboardingRouter {
  static const String loginRoute = '/login';
  static const String completeProfileRoute = '/doctor/complete-profile';
  static const String dashboardRoute = '/doctor/dashboard';

  /// Determine where to route doctor based on profile completion status
  static String getInitialRoute({
    required bool isProfileCompleted,
    required bool isLoggedIn,
  }) {
    if (!isLoggedIn) {
      return loginRoute;
    }

    if (!isProfileCompleted) {
      return completeProfileRoute;
    }

    return dashboardRoute;
  }

  /// Listen to auth state and profile completion changes
  static Future<void> handlePostLoginNavigation(
    BuildContext context,
    WidgetRef ref,
    User? user,
  ) async {
    if (user == null) return;

    try {
      // Fetch user profile to check completion status
      // NOTE: This method is kept for reference but currently uses GoRouter instead
      // For now, just return - GoRouter handles routing
      return;
    } catch (e) {
      _showErrorAndReroute(context, 'Failed to load profile: $e');
    }
  }

  /// Handle edge case: profile incomplete but trying to access dashboard
  static bool shouldRedirectToCompleteProfile({
    required bool isProfileCompleted,
    required String currentRoute,
  }) {
    return !isProfileCompleted && currentRoute == dashboardRoute;
  }

  /// Handle edge case: user changes role
  static Future<void> handleRoleChange(
    BuildContext context,
    String uid,
    String newRole,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Role Changed'),
        content: const Text(
          'You\'ve changed your role. Your profile will need to be reconfigured.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle logout and cleanup
  static Future<void> handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed(loginRoute);
  }

  static void _showErrorAndReroute(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushReplacementNamed(loginRoute);
  }
}
