import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authProvider.notifier).sendResetEmail(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('user-not-found')) {
      return 'No account associated with this email exists.';
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

    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Hero(
                  tag: 'auth_card',
                  child: BentoCard(
                    glowColor: ReceiptoTheme.warning,
                    borderRadius: 32,
                    child: Container(
                      width: isTabletOrDesktop ? 450 : double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              _isSuccess ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                              size: 60,
                              color: _isSuccess ? ReceiptoTheme.highlight : ReceiptoTheme.warning,
                            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 20),

                            // Title
                            Text(
                              'Reset Password',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    color: _isSuccess ? ReceiptoTheme.highlight.withOpacity(0.5) : ReceiptoTheme.warning.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              _isSuccess
                                  ? 'Password reset email sent successfully.'
                                  : 'Enter your registered email address to receive a password reset link.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (!_isSuccess) ...[
                              // Email Address Field
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.email_outlined, color: ReceiptoTheme.warning, size: 20),
                                  labelText: 'Email Address',
                                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.02),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: ReceiptoTheme.warning),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: authState.isLoading ? null : _submitReset,
                                child: Container(
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [ReceiptoTheme.warning, ReceiptoTheme.accent],
                                    ),
                                  ),
                                  child: authState.isLoading
                                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                                      : const Text(
                                          'Send Reset Link',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                        ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Footer: Back to Sign In
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Back to Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ReceiptoTheme.secondary.withOpacity(0.8),
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
}
