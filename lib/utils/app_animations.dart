import 'package:flutter/material.dart';

class AppAnimations {
  // Page transition animation
  static PageRouteBuilder pageRouteBuilder({
    required Widget page,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // Button animations
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    bool isVisible = true,
    Duration duration = const Duration(milliseconds: 700),
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.95,
        duration: duration,
        curve: curve,
        child: ElevatedButton(onPressed: onPressed, child: child),
      ),
    );
  }

  // Animated container with gradient
  static Widget animatedGradientContainer({
    required Widget child,
    required Gradient gradient,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return AnimatedContainer(
      duration: duration,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: child,
    );
  }

  // Text fade-in animation
  static Widget animatedText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    bool isVisible = true,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.easeInOut,
      child: AnimatedPadding(
        padding: EdgeInsets.only(top: isVisible ? 0 : 20),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Text(text, style: style, textAlign: textAlign),
      ),
    );
  }

  // Staggered list item animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    required bool isVisible,
    Duration baseDuration = const Duration(milliseconds: 600),
    Duration baseDelay = const Duration(milliseconds: 100),
  }) {
    // Calculate delay based on index
    final delayTime = Duration(milliseconds: baseDelay.inMilliseconds * index);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isVisible ? 1.0 : 0.0),
      duration: baseDuration,
      // Apply delay by using onEnd for first invisible render
      onEnd: () {},
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
