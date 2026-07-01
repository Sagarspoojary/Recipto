import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return Scaffold(
      body: ParticleAtmosphere(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: KineticTypography()),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings & Core',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User Info Card
                    if (user != null)
                      BentoCard(
                        glowColor: ReceiptoTheme.secondary,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  user.photoUrl ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: ReceiptoTheme.secondary.withOpacity(0.15),
                                        border: Border.all(color: ReceiptoTheme.secondary, width: 0.5),
                                      ),
                                      child: Text(
                                        'MEMBERSHIP: ${user.membership.toUpperCase()}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ReceiptoTheme.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Storage Grid Info
                    BentoCard(
                      glowColor: ReceiptoTheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SECURE CLOUD STORAGE', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                            const SizedBox(height: 16),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('12.4 MB Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('100.0 MB Max', style: TextStyle(color: Colors.white30, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.124,
                                minHeight: 8,
                                color: ReceiptoTheme.primary,
                                backgroundColor: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Controls Bento Grid
                    BentoCard(
                      glowColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SYSTEM OPTIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
                            const SizedBox(height: 12),

                            SwitchListTile(
                              title: const Text('Biometric Security', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Require FaceID / TouchID on startup', style: TextStyle(fontSize: 11)),
                              value: true,
                              activeColor: ReceiptoTheme.secondary,
                              onChanged: (_) {},
                            ),
                            const Divider(color: Colors.white12),
                            SwitchListTile(
                              title: const Text('Dynamic Particles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Enable neural network background motion', style: TextStyle(fontSize: 11)),
                              value: true,
                              activeColor: ReceiptoTheme.secondary,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Log out
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        context.go('/auth');
                      },
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ReceiptoTheme.error.withOpacity(0.1),
                          border: Border.all(color: ReceiptoTheme.error.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'TERMINATE SESSION (LOG OUT)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: ReceiptoTheme.error, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
