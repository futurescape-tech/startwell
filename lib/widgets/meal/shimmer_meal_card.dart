import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';

class ShimmerMealCard extends StatelessWidget {
  const ShimmerMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width to make the card responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2) - 24; // Account for padding and spacing

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: ShimmerWidgets.shimmerBox(
              height: 140,
              width: double.infinity,
              borderRadius: 0,
            ),
          ),

          // Content placeholder
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ShimmerWidgets.shimmerText(
                    height: 18,
                    width: 160,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),

                  // Description - 2 lines
                  ShimmerWidgets.shimmerText(
                    height: 12,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidgets.shimmerText(
                    height: 12,
                    width: 180,
                    borderRadius: 4,
                  ),
                  const Spacer(),

                  // Price and button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      ShimmerWidgets.shimmerText(
                        height: 16,
                        width: 60,
                        borderRadius: 4,
                      ),

                      // Add button
                      ShimmerWidgets.shimmerBox(
                        height: 32,
                        width: 70,
                        borderRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
