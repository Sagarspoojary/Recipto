import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

enum PasswordStrength { weak, fair, good, strong, excellent }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  PasswordStrength _strength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_analyzePassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _analyzePassword() {
    final text = _passwordController.text;
    if (text.isEmpty) {
      setState(() => _strength = PasswordStrength.weak);
      return;
    }

    int score = 0;
    if (text.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(text) && RegExp(r'[A-Z]').hasMatch(text)) score++;
    if (RegExp(r'[0-9]').hasMatch(text)) score++;
    if (RegExp(r'[!@#\$&*~-]').hasMatch(text)) score++;
    if (text.length >= 12) score++;

    setState(() {
      if (score <= 1) {
        _strength = PasswordStrength.weak;
      } else if (score == 2) {
        _strength = PasswordStrength.fair;
      } else if (score == 3) {
        _strength = PasswordStrength.good;
      } else if (score == 4) {
        _strength = PasswordStrength.strong;
      } else {
        _strength = PasswordStrength.excellent;
      }
    });
  }

  void _submitSignUp() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to register.'),
          backgroundColor: ReceiptoTheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signUpEmail(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  Color _getStrengthColor() {
    switch (_strength) {
      case PasswordStrength.weak:
        return ReceiptoTheme.error;
      case PasswordStrength.fair:
        return ReceiptoTheme.warning;
      case PasswordStrength.good:
        return ReceiptoTheme.primary;
      case PasswordStrength.strong:
        return ReceiptoTheme.secondary;
      case PasswordStrength.excellent:
        return ReceiptoTheme.highlight;
    }
  }

  String _getStrengthText() {
    switch (_strength) {
      case PasswordStrength.weak:
        return 'WEAK';
      case PasswordStrength.fair:
        return 'FAIR';
      case PasswordStrength.good:
        return 'GOOD';
      case PasswordStrength.strong:
        return 'STRONG';
      case PasswordStrength.excellent:
        return 'EXCELLENT';
    }
  }

  String _getFriendlyErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (errStr.contains('weak-password')) {
      return 'The password is too weak. Please use a stronger password.';
    } else if (errStr.contains('invalid-email')) {
      return 'The email address format is invalid.';
    } else if (errStr.contains('network-request-failed')) {
      return 'Connection failed. Please check your internet connection.';
    }
    return error.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mediaQuery = MediaQuery.of(context);
    final isTabletOrDesktop = mediaQuery.size.width > 600;

    ref.listen(authProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null) {
          await ref.read(authProvider.notifier).sendVerification();
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created! Please check your email to verify and sign in.'),
                backgroundColor: ReceiptoTheme.primary,
              ),
            );
            context.go('/login');
          }
        }
      });
    });

    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Hero(
                  tag: 'auth_card',
                  child: BentoCard(
                    glowColor: _getStrengthColor(),
                    borderRadius: 32,
                    child: Container(
                      width: isTabletOrDesktop ? 500 : double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Register Node',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    color: _getStrengthColor().withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Full Name
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                              validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 12),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Password', Icons.lock_outline, togglePass: true),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                if (val.length < 8) return 'Password must be at least 8 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Strength indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PASSWORD STRENGTH: ${_getStrengthText()}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStrengthColor(), letterSpacing: 1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (_strength.index + 1) / 5,
                                minHeight: 4,
                                color: _getStrengthColor(),
                                backgroundColor: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Confirm Password', Icons.lock_outline),
                              validator: (val) {
                                if (val != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Terms & Conditions Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: ReceiptoTheme.secondary,
                                  checkColor: Colors.black,
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptTerms = val ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'I accept the Terms and Conditions of service.',
                                    style: TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Create Account Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: authState.isLoading ? null : _submitSignUp,
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Social Buttons
                            isTabletOrDesktop
                                ? Row(
                                    children: _buildSocialButtons(ref),
                                  )
                                : Column(
                                    children: _buildSocialButtons(ref, vertical: true),
                                  ),
                            const SizedBox(height: 32),

                            // Footer: Back to Login
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                                    children: const [
                                      TextSpan(text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: ReceiptoTheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (authState.hasError) ...[
                              const SizedBox(height: 12),
                              Text(
                                _getFriendlyErrorMessage(authState.error!),
                                style: const TextStyle(color: ReceiptoTheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {bool togglePass = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: ReceiptoTheme.secondary, size: 18),
      suffixIcon: togglePass
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white30,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ReceiptoTheme.secondary),
      ),
    );
  }

  List<Widget> _buildSocialButtons(WidgetRef ref, {bool vertical = false}) {
    final List<Widget> buttons = [
      _SocialItemButton(
        provider: 'Google',
        logoAsset: 'assets/images/google.png',
        onTap: () => ref.read(authProvider.notifier).signInGoogle(),
      ),
      _SocialItemButton(
        provider: 'GitHub',
        logoAsset: 'assets/images/github.png',
        onTap: () => ref.read(authProvider.notifier).signInGitHub(),
      ),
    ];

    if (vertical) {
      return buttons
          .map((b) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: b))
          .toList();
    }

    return buttons
        .map((b) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0), child: b)))
        .toList();
  }
}

class _SocialItemButton extends StatelessWidget {
  final String provider;
  final String logoAsset;
  final VoidCallback onTap;

  const _SocialItemButton({
    required this.provider,
    required this.logoAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                logoAsset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                provider,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.04));
  }
}
