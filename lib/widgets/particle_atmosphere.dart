import 'dart:math';
import 'package:flutter/material.dart';

class ParticleAtmosphere extends StatefulWidget {
  final Widget child;
  const ParticleAtmosphere({Key? key, required this.child}) : super(key: key);

  @override
  State<ParticleAtmosphere> createState() => _ParticleAtmosphereState();
}

class _ParticleAtmosphereState extends State<ParticleAtmosphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BlobParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Create 5-7 large particles with different colors and trajectories
    final colors = [
      const Color(0x336C63FF), // Purple
      const Color(0x2200E5FF), // Cyan
      const Color(0x22FF5ACD), // Pink
      const Color(0x199EFFA9), // Highlight Green
      const Color(0x2A6C63FF),
    ];

    for (int i = 0; i < 6; i++) {
      _particles.add(
        BlobParticle(
          baseX: _random.nextDouble(),
          baseY: _random.nextDouble(),
          radius: 120.0 + _random.nextDouble() * 150.0,
          color: colors[i % colors.length],
          speedX: 0.05 + _random.nextDouble() * 0.05,
          speedY: 0.05 + _random.nextDouble() * 0.05,
          amplitude: 0.1 + _random.nextDouble() * 0.15,
          phase: _random.nextDouble() * pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark Background
            Container(color: const Color(0xff050816)),
            // Animated Custom Paint Blobs
            Positioned.fill(
              child: CustomPaint(
                painter: BlobPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
            // Background Noise or Backdrop Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            if (widget.child != null) widget.child,
          ],
        );
      },
    );
  }
}

class BlobParticle {
  final double baseX;
  final double baseY;
  final double radius;
  final Color color;
  final double speedX;
  final double speedY;
  final double amplitude;
  final double phase;

  BlobParticle({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.amplitude,
    required this.phase,
  });

  Offset getOffset(Size size, double progress) {
    final angle = progress * pi * 2 + phase;
    // Mathematical organic movement
    final dx = baseX * size.width + sin(angle * speedX * 10) * amplitude * size.width * 0.2;
    final dy = baseY * size.height + cos(angle * speedY * 10) * amplitude * size.height * 0.2;
    return Offset(dx, dy);
  }
}

class BlobPainter extends CustomPainter {
  final List<BlobParticle> particles;
  final double progress;

  BlobPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    for (final particle in particles) {
      final offset = particle.getOffset(size, progress);
      // Soft breathing size
      final breath = 1.0 + 0.15 * sin(progress * pi * 2 + particle.phase);
      final currentRadius = particle.radius * breath;

      final rect = Rect.fromCircle(center: offset, radius: currentRadius);
      paint.shader = RadialGradient(
        colors: [
          particle.color,
          particle.color.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

      canvas.drawCircle(offset, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) => true;
}
