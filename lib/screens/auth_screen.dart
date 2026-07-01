import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Watch for success
    ref.listen(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          context.go('/permissions');
        }
      });
    });

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
                    glowColor: ReceiptoTheme.secondary,
                    borderRadius: 32,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Spinning glowing logo
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ReceiptoTheme.primary.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat())
                                .rotate(duration: 6.seconds),

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
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 8),

                            Text(
                              'Secure. Classify. Analyze. Instant OCR.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: ReceiptoTheme.textSecondary,
                                  ),
                            ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

                            const SizedBox(height: 32),

                            if (authState.isLoading)
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(ReceiptoTheme.secondary),
                              )
                            else ...[
                              _SocialButton(
                                label: 'Continue with Google',
                                icon: Icons.g_mobiledata,
                                color: const Color(0xffEA4335),
                                onTap: () => ref.read(authProvider.notifier).signInGoogle(),
                              ),
                              const SizedBox(height: 12),
                              _SocialButton(
                                label: 'Continue with Apple',
                                icon: Icons.apple,
                                color: Colors.black,
                                onTap: () => ref.read(authProvider.notifier).signInApple(),
                              ),
                              const SizedBox(height: 12),
                              _SocialButton(
                                label: 'Continue with GitHub',
                                icon: Icons.code,
                                color: const Color(0xff24292e),
                                onTap: () => ref.read(authProvider.notifier).signInGitHub(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      'OR DEVELOPER EVALUATION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SocialButton(
                                label: 'Launch Demo Mode (Offline)',
                                icon: Icons.flash_on_rounded,
                                color: ReceiptoTheme.primary,
                                isAccent: true,
                                onTap: () => ref.read(authProvider.notifier).signInMock(),
                              ),
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
  final Color color;
  final VoidCallback onTap;
  final bool isAccent;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: isAccent ? ReceiptoTheme.secondary.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isAccent ? ReceiptoTheme.secondary : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .shimmer(duration: 1800.ms, color: Colors.white.withOpacity(0.05));
  }
}
