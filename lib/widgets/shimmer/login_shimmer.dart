import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class LoginScreenShimmer extends StatelessWidget {
  const LoginScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
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
                        width: 100,
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
                    height: 560,
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Logo shimmer
                      Center(
                        child: ShimmerWidgets.shimmerCircle(
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Welcome text shimmer
                      Center(
                        child: ShimmerWidgets.shimmerText(
                          height: 26,
                          width: 180,
                          borderRadius: 6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // One-liner shimmer
                      Center(
                        child: ShimmerWidgets.shimmerText(
                          height: 15,
                          width: 300,
                          borderRadius: 4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Toggle buttons shimmer
                      ShimmerWidgets.shimmerBox(
                        height: 48,
                        borderRadius: 16,
                      ),
                      const SizedBox(height: 30),

                      // Input field shimmers
                      ShimmerWidgets.shimmerTextField(
                        height: 56,
                        borderRadius: 12,
                      ),
                      const SizedBox(height: 20),
                      ShimmerWidgets.shimmerTextField(
                        height: 56,
                        borderRadius: 12,
                      ),
                      const SizedBox(height: 16),

                      // Forgot password link shimmer
                      Align(
                        alignment: Alignment.centerRight,
                        child: ShimmerWidgets.shimmerText(
                          height: 14,
                          width: 120,
                          borderRadius: 4,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Login button shimmer
                      ShimmerWidgets.shimmerButton(
                        height: 56,
                        borderRadius: 16,
                      ),
                      const SizedBox(height: 30),

                      // Sign up link shimmer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerWidgets.shimmerText(
                            height: 14,
                            width: 140,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 8),
                          ShimmerWidgets.shimmerText(
                            height: 14,
                            width: 60,
                            borderRadius: 4,
                          ),
                        ],
                      ),
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
