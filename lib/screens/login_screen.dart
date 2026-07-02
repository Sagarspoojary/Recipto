import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signInEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  String _getFriendlyErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('user-not-found')) {
      return 'No account exists for this email. Please sign up.';
    } else if (errStr.contains('invalid-credential') || errStr.contains('wrong-password')) {
      return 'Credentials mismatched. Please check your email or password.';
    } else if (errStr.contains('invalid-email')) {
      return 'The email address format is invalid.';
    } else if (errStr.contains('too-many-requests')) {
      return 'Too many login attempts. Please try again later.';
    } else if (errStr.contains('network-request-failed')) {
      return 'Connection failed. Please check your internet connection.';
    }
    return error.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  void _showEmailPromptDialog(BuildContext context, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            title: const Text('Email Address Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your GitHub account does not provide a public email address. Please enter an email address to continue.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.email_outlined, color: ReceiptoTheme.secondary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.02),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final email = controller.text.trim();
                  if (email.isNotEmpty && email.contains('@')) {
                    final profileService = ref.read(profileServiceProvider);
                    final profile = await profileService.getUserProfile(uid);
                    if (profile != null) {
                      await profileService.saveUserProfile(profile.copyWith(email: email));
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address.')),
                    );
                  }
                },
                child: const Text('Submit', style: TextStyle(color: ReceiptoTheme.secondary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mediaQuery = MediaQuery.of(context);
    final isTabletOrDesktop = mediaQuery.size.width > 600;

    ref.listen(authProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null) {
          final profileService = ref.read(profileServiceProvider);
          final profile = await profileService.getUserProfile(user.uid);
          if (profile != null && profile.email.isEmpty) {
            if (context.mounted) {
              _showEmailPromptDialog(context, user.uid);
            }
          } else {
            if (context.mounted) {
              context.go('/dashboard');
            }
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
                    glowColor: ReceiptoTheme.primary,
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
                            // 1. Top Section: Logo, Title, Subtitle
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ReceiptoTheme.primary.withOpacity(0.4),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .rotate(duration: 8.seconds),
                            const SizedBox(height: 16),
                            Text(
                              'Receipto',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: ReceiptoTheme.secondary.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome back! Sign in to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 2. Email Field
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildFieldDecoration('Email Address', Icons.email_outlined),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _buildFieldDecoration(
                                'Password',
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white30,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4. Forgot Password & Remember Me Row
                            // 4. Forgot Password aligned to the right
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push('/forgot-password'),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: ReceiptoTheme.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 5. Login Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: authState.isLoading ? null : _submitLogin,
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ReceiptoTheme.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: authState.isLoading
                                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 6. Divider
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

                            // 7. Social Login Buttons
                            isTabletOrDesktop
                                ? Row(
                                    children: _buildSocialButtons(ref),
                                  )
                                : Column(
                                    children: _buildSocialButtons(ref, vertical: true),
                                  ),
                            const SizedBox(height: 32),

                            // 8. Bottom Section: Sign Up
                            GestureDetector(
                              onTap: () => context.push('/signup'),
                              child: Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                                    children: const [
                                      TextSpan(text: "Don't have an account? "),
                                      TextSpan(
                                        text: 'Sign Up',
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
                              const SizedBox(height: 16),
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

  InputDecoration _buildFieldDecoration(String placeholder, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: ReceiptoTheme.primary, size: 18),
      suffixIcon: suffix,
      labelText: placeholder,
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
        borderSide: const BorderSide(color: ReceiptoTheme.primary),
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
