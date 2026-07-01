import 'package:flutter/material.dart';

class KineticTypography extends StatefulWidget {
  const KineticTypography({Key? key}) : super(key: key);

  @override
  State<KineticTypography> createState() => _KineticTypographyState();
}

class _KineticTypographyState extends State<KineticTypography>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
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
        final progress = _controller.value;
        return Stack(
          children: [
            // Row 1: Left to Right
            Positioned(
              top: 80,
              left: -400 + (progress * 500) % 600,
              child: _OutlinedText(text: "RECEIPTO  AI  SMART  VAULT"),
            ),
            // Row 2: Right to Left
            Positioned(
              top: 240,
              right: -400 + (progress * 400) % 600,
              child: _OutlinedText(text: "SCAN  ORGANIZE  FLOW  SYNC"),
            ),
            // Row 3: Left to Right (Faster)
            Positioned(
              top: 400,
              left: -600 + (progress * 600) % 700,
              child: _OutlinedText(text: "CLOUD  SECURE  ANALYTICS"),
            ),
            // Row 4: Right to Left (Diagonally slightly offset)
            Positioned(
              top: 560 + ((progress - 0.5).abs() * 30),
              right: -500 + (progress * 300) % 600,
              child: _OutlinedText(text: "BENTO  MINIMAL  FUTURE  OS"),
            ),
            // Row 5: Left to Right
            Positioned(
              top: 720,
              left: -300 + (progress * 250) % 500,
              child: _OutlinedText(text: "RECEIPTS  TAX  BUDGET  AI"),
            ),
          ],
        );
      },
    );
  }
}

class _OutlinedText extends StatelessWidget {
  final String text;
  const _OutlinedText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 70,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withOpacity(0.025), // Very low contrast
      ),
    );
  }
}
