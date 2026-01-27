import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Border? border;
  final Clip clipBehavior;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.7,
    this.borderRadius = 24.0,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((opacity * 255).toInt()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: AppTheme.borderColor.withAlpha(100), width: 1.5),
            gradient: AppTheme.glassGradient,
          ),
          child: child,
        ),
      ),
    );
  }
}
