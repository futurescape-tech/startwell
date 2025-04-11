import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class LaunchScreenShimmer extends StatelessWidget {
  const LaunchScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = screenHeight * 0.15;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),

              // App logo shimmer
              Center(
                child: ShimmerWidgets.shimmerCircle(
                  size: logoSize,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // App title shimmer
              ShimmerWidgets.shimmerText(
                height: 40,
                width: 200,
                borderRadius: 8,
              ),
              SizedBox(height: screenHeight * 0.02),

              // App one-liner shimmer
              ShimmerWidgets.shimmerText(
                height: 16,
                width: 300,
                borderRadius: 4,
              ),
              SizedBox(height: screenHeight * 0.01),
              ShimmerWidgets.shimmerText(
                height: 16,
                width: 250,
                borderRadius: 4,
              ),
              SizedBox(height: screenHeight * 0.02),

              // Welcome message shimmer
              ShimmerWidgets.shimmerBox(
                height: 80,
                width: double.infinity,
                borderRadius: 20,
              ),

              const Spacer(),

              // Login button shimmer
              ShimmerWidgets.shimmerButton(
                height: 56,
                width: double.infinity,
                borderRadius: 16,
              ),
              const SizedBox(height: 20),

              // Sign up button shimmer
              ShimmerWidgets.shimmerButton(
                height: 56,
                width: double.infinity,
                borderRadius: 16,
              ),
              SizedBox(height: screenHeight * 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
