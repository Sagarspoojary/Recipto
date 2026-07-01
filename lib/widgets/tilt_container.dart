import 'dart:math';
import 'package:flutter/material.dart';

class TiltContainer extends StatefulWidget {
  final Widget child;
  final double maxTilt; // in degrees
  final double scaleOnHover;
  final Duration duration;

  const TiltContainer({
    Key? key,
    required this.child,
    this.maxTilt = 8.0,
    this.scaleOnHover = 1.02,
    this.duration = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  State<TiltContainer> createState() => _TiltContainerState();
}

class _TiltContainerState extends State<TiltContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;
  late Animation<double> _animationScale;

  double _rotateX = 0.0;
  double _rotateY = 0.0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    _animationX = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _animationY = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _animationScale = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onMove(PointerEvent event, Size size) {
    // Calculate normalized coordinates (-1 to 1) from the center
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    final x = (event.localPosition.dx - halfWidth) / halfWidth;
    final y = (event.localPosition.dy - halfHeight) / halfHeight;

    // Constrain bounds
    final clampedX = x.clamp(-1.0, 1.0);
    final clampedY = y.clamp(-1.0, 1.0);

    setState(() {
      // Rotate around X axis based on Y position and vice-versa
      _rotateX = -clampedY * (widget.maxTilt * pi / 180);
      _rotateY = clampedX * (widget.maxTilt * pi / 180);
      _scale = widget.scaleOnHover;
    });
  }

  void _onLeave() {
    // Reset to zero with smooth spring back
    _animationX = Tween<double>(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _animationY = Tween<double>(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _animationScale = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _rotateX = 0.0;
        _rotateY = 0.0;
        _scale = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 200,
          constraints.hasBoundedHeight ? constraints.maxHeight : 200,
        );

        final transformMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_controller.isAnimating ? _animationX.value : _rotateX)
          ..rotateY(_controller.isAnimating ? _animationY.value : _rotateY)
          ..scale(_controller.isAnimating ? _animationScale.value : _scale);

        return Listener(
          onPointerMove: (event) => _onMove(event, size),
          onPointerDown: (event) => _onMove(event, size),
          onPointerUp: (_) => _onLeave(),
          onPointerCancel: (_) => _onLeave(),
          child: MouseRegion(
            onExit: (_) => _onLeave(),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform(
                  transform: transformMatrix,
                  alignment: FractionalOffset.center,
                  child: widget.child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
