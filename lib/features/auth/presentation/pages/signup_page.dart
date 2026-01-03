import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meddoc/shared/services/auth_onboarding_service.dart';

/// Step 1 in Doctor Onboarding: Email/Password signup
/// After successful signup, redirects to SignUpRoleSelectorPage
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'DOCTOR'; // DOCTOR or PATIENT

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _validateEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  /// Validate password strength
  bool _validatePassword(String password) {
    // At least 8 chars, 1 uppercase, 1 lowercase, 1 digit
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final onboarding = AuthOnboardingService();

      // Step 1: Create Firebase Auth account
      print('🔐 Creating Firebase Auth account...');
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = userCredential.user!.uid;
      print('✅ Firebase Auth account created: $uid');

      // Step 2: Create /users/{uid} document
      print('📝 Creating /users/$uid document...');
      if (_selectedRole == 'DOCTOR') {
        await onboarding.createUserDocForNewDoctor(
          uid: uid,
          email: _emailController.text.trim(),
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );
      } else {
        await onboarding.createUserDocForNewPatient(
          uid: uid,
          email: _emailController.text.trim(),
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );
      }

      // Step 3: Only create /doctors/{uid} placeholder for doctors
      if (_selectedRole == 'DOCTOR') {
        print('📝 Creating /doctors/$uid placeholder...');
        await onboarding.createDoctorPlaceholderDoc(uid: uid);
      }

      print('✅ $_selectedRole account signup complete!');

      if (!mounted) return;

      // Route based on role
      if (_selectedRole == 'DOCTOR') {
        // Navigate to doctor profile completion screen
        Navigator.of(context).pushReplacementNamed(
          '/auth/signup/complete-profile',
          arguments: {
            'uid': uid,
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.isNotEmpty
                ? _phoneController.text.trim()
                : null,
          },
        );
      } else {
        // Patients go straight to login
        Navigator.of(context).pushReplacementNamed('/auth/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please log in with your credentials.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Unexpected error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Friendly error messages
  String _friendlyAuthError(String code) {
    const errors = {
      'email-already-in-use':
          'Email already registered. Please log in instead.',
      'invalid-email': 'Please enter a valid email address.',
      'operation-not-allowed':
          'Sign up is temporarily disabled. Please try again later.',
      'weak-password':
          'Password must have 8+ chars, uppercase, lowercase, and a number.',
      'user-disabled': 'This account has been disabled.',
      'network-request-failed': 'Network error. Please check your connection.',
    };
    return errors[code] ?? 'Sign up failed. Please try again.';
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return false;
    }

    if (!_validateEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return false;
    }

    if (password.isEmpty) {
      setState(() => _error = 'Please enter a password');
      return false;
    }

    if (!_validatePassword(password)) {
      setState(
        () => _error =
            'Password must have 8+ chars, uppercase, lowercase, and a number',
      );
      return false;
    }

    if (confirmPassword != password) {
      setState(() => _error = 'Passwords do not match');
      return false;
    }

    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create $_selectedRole Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role selector
            const SizedBox(height: 20),
            const Text(
              'I am a...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _loading
                        ? null
                        : () => setState(() => _selectedRole = 'DOCTOR'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'DOCTOR'
                            ? Colors.blue[100]
                            : Colors.grey[100],
                        border: Border.all(
                          color: _selectedRole == 'DOCTOR'
                              ? Colors.blue
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Doctor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedRole == 'DOCTOR'
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _loading
                        ? null
                        : () => setState(() => _selectedRole = 'PATIENT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'PATIENT'
                            ? Colors.blue[100]
                            : Colors.grey[100],
                        border: Border.all(
                          color: _selectedRole == 'PATIENT'
                              ? Colors.blue
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Patient',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedRole == 'PATIENT'
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Header
            const SizedBox(height: 30),
            Text(
              '${_selectedRole} Registration',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your account to get started',
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

            const SizedBox(height: 30),

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

            // Phone field
            TextField(
              controller: _phoneController,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 (555) 000-0000',
                prefixIcon: const Icon(Icons.phone_outlined),
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
                hintText: 'At least 8 characters',
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

            const SizedBox(height: 8),
            Text(
              'Must contain: 8+ characters, uppercase, lowercase, number',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Confirm password field
            TextField(
              controller: _confirmPasswordController,
              enabled: !_loading,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Sign up button
            ElevatedButton(
              onPressed: _loading ? null : _handleSignUp,
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
                  : const Text('Create Account'),
            ),

            const SizedBox(height: 20),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: _loading
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/auth/login'),
                  child: Text(
                    'Log In',
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
