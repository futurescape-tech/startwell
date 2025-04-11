import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class DashboardScreenShimmer extends StatelessWidget {
  const DashboardScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom App Bar shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerWidgets.shimmerText(
                    height: 24,
                    width: 120,
                    borderRadius: 6,
                  ),
                  ShimmerWidgets.shimmerCircle(size: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section shimmer
                      ShimmerWidgets.shimmerText(
                        height: 28,
                        width: 180,
                        borderRadius: 6,
                      ),
                      const SizedBox(height: 8),
                      ShimmerWidgets.shimmerText(
                        height: 16,
                        width: 220,
                        borderRadius: 4,
                      ),

                      const SizedBox(height: 25),

                      // Today's Meal Card shimmer
                      ShimmerWidgets.shimmerCard(
                        height: 160,
                        borderRadius: 16,
                        children: [
                          Row(
                            children: [
                              ShimmerWidgets.shimmerBox(
                                height: 44,
                                width: 44,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerWidgets.shimmerText(
                                      height: 18,
                                      width: 120,
                                      borderRadius: 4,
                                    ),
                                    const SizedBox(height: 6),
                                    ShimmerWidgets.shimmerText(
                                      height: 14,
                                      width: 200,
                                      borderRadius: 4,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 15),
                          // Meal items shimmer
                          Row(
                            children: [
                              _buildMealItemShimmer(),
                              _buildMealItemShimmer(),
                              _buildMealItemShimmer(),
                              _buildMealItemShimmer(),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Nutrition progress shimmer
                      ShimmerWidgets.shimmerText(
                        height: 20,
                        width: 160,
                        borderRadius: 5,
                      ),
                      const SizedBox(height: 15),

                      ShimmerWidgets.shimmerCard(
                        height: 200,
                        borderRadius: 16,
                        children: [
                          _buildNutritionProgressBarShimmer(),
                          const SizedBox(height: 15),
                          _buildNutritionProgressBarShimmer(),
                          const SizedBox(height: 15),
                          _buildNutritionProgressBarShimmer(),
                          const SizedBox(height: 15),
                          _buildNutritionProgressBarShimmer(),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Weekly schedule section shimmer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerWidgets.shimmerText(
                            height: 20,
                            width: 150,
                            borderRadius: 5,
                          ),
                          ShimmerWidgets.shimmerText(
                            height: 16,
                            width: 60,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Weekly schedule cards shimmer
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: [
                            _buildDayCardShimmer(),
                            _buildDayCardShimmer(),
                            _buildDayCardShimmer(),
                            _buildDayCardShimmer(),
                            _buildDayCardShimmer(),
                          ],
                        ),
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

  Widget _buildMealItemShimmer() {
    return Expanded(
      child: Column(
        children: [
          ShimmerWidgets.shimmerBox(
            height: 40,
            width: 40,
            borderRadius: 10,
          ),
          const SizedBox(height: 8),
          ShimmerWidgets.shimmerText(
            height: 12,
            width: 50,
            borderRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionProgressBarShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerWidgets.shimmerText(
              height: 14,
              width: 70,
              borderRadius: 4,
            ),
            ShimmerWidgets.shimmerText(
              height: 14,
              width: 40,
              borderRadius: 4,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShimmerWidgets.shimmerBox(
          height: 8,
          borderRadius: 10,
        ),
      ],
    );
  }

  Widget _buildDayCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ShimmerWidgets.shimmerBox(
        height: 90,
        width: 120,
        borderRadius: 15,
      ),
    );
  }
}
