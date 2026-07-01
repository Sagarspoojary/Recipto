import 'package:flutter/material.dart';
import 'glass_container.dart';
import 'tilt_container.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool animateHover;

  const BentoCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.glowColor,
    this.onTap,
    this.animateHover = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = GlassContainer(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          // Subtle glow in the corner
          if (glowColor != null)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                key: const Key('glow_circle'),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor!.withOpacity(0.12),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    if (onTap != null) {
      card = InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      );
    }

    if (animateHover) {
      return TiltContainer(
        maxTilt: 6.0,
        child: card,
      );
    }

    return card;
  }
}
