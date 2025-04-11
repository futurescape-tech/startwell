import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:startwell/utils/app_colors.dart';

/// A utility class that provides reusable shimmer widgets for loading states
class ShimmerWidgets {
  // Base shimmer configuration
  static Shimmer _baseShimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: AppColors.primary.withOpacity(0.2),
      highlightColor: AppColors.primary.withOpacity(0.05),
      period: const Duration(
          milliseconds: 1500), // Slightly slower for smoother effect
      child: child,
    );
  }

  // Rectangle box with optional rounded corners
  static Widget shimmerBox({
    double height = 20,
    double width = double.infinity,
    double borderRadius = 8,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Circle shimmer (for avatars, logos, etc.)
  static Widget shimmerCircle({
    double size = 48,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return _baseShimmer(
      child: Container(
        height: size,
        width: size,
        margin: margin,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Card with shimmer effect
  static Widget shimmerCard({
    double height = 100,
    double width = double.infinity,
    double borderRadius = 16,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    List<Widget> children = const [],
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  // Text field shimmer
  static Widget shimmerTextField({
    double height = 56,
    double borderRadius = 12,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: double.infinity,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }

  // Button shimmer
  static Widget shimmerButton({
    double height = 56,
    double width = double.infinity,
    double borderRadius = 16,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Text shimmer
  static Widget shimmerText({
    double height = 16,
    double width = 150,
    double borderRadius = 4,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4),
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // List item shimmer
  static Widget shimmerListItem({
    double height = 80,
    double width = double.infinity,
    double borderRadius = 12,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return _baseShimmer(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            // Avatar/icon placeholder
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Content placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
