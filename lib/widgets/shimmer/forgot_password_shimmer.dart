import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class ForgotPasswordScreenShimmer extends StatelessWidget {
  const ForgotPasswordScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar shimmer
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  ShimmerWidgets.shimmerCircle(size: 40),
                  Expanded(
                    child: Center(
                      child: ShimmerWidgets.shimmerText(
                        height: 22,
                        width: 160,
                        borderRadius: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form content shimmer
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ShimmerWidgets.shimmerCard(
                    height: 420,
                    borderRadius: 24,
                    padding: const EdgeInsets.all(28),
                    children: [
                      SizedBox(height: screenHeight * 0.02),

                      // Logo shimmer
                      Center(
                        child: ShimmerWidgets.shimmerCircle(
                          size: 100,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Title shimmer
                      Center(
                        child: ShimmerWidgets.shimmerText(
                          height: 24,
                          width: 200,
                          borderRadius: 6,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Instructions text shimmer
                      Center(
                        child: ShimmerWidgets.shimmerText(
                          height: 15,
                          width: 300,
                          borderRadius: 4,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Input field shimmer
                      ShimmerWidgets.shimmerTextField(
                        height: 56,
                        borderRadius: 12,
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Submit button shimmer
                      ShimmerWidgets.shimmerButton(
                        height: 56,
                        borderRadius: 16,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
