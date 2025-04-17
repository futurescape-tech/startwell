import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class HomeBannerShimmer extends StatelessWidget {
  const HomeBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidgets.shimmerCard(
      height: 160,
      borderRadius: 20,
      children: [
        ShimmerWidgets.shimmerText(
          height: 22,
          width: 200,
          borderRadius: 6,
        ),
        const SizedBox(height: 12),
        ShimmerWidgets.shimmerText(
          height: 14,
          width: double.infinity,
          borderRadius: 4,
        ),
        const SizedBox(height: 6),
        ShimmerWidgets.shimmerText(
          height: 14,
          width: MediaQuery.of(context).size.width * 0.7,
          borderRadius: 4,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ShimmerWidgets.shimmerButton(
            height: 40,
            width: 160,
            borderRadius: 20,
          ),
        ),
      ],
    );
  }
}

class SubscriptionCardShimmer extends StatelessWidget {
  const SubscriptionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Active Plan Card Shimmer
        _buildSubscriptionCardShimmer(),
        const SizedBox(height: 15),
        // Remaining Meals Card Shimmer
        _buildRemMealsCardShimmer(),
      ],
    );
  }

  Widget _buildSubscriptionCardShimmer() {
    return ShimmerWidgets.shimmerCard(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ShimmerWidgets.shimmerCircle(size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidgets.shimmerText(
                    height: 18,
                    width: 100,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerWidgets.shimmerText(
                    height: 14,
                    width: 180,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            ShimmerWidgets.shimmerBox(
              height: 24,
              width: 70,
              borderRadius: 12,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemMealsCardShimmer() {
    return ShimmerWidgets.shimmerCard(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ShimmerWidgets.shimmerCircle(size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidgets.shimmerText(
                    height: 18,
                    width: 150,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerWidgets.shimmerText(
                    height: 14,
                    width: 180,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 12),
                  ShimmerWidgets.shimmerBox(
                    height: 6,
                    width: double.infinity,
                    borderRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class UpcomingMealShimmer extends StatelessWidget {
  const UpcomingMealShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: ShimmerWidgets.shimmerCard(
            height: 90,
            borderRadius: 16,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShimmerWidgets.shimmerCircle(size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidgets.shimmerText(
                          height: 16,
                          width: 180,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 8),
                        ShimmerWidgets.shimmerText(
                          height: 14,
                          width: 120,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  ShimmerWidgets.shimmerBox(
                    height: 24,
                    width: 60,
                    borderRadius: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionsShimmer extends StatelessWidget {
  const QuickActionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShimmerWidgets.shimmerCard(
            height: 80,
            borderRadius: 16,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerWidgets.shimmerCircle(size: 30),
                  const SizedBox(width: 10),
                  ShimmerWidgets.shimmerText(
                    height: 16,
                    width: 80,
                    borderRadius: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ShimmerWidgets.shimmerCard(
            height: 80,
            borderRadius: 16,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerWidgets.shimmerCircle(size: 30),
                  const SizedBox(width: 10),
                  ShimmerWidgets.shimmerText(
                    height: 16,
                    width: 60,
                    borderRadius: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeScreenShimmer extends StatelessWidget {
  const HomeScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShimmerWidgets.shimmerText(
          height: 22,
          width: 80,
          borderRadius: 6,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ShimmerWidgets.shimmerCircle(size: 36),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Shimmer
              const HomeBannerShimmer(),
              const SizedBox(height: 30),

              // Subscription title
              ShimmerWidgets.shimmerText(
                height: 18,
                width: 180,
                borderRadius: 6,
              ),
              const SizedBox(height: 15),

              // Subscription Cards
              const SubscriptionCardShimmer(),
              const SizedBox(height: 30),

              // Upcoming meals title
              ShimmerWidgets.shimmerText(
                height: 18,
                width: 160,
                borderRadius: 6,
              ),
              const SizedBox(height: 15),

              // Upcoming meals
              const UpcomingMealShimmer(),
              const SizedBox(height: 30),

              // Quick actions title
              ShimmerWidgets.shimmerText(
                height: 18,
                width: 120,
                borderRadius: 6,
              ),
              const SizedBox(height: 15),

              // Quick actions
              const QuickActionsShimmer(),
              const SizedBox(height: 40),

              // Footer
              Center(
                child: Column(
                  children: [
                    ShimmerWidgets.shimmerText(
                      height: 18,
                      width: 220,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 8),
                    ShimmerWidgets.shimmerText(
                      height: 14,
                      width: 180,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
