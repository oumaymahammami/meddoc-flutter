import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meddoc/shared/auth/auth_service.dart';
import '../constants/auth_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userRole = await _auth.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      _onLoginSuccess(context, userRole);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onLoginSuccess(BuildContext context, String userRole) {
    // Redirect based on user role
    if (userRole == 'doctor') {
      context.go('/doctor/dashboard');
    } else {
      // Patients go directly to their home dashboard
      context.go('/patient');
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-email')) {
      return 'Email invalide.';
    }
    if (msg.contains('user-not-found')) {
      return "Compte introuvable. Vérifiez l'email ou inscrivez-vous.";
    }
    if (msg.contains('wrong-password')) {
      return 'Mot de passe incorrect.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard.';
    }
    return 'Connexion échouée. Vérifiez vos informations et réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          _AnimatedBackdrop(floatController: _floatController),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide
                      ? AuthDimensions.paddingXXL
                      : AuthDimensions.paddingLG,
                  vertical: isWide
                      ? AuthDimensions.paddingXL
                      : AuthDimensions.paddingLG,
                ),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: isWide
                        ? _buildWideLayout(context)
                        : _buildStackedLayout(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _HeroPanel(floatController: _floatController)),
        const SizedBox(width: AuthDimensions.paddingLG),
        Expanded(
          child: _FrostedCard(
            child: _AuthForm(
              formKey: _formKey,
              email: _email,
              password: _password,
              showPassword: _showPassword,
              onTogglePassword: () =>
                  setState(() => _showPassword = !_showPassword),
              onSubmit: _loading ? null : _login,
              loading: _loading,
              error: _error,
              onNavigateRegister: () => context.go('/register'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPanel(floatController: _floatController, compact: true),
        const SizedBox(height: AuthDimensions.paddingLG),
        _FrostedCard(
          child: _AuthForm(
            formKey: _formKey,
            email: _email,
            password: _password,
            showPassword: _showPassword,
            onTogglePassword: () =>
                setState(() => _showPassword = !_showPassword),
            onSubmit: _loading ? null : _login,
            loading: _loading,
            error: _error,
            onNavigateRegister: () => context.go('/register'),
          ),
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.loading,
    required this.error,
    required this.onNavigateRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;
  final bool loading;
  final String? error;
  final VoidCallback onNavigateRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connexion',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AuthDimensions.paddingSM),
        Text(
          'Ravi de vous revoir. Accédez à votre espace sécurisé.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AuthColors.textSecondary),
        ),
        const SizedBox(height: AuthDimensions.paddingLG),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    icon: Icons.email_outlined,
                    hint: 'prenom.nom@exemple.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email requis';
                    }
                    if (!v.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              _LabeledField(
                label: 'Mot de passe',
                child: TextFormField(
                  controller: password,
                  obscureText: !showPassword,
                  decoration: _inputDecoration(
                    icon: Icons.lock_outline_rounded,
                    hint: 'Votre mot de passe',
                    trailing: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: AuthColors.textLight,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Mot de passe requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingSM),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Mot de passe oublié ? (bientôt)',
                    style: TextStyle(
                      color: AuthColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? const SizedBox.shrink()
                    : _ErrorBanner(message: error!),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AuthDimensions.paddingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AuthDimensions.radiusMD,
                    ),
                  ),
                  elevation: 0,
                  shadowColor: AuthColors.primary.withValues(alpha: 0.35),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Pas encore de compte ? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AuthColors.textSecondary,
                    ),
                    children: [
                      WidgetSpan(
                        child: InkWell(
                          onTap: onNavigateRegister,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AuthDimensions.paddingXS,
                              vertical: AuthDimensions.paddingXS,
                            ),
                            child: Text(
                              "S'inscrire",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AuthColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AuthColors.textLight),
      suffixIcon: trailing,
      filled: true,
      fillColor: AuthColors.surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AuthDimensions.radiusMD),
        borderSide: const BorderSide(color: AuthColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AuthDimensions.radiusMD),
        borderSide: const BorderSide(color: AuthColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AuthDimensions.radiusMD),
        borderSide: const BorderSide(color: AuthColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AuthDimensions.paddingMD,
        vertical: AuthDimensions.paddingSM,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.floatController, this.compact = false});

  final AnimationController floatController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final oscillation = Tween(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: oscillation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(oscillation.value, math.sin(oscillation.value) * 4),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact
              ? AuthDimensions.paddingLG
              : AuthDimensions.paddingXL,
          vertical: compact
              ? AuthDimensions.paddingLG
              : AuthDimensions.paddingXL,
        ),
        decoration: BoxDecoration(
          gradient: AuthColors.primaryGradient,
          borderRadius: BorderRadius.circular(AuthDimensions.radiusXL),
          boxShadow: [AuthColors.softGlow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AuthDimensions.radiusLG,
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AuthDimensions.paddingMD),
                Text(
                  'MedDoc',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuthDimensions.paddingLG),
            Text(
              'Accédez à votre espace santé en toute sécurité.',
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AuthDimensions.paddingMD),
            Text(
              'Track your records, appointments and results in real-time. Modern interface, protected data.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AuthDimensions.paddingLG),
            Wrap(
              spacing: AuthDimensions.paddingSM,
              runSpacing: AuthDimensions.paddingSM,
              children: const [
                _Pill(text: 'Sécurité renforcée'),
                _Pill(text: 'Accès instantané'),
                _Pill(text: 'Dossiers médicaux complets'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuthDimensions.paddingMD,
        vertical: AuthDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AuthDimensions.radiusLG),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuthDimensions.paddingXL),
      decoration: BoxDecoration(
        gradient: AuthColors.glassGradient,
        borderRadius: BorderRadius.circular(AuthDimensions.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [AuthColors.softGlow, AuthColors.thinBorder],
      ),
      child: child,
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({required this.floatController});
  final AnimationController floatController;

  @override
  Widget build(BuildContext context) {
    final oscillation = Tween(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: oscillation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(gradient: AuthColors.backgroundGradient),
          child: Stack(
            children: [
              _glowCircle(
                size: 220,
                offset: Offset(-40 + oscillation.value, -30),
                color: AuthColors.primary.withValues(alpha: 0.2),
              ),
              _glowCircle(
                size: 280,
                offset: Offset(220 - oscillation.value, 120),
                color: AuthColors.primaryAccent.withValues(alpha: 0.18),
              ),
              _glowCircle(
                size: 180,
                offset: Offset(60, 420 + oscillation.value),
                color: AuthColors.primary.withValues(alpha: 0.12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glowCircle({
    required double size,
    required Offset offset,
    required Color color,
  }) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AuthColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AuthDimensions.paddingXS),
        child,
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuthDimensions.paddingMD),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AuthDimensions.radiusMD),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AuthColors.error, size: 20),
          const SizedBox(width: AuthDimensions.paddingMD),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AuthColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
