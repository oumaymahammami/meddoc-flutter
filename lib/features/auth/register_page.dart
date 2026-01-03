import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/auth/auth_service.dart';
import 'constants/auth_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _authService = AuthService();

  String _role = 'patient';
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  String? _error;
  late AnimationController _fadeController;
  late AnimationController _floatController;

  int _passwordStrength = 0; // 0-4

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

    _password.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final pwd = _password.text;
    int strength = 0;

    if (pwd.length >= 6) {
      strength++;
    }
    if (pwd.length >= 10) {
      strength++;
    }
    if (RegExp(r'[A-Z]').hasMatch(pwd)) {
      strength++;
    }
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) {
      strength++;
    }

    setState(() => _passwordStrength = strength);
  }

  String get _passwordStrengthLabel {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Fort';
      case 4:
        return 'Très fort';
      default:
        return '';
    }
  }

  Color get _passwordStrengthColor {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return AuthColors.error;
      case 2:
        return AuthColors.warning;
      case 3:
      case 4:
        return AuthColors.success;
      default:
        return AuthColors.textLight;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter les conditions d'utilisation"),
          backgroundColor: AuthColors.error,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.register(
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        name: _name.text.trim(),
      );
      if (!mounted) return;
      // Route patient to onboarding, others to home
      if (_role == 'patient') {
        context.go('/patient/onboarding');
      } else {
        context.go('/');
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('weak-password') || msg.contains('WEAK_PASSWORD')) {
      return 'Mot de passe trop faible (min 6 caractères).';
    }
    if (msg.contains('email-already-in-use') || msg.contains('EMAIL_EXISTS')) {
      return 'Cet email est déjà utilisé.';
    }
    if (msg.contains('invalid-email') || msg.contains('INVALID_EMAIL')) {
      return 'Email invalide.';
    }
    return 'Inscription échouée. Vérifiez les informations et réessayez.';
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
            child: _RegisterForm(
              formKey: _formKey,
              name: _name,
              email: _email,
              password: _password,
              confirmPassword: _confirmPassword,
              showPassword: _showPassword,
              showConfirmPassword: _showConfirmPassword,
              onTogglePassword: () =>
                  setState(() => _showPassword = !_showPassword),
              onToggleConfirmPassword: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              loading: _loading,
              error: _error,
              role: _role,
              onRoleChanged: (v) => setState(() => _role = v ?? 'patient'),
              agreedToTerms: _agreedToTerms,
              onToggleTerms: () =>
                  setState(() => _agreedToTerms = !_agreedToTerms),
              passwordStrength: _passwordStrength,
              passwordStrengthColor: _passwordStrengthColor,
              passwordStrengthLabel: _passwordStrengthLabel,
              onSubmit: _loading ? null : _register,
              onNavigateLogin: () => context.go('/login'),
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
          child: _RegisterForm(
            formKey: _formKey,
            name: _name,
            email: _email,
            password: _password,
            confirmPassword: _confirmPassword,
            showPassword: _showPassword,
            showConfirmPassword: _showConfirmPassword,
            onTogglePassword: () =>
                setState(() => _showPassword = !_showPassword),
            onToggleConfirmPassword: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
            loading: _loading,
            error: _error,
            role: _role,
            onRoleChanged: (v) => setState(() => _role = v ?? 'patient'),
            agreedToTerms: _agreedToTerms,
            onToggleTerms: () =>
                setState(() => _agreedToTerms = !_agreedToTerms),
            passwordStrength: _passwordStrength,
            passwordStrengthColor: _passwordStrengthColor,
            passwordStrengthLabel: _passwordStrengthLabel,
            onSubmit: _loading ? null : _register,
            onNavigateLogin: () => context.go('/login'),
          ),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.loading,
    required this.error,
    required this.role,
    required this.onRoleChanged,
    required this.agreedToTerms,
    required this.onToggleTerms,
    required this.passwordStrength,
    required this.passwordStrengthColor,
    required this.passwordStrengthLabel,
    required this.onSubmit,
    required this.onNavigateLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool loading;
  final String? error;
  final String role;
  final ValueChanged<String?> onRoleChanged;
  final bool agreedToTerms;
  final VoidCallback onToggleTerms;
  final int passwordStrength;
  final Color passwordStrengthColor;
  final String passwordStrengthLabel;
  final VoidCallback? onSubmit;
  final VoidCallback onNavigateLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Créer un compte',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AuthDimensions.paddingSM),
        Text(
          'Rejoignez la plateforme MedDoc et pilotez vos données de santé en toute sérénité.',
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
                label: 'Nom complet',
                child: TextFormField(
                  controller: name,
                  decoration: _inputDecoration(
                    icon: Icons.person_outline,
                    hint: 'Prénom Nom',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nom requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
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
                    hint: 'Minimum 6 caractères',
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
                    if (v.length < 6) {
                      return 'Au moins 6 caractères';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingSM),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: password.text.isEmpty
                    ? const SizedBox.shrink()
                    : _PasswordStrength(
                        strength: passwordStrength,
                        color: passwordStrengthColor,
                        label: passwordStrengthLabel,
                      ),
              ),
              const SizedBox(height: AuthDimensions.paddingSM),
              _LabeledField(
                label: 'Confirmer le mot de passe',
                child: TextFormField(
                  controller: confirmPassword,
                  obscureText: !showConfirmPassword,
                  decoration: _inputDecoration(
                    icon: Icons.lock_person_outlined,
                    hint: 'Répétez votre mot de passe',
                    trailing: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AuthColors.textLight,
                      ),
                      onPressed: onToggleConfirmPassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Veuillez confirmer le mot de passe';
                    }
                    if (v != password.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              _LabeledField(
                label: 'Je suis',
                child: DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(
                      value: 'patient',
                      child: Text('👤 Patient'),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Text('👨‍⚕️ Professionnel de santé'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('🛡️ Administrateur'),
                    ),
                  ],
                  onChanged: onRoleChanged,
                  decoration: _inputDecoration(
                    icon: Icons.badge_outlined,
                    hint: 'Choisissez votre profil',
                  ),
                ),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (_) => onToggleTerms(),
                    activeColor: AuthColors.primary,
                  ),
                  const SizedBox(width: AuthDimensions.paddingXS),
                  Expanded(
                    child: GestureDetector(
                      onTap: onToggleTerms,
                      child: RichText(
                        text: TextSpan(
                          text: "J'accepte les ",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AuthColors.textSecondary),
                          children: [
                            TextSpan(
                              text: "conditions d'utilisation",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AuthColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            TextSpan(
                              text: ' et la ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AuthColors.textSecondary),
                            ),
                            TextSpan(
                              text: 'politique de confidentialité',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AuthColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AuthDimensions.paddingLG),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? const SizedBox.shrink()
                    : _ErrorBanner(message: error!),
              ),
              const SizedBox(height: AuthDimensions.paddingMD),
              ElevatedButton(
                onPressed: (loading || !agreedToTerms) ? null : onSubmit,
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
                          "S'inscrire",
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
                    text: 'Déjà inscrit ? ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AuthColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Se connecter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = onNavigateLogin,
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

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({
    required this.strength,
    required this.color,
    required this.label,
  });

  final int strength;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 4,
                minHeight: 5,
                backgroundColor: AuthColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: AuthDimensions.paddingMD),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({required this.floatController});
  final AnimationController floatController;

  @override
  Widget build(BuildContext context) {
    final oscillation = Tween(begin: -10.0, end: 10.0).animate(
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
                size: 240,
                offset: Offset(-60 + oscillation.value, -20),
                color: AuthColors.primary.withValues(alpha: 0.2),
              ),
              _glowCircle(
                size: 260,
                offset: Offset(200 - oscillation.value, 180),
                color: AuthColors.primaryAccent.withValues(alpha: 0.2),
              ),
              _glowCircle(
                size: 200,
                offset: Offset(40, 460 + oscillation.value),
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
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 28),
          ],
        ),
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
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
              'Rejoignez la santé de demain.',
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AuthDimensions.paddingMD),
            Text(
              'Créé pour 2026 : expérience fluide, sécurité avancée, et un parcours patient / praticien repensé.',
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
                _Pill(text: 'Onboarding rapide'),
                _Pill(text: 'UX 2026'),
                _Pill(text: 'Données sécurisées'),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
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
