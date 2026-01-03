import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:meddoc/shared/services/auth_onboarding_service.dart';

/// Login Page with Role-Based Routing
///
/// After successful login, checks:
/// 1. User role (DOCTOR or PATIENT)
/// 2. For DOCTOR: checks profile completion status
/// 3. Routes accordingly:
///    - DOCTOR, profileCompleted=false → Complete Profile Screen
///    - DOCTOR, profileCompleted=true → Doctor Dashboard
///    - PATIENT → Patient Home Page
/// 4. Also verifies /doctors/{uid} exists for doctors
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_validateForm()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final onboarding = AuthOnboardingService();

      // Step 1: Authenticate with Firebase
      print('🔐 Authenticating with Firebase...');
      final userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = userCredential.user!.uid;
      print('✅ Firebase auth successful: $uid');

      if (!mounted) return;

      // Step 2: Get user role
      print('👤 Fetching user role...');
      final role = await onboarding.getUserRole(uid);
      print('✅ User role: $role');

      // =====================================================
      // DOCTOR LOGIN FLOW
      // =====================================================
      if (role == 'DOCTOR') {
        // Step 3: Check profile completion status
        print('📋 Checking doctor profile completion status...');
        final isComplete = await onboarding.isDoctorProfileComplete(uid);
        print('Profile complete: $isComplete');

        // Step 4: Verify /doctors/{uid} exists
        print('🔍 Verifying /doctors/$uid exists...');
        final doctorExists = await onboarding.verifyDoctorDocExists(uid);
        if (!doctorExists) {
          if (mounted) {
            setState(
              () => _error = 'Profile data corrupted. Please contact support.',
            );
          }
          return;
        }

        if (!mounted) return;

        // Step 5: Route based on completion status
        if (!isComplete) {
          print('⬜ Doctor profile incomplete, routing to completion screen...');
          final userDoc = await onboarding.getUserDoc(uid);
          context.go(
            '/auth/signup/complete-profile',
            extra: {
              'uid': uid,
              'email': userDoc?['email'] ?? _emailController.text.trim(),
              'phone': userDoc?['phone'],
            },
          );
        } else {
          print('✅ Doctor profile complete, routing to dashboard...');
          context.go('/doctor/dashboard');
        }
      }
      // =====================================================
      // PATIENT LOGIN FLOW
      // =====================================================
      else if (role == 'PATIENT') {
        print('✅ Patient authenticated, routing to home...');
        context.go('/patient/home');
      }
      // Unknown role
      else {
        if (mounted) {
          setState(() => _error = 'Unknown user role. Please contact support.');
          await auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _friendlyAuthError(String code) {
    const errors = {
      'user-not-found': 'No account found with this email address.',
      'wrong-password': 'Incorrect password. Please try again.',
      'invalid-email': 'Please enter a valid email address.',
      'user-disabled': 'This account has been disabled.',
      'too-many-requests':
          'Too many failed login attempts. Please try again later.',
      'network-request-failed': 'Network error. Please check your connection.',
    };
    return errors[code] ?? 'Login failed. Please try again.';
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return false;
    }

    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Login'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 40),
            Text(
              'Welcome Back',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Log in to your doctor account',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Email field
            TextField(
              controller: _emailController,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'doctor@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              enabled: !_loading,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        // TODO: Implement forgot password flow
                      },
                child: const Text('Forgot Password?'),
              ),
            ),

            const SizedBox(height: 30),

            // Login button
            ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log In'),
            ),

            const SizedBox(height: 20),

            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: _loading ? null : () => context.go('/auth/signup'),
                  child: Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
