import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/screens/subscription_selection_screen.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/veg_icon.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/utils/meal_constants.dart';

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

    // Get color and icon based on meal type
    final Color mealTypeColor = MealConstants.getIconColor(sourceTab);
    final Color mealBgColor = MealConstants.getBgColor(sourceTab);
    final IconData mealIcon = MealConstants.getIcon(sourceTab);

    // Get meal type label
    final String mealTypeLabel = sourceTab == 'breakfast'
        ? 'Breakfast'
        : sourceTab == 'express'
            ? 'Express'
            : 'Lunch';

    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Meal Details',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Image with Recommended badge
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        meal['image'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: Icon(
                              mealIcon,
                              size: 60,
                              color: mealTypeColor.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Meal type label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: mealTypeColor.withOpacity(0.8),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mealIcon,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mealTypeLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Show "Most Recommended" badge for specific meals
                  if ((sourceTab == 'breakfast' &&
                          meal['name'] == 'Breakfast of the Day') ||
                      (sourceTab == 'lunch' &&
                          meal['name'] == 'Lunch of the Day'))
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.purple, AppTheme.deepPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recommended',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Meal Name + Veg Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const VegIcon(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meal['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: mealTypeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '₹${meal['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mealTypeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),

              const SizedBox(height: 12),

              // Price and Save info

              if (sourceTab != 'express')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            'Save 20% on Annual - 200 days',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Masked by gradient
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Description Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mealBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mealTypeColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      mealIcon,
                      color: mealTypeColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getDescription(meal['name']),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reviews Section Header
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Parent Reviews",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "4.5",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(${reviews.length})",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Horizontally scrollable reviews with enhanced card design
              SizedBox(
                height: 150,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final review = reviews[index];
                    final Color cardColor = index % 2 == 0
                        ? AppTheme.purple.withOpacity(0.06)
                        : Colors.green.withOpacity(0.06);
                    final Color iconColor =
                        index % 2 == 0 ? AppTheme.purple : Colors.green;

                    return Container(
                      width: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        color: cardColor,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: iconColor.withOpacity(0.2),
                                          blurRadius: 4,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: cardColor,
                                      child: Text(
                                        review.name.substring(0, 1),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      review.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textDark,
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
                                    i < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: i < review.rating
                                        ? AppTheme.orange
                                        : Colors.grey.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  review.comment,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textMedium,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Choose Plan Button - exactly matching meal plan page
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Create a dummy meal to pass to the subscription screen
                      final mealCategory = sourceTab == 'breakfast'
                          ? MealCategory.breakfast
                          : sourceTab == 'express'
                              ? MealCategory.expressOneDay
                              : MealCategory.lunch;

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
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      isExpressTab ? 'Order Express' : 'Choose Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
