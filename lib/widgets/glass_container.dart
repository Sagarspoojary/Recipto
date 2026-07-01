import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? customBorder;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 16.0,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.customBorder,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: color ?? ReceiptoTheme.glassWhite,
              border: customBorder ??
                  Border.all(
                    color: borderColor ?? ReceiptoTheme.glassBorder,
                    width: 1.5,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
