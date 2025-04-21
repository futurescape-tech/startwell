import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/screens/subscription_selection_screen.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/veg_icon.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';

class Review {
  final String name;
  final int rating;
  final String comment;

  Review({required this.name, required this.rating, required this.comment});
}

class MealDetailPage extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String sourceTab;
  final bool isExpressTab;

  const MealDetailPage({
    super.key,
    required this.meal,
    required this.sourceTab,
    this.isExpressTab = false,
  });

  String _getDescription(String mealName) {
    final jainMeals = ['Jain Breakfast', 'Jain Lunch'];
    if (jainMeals.contains(mealName)) {
      return "Jain Meals Exclude Underground Roots (Onion, Garlic, Potato, Ginger, Carrot, Radish, Beetroot, Yam, Turnip, Sweet Potato)";
    } else {
      return "A rotating menu of Indian and International options to introduce diverse flavours to the child.";
    }
  }

  // Dummy reviews list
  List<Review> _getDummyReviews() {
    return [
      Review(
        name: 'Priya Sharma',
        rating: 5,
        comment: 'My kid loved it! The food was fresh and tasty.',
      ),
      Review(
        name: 'Rahul Mehta',
        rating: 4,
        comment: 'Fresh and on time. Excellent service every time.',
      ),
      Review(
        name: 'Anjali Patel',
        rating: 5,
        comment: 'Great variety and nutritious options for kids.',
      ),
      Review(
        name: 'Vikram Singh',
        rating: 4,
        comment: 'The jain options are perfect for our family needs.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _getDummyReviews();

    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Meal Details',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Image
              Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Image.asset(
                      meal['image'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isExpressTab
                                    ? (meal['isVeg']
                                        ? Icons.stop
                                        : Icons.restaurant)
                                    : Icons.stop,
                                size: 40,
                                color: isExpressTab
                                    ? (meal['isVeg']
                                        ? Colors.green
                                        : Colors.brown)
                                    : Colors.green,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meal['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Show "Most Recommended" badge only for specific meals
                  if ((sourceTab == 'breakfast' &&
                          meal['name'] == 'Breakfast of the Day') ||
                      (sourceTab == 'lunch' &&
                          meal['name'] == 'Lunch of the Day'))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8E2DE2), // Purple
                                Color(0xFFFF6A00), // Orange
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Most Recommended',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Meal Name + Veg Icon
              Row(
                children: [
                  const VegIcon(),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meal['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                '₹${meal['price']}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.purple,
                ),
              ),

              // Animated Offer Text - only show for non-express tabs
              if (sourceTab != 'express 1 day lunch')
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.pink],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '💸 Save 20% on Annual - 200 days',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Description
              Text(
                _getDescription(meal['name']),
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 16),

              // Rating
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 20,
                    color: index < 4 ? Colors.orange : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reviews Section Header
              Text(
                "Parent Reviews",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // Horizontally scrollable reviews - Fixed height and improved layout
              SizedBox(
                height: 150, // Slightly increased height to prevent overflow
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final review = reviews[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.purple.withOpacity(
                                    0.2,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppTheme.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    review.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < review.rating
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review.comment,
                              style: GoogleFonts.poppins(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Choose Plan Button with additional bottom padding for safety
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Create a dummy meal to pass to the subscription screen
                      final mealCategory = sourceTab == 'breakfast'
                          ? MealCategory.breakfast
                          : sourceTab == 'express 1 day lunch'
                              ? MealCategory.expressOneDay
                              : MealCategory.lunch;

                      print('Creating meal with image: ${meal['image']}');
                      final dummyMeal = Meal(
                        id: 'dummy',
                        name: meal['name'],
                        description: _getDescription(meal['name']),
                        price: meal['price'].toDouble(),
                        type: MealType.veg,
                        categories: [mealCategory],
                        imageUrl: meal['image'],
                        ingredients: [],
                        nutritionalInfo: {},
                        allergyInfo: [],
                      );

                      // Create an empty selection manager
                      final selectionManager = MealSelectionManager();

                      // Navigate to subscription selection screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionSelectionScreen(
                            selectionManager: selectionManager,
                            selectedMeals: [dummyMeal],
                            totalMealCost: meal['price'].toDouble(),
                            mealType: sourceTab,
                            isExpressOrder: isExpressTab,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Choose Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
