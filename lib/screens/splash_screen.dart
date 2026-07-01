import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate animated loading bar
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _timer?.cancel();
          context.go('/login');
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Morphing Glass Logo
                  GlassContainer(
                    width: 130,
                    height: 130,
                    borderRadius: 36,
                    color: Colors.white.withOpacity(0.06),
                    borderColor: ReceiptoTheme.secondary.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ReceiptoTheme.secondary.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 1200.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                      )
                      .shimmer(delay: 500.ms, duration: 1500.ms),

                  const SizedBox(height: 40),

                  // App Title
                  Text(
                    'RECEIPTO',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: ReceiptoTheme.secondary.withOpacity(0.8),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'YOUR INTELLIGENT RECEIPT VAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: ReceiptoTheme.secondary.withOpacity(0.8),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut),

                  const SizedBox(height: 60),

                  // Loading Indicator
                  SizedBox(
                    width: 200,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          Container(color: Colors.white.withOpacity(0.1)),
                          FractionallySizedBox(
                            widthFactor: _progress,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ReceiptoTheme.primary,
                                    ReceiptoTheme.secondary,
                                    ReceiptoTheme.accent,
                                  ],
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
        ),
      ),
    );
  }
}
