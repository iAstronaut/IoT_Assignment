import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double? width;
  final double? height;
  final double blurIntensity;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isClickable;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.width,
    this.height,
    this.blurIntensity = 10,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.isClickable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppTheme.defaultPadding),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: gradient,
            boxShadow: boxShadow ?? AppTheme.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (isClickable && onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }

  // Factory constructor for creating a loading card
  factory GlassCard.loading({
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
  }) {
    return GlassCard(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  // Factory constructor for creating a shimmer loading effect
  factory GlassCard.shimmer({
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
  }) {
    return GlassCard(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      child: const SizedBox(),
    );
  }
}