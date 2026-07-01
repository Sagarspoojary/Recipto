import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Auto-routing to permissions or verification if user logins successfully
    ref.listen(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          context.go('/dashboard');
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Hero(
                  tag: 'auth_card',
                  child: BentoCard(
                    glowColor: ReceiptoTheme.secondary,
                    borderRadius: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Spinning glowing logo
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ReceiptoTheme.primary.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .rotate(duration: 8.seconds),

                          const SizedBox(height: 24),

                          Text(
                            'Welcome to Receipto',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              shadows: [
                                Shadow(
                                  color: ReceiptoTheme.secondary.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 8),

                          Text(
                            'Your Intelligent Receipt Vault',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ReceiptoTheme.textSecondary,
                                ),
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                          const SizedBox(height: 36),

                          if (authState.isLoading)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(ReceiptoTheme.secondary),
                            )
                          else ...[
                            _SocialButton(
                              label: 'Continue with Google',
                              icon: Icons.g_mobiledata,
                              onTap: () => ref.read(authProvider.notifier).signInGoogle(),
                            ),
                            const SizedBox(height: 12),
                            _SocialButton(
                              label: 'Continue with Apple',
                              icon: Icons.apple,
                              onTap: () => ref.read(authProvider.notifier).signInApple(),
                            ),
                            const SizedBox(height: 12),
                            _SocialButton(
                              label: 'Continue with GitHub',
                              icon: Icons.code,
                              onTap: () => ref.read(authProvider.notifier).signInGitHub(),
                            ),
                            const SizedBox(height: 12),
                            _SocialButton(
                              label: 'Continue with Email',
                              icon: Icons.email_rounded,
                              isEmail: true,
                              onTap: () => context.push('/login'),
                            ),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: () => context.push('/signup'),
                              child: Text(
                                "Don't have an account? Sign Up",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ReceiptoTheme.secondary.withOpacity(0.9),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                          ],
                          if (authState.hasError) ...[
                            const SizedBox(height: 16),
                            Text(
                              authState.error.toString(),
                              style: const TextStyle(color: ReceiptoTheme.error, fontSize: 12),
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
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEmail;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: isEmail ? ReceiptoTheme.secondary.withOpacity(0.3) : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isEmail ? ReceiptoTheme.secondary : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.04));
  }
}
