import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/screens/subscription_selection_screen.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/widgets/common/veg_icon.dart';
import 'package:startwell/utils/routes.dart';

class MealPlanScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final String? initialTab;

  const MealPlanScreen({super.key, this.userProfile, this.initialTab});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  // Simple list of test meals for each category
  final List<Map<String, dynamic>> _breakfastMeals = [
    {
      'name': 'Breakfast of the Day',
      'price': 75,
      'isVeg': true,
      'isRecommended': true,
      'image':
          'assets/images/breakfast/breakfast of the day (most recommended).png',
      'isSelected': false,
    },
    {
      'name': 'Indian Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/Indian Breakfast.png',
      'isSelected': false,
    },
    {
      'name': 'International Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/International Breakfast.png',
      'isSelected': false,
    },
    {
      'name': 'Jain Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/Jain Breakfast.png',
      'isSelected': false,
    },
  ];

  final List<Map<String, dynamic>> _lunchMeals = [
    {
      'name': 'Lunch of the Day',
      'price': 125,
      'isVeg': true,
      'isRecommended': true,
      'image': 'assets/images/lunch/lunch of the day (most recommended).png',
      'isSelected': false,
    },
    {
      'name': 'Indian Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/Indian Lunch.png',
      'isSelected': false,
    },
    {
      'name': 'International Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/International Lunch.png',
      'isSelected': false,
    },
    {
      'name': 'Jain Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/Jain Lunch.png',
      'isSelected': false,
    },
  ];

  // Check if breakfast tab should be disabled
  bool get isBreakfastDisabled => MealSelectionManager.hasBreakfastInCart;

  // Check if lunch tab should be disabled
  bool get isLunchDisabled => MealSelectionManager.hasLunchInCart;

  // Toggle meal selection
  void _toggleMealSelection(String mealType, int index) {
    setState(() {
      if (mealType == 'breakfast') {
        // Check if this meal is already selected
        bool isCurrentlySelected = _breakfastMeals[index]['isSelected'] as bool;

        // If it's currently selected, unselect it
        if (isCurrentlySelected) {
          _breakfastMeals[index]['isSelected'] = false;
        } else {
          // Otherwise, select this meal and deselect all others
          for (int i = 0; i < _breakfastMeals.length; i++) {
            _breakfastMeals[i]['isSelected'] = (i == index);
          }
        }
      } else {
        // Check if this meal is already selected
        bool isCurrentlySelected = _lunchMeals[index]['isSelected'] as bool;

        // If it's currently selected, unselect it
        if (isCurrentlySelected) {
          _lunchMeals[index]['isSelected'] = false;
        } else {
          // Otherwise, select this meal and deselect all others
          for (int i = 0; i < _lunchMeals.length; i++) {
            _lunchMeals[i]['isSelected'] = (i == index);
          }
        }
      }
    });
  }

  // Get selected meal for a meal type
  Map<String, dynamic>? _getSelectedMeal(String mealType) {
    if (mealType == 'breakfast') {
      for (var meal in _breakfastMeals) {
        if (meal['isSelected'] == true) {
          return meal;
        }
      }
    } else {
      for (var meal in _lunchMeals) {
        if (meal['isSelected'] == true) {
          return meal;
        }
      }
    }
    return null;
  }

  // Check if current time is within Express window (12:00 AM to 8:00 AM IST)
  bool isWithinExpressWindow() {
    // Convert to IST time (UTC + 5:30)
    DateTime now = DateTime.now().toUtc().add(
          const Duration(hours: 5, minutes: 30),
        );
    final nowHour = now.hour;
    return nowHour >= 0 && nowHour < 8;
  }

  // Show Express time window message
  void _showExpressTimeMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Express Order Timing',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            'Express 1-Day orders are only available from 12:00 AM to 8:00 AM.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Okay',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if any meals are selected
    final breakfastMeal = _getSelectedMeal('breakfast');
    final lunchMeal = _getSelectedMeal('lunch');
    final bool hasSelection = breakfastMeal != null || lunchMeal != null;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(Routes.main, (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Order Meal',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: AppTheme.purpleToDeepPurple),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(Routes.main, (route) => false),
          ),
          actions: [
            // Cart icon
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  if (MealSelectionManager.hasBreakfastInCart ||
                      MealSelectionManager.hasLunchInCart)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${(MealSelectionManager.hasBreakfastInCart ? 1 : 0) + (MealSelectionManager.hasLunchInCart ? 1 : 0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, Routes.cart);
              },
            ),
            // Profile avatar
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: widget.userProfile != null
                  ? ProfileAvatar(
                      userProfile: widget.userProfile,
                      radius: 18,
                      onAvatarTap: () {
                        Navigator.pushNamed(context, Routes.profileSettings);
                      },
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.account_circle,
                        color: AppTheme.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.profileSettings);
                      },
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    Text(
                      'Choose your meal type',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content area with both breakfast and lunch meals
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Breakfast Section
                            if (!isBreakfastDisabled) ...[
                              _buildSectionHeader(
                                'Breakfast',
                                Colors.pink,
                                Icons.ramen_dining,
                                'Fresh breakfast delivered to your child at school in the morning hours.',
                              ),
                              const SizedBox(height: 16),
                              // Grid view for breakfast meals
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      0.9, // Increased to reduce card height
                                ),
                                itemCount: _breakfastMeals.length,
                                itemBuilder: (context, index) {
                                  final meal = _breakfastMeals[index];
                                  return _buildGridMealCard(
                                    name: meal['name'] as String,
                                    price: meal['price'] as int,
                                    isVeg: meal['isVeg'] as bool,
                                    isRecommended:
                                        meal['isRecommended'] as bool,
                                    imageUrl: meal['image'] as String,
                                    mealType: 'breakfast',
                                    tabColor: Colors.pink,
                                    isSelected: meal['isSelected'] as bool,
                                    index: index,
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                            ] else
                              _buildDisabledSection('Breakfast'),

                            // Lunch Section
                            if (!isLunchDisabled) ...[
                              _buildSectionHeader(
                                'Lunch',
                                Colors.green,
                                Icons.flatware,
                                'Nutritious lunch delivered to your child during school lunch hours.',
                              ),
                              const SizedBox(height: 16),
                              // Grid view for lunch meals
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      0.9, // Increased to reduce card height
                                ),
                                itemCount: _lunchMeals.length,
                                itemBuilder: (context, index) {
                                  final meal = _lunchMeals[index];
                                  return _buildGridMealCard(
                                    name: meal['name'] as String,
                                    price: meal['price'] as int,
                                    isVeg: meal['isVeg'] as bool,
                                    isRecommended:
                                        meal['isRecommended'] as bool,
                                    imageUrl: meal['image'] as String,
                                    mealType: 'lunch',
                                    tabColor: Colors.green,
                                    isSelected: meal['isSelected'] as bool,
                                    index: index,
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                            ] else
                              _buildDisabledSection('Lunch'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Choose Plan button
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 60, // Increased height to match other buttons
                decoration: BoxDecoration(
                  gradient: hasSelection ? AppTheme.purpleToDeepPurple : null,
                  color: hasSelection ? null : Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(30), // Adjusted for new height
                ),
                child: ElevatedButton(
                  onPressed: hasSelection
                      ? () {
                          _navigateToSubscriptionPlanWithSelectedMeals();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Adjusted for new height
                    ),
                  ),
                  child: Text(
                    'Choose Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasSelection ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to subscription plan with selected meals
  void _navigateToSubscriptionPlanWithSelectedMeals() {
    final breakfastMeal = _getSelectedMeal('breakfast');
    final lunchMeal = _getSelectedMeal('lunch');

    // Create list of selected meals
    List<Meal> selectedMeals = [];
    double totalCost = 0.0;
    String mealType = '';

    // Add breakfast meal if selected
    if (breakfastMeal != null) {
      final breakfast = Meal(
        id: 'breakfast',
        name: breakfastMeal['name'] as String,
        description: 'Your selected breakfast meal',
        price: (breakfastMeal['price'] as int).toDouble(),
        type: MealType.veg,
        categories: [MealCategory.breakfast],
        imageUrl: breakfastMeal['image'] as String,
        ingredients: [],
        nutritionalInfo: {},
        allergyInfo: [],
      );
      selectedMeals.add(breakfast);
      totalCost += breakfast.price;
      mealType = 'breakfast';
    }

    // Add lunch meal if selected
    if (lunchMeal != null) {
      final lunch = Meal(
        id: 'lunch',
        name: lunchMeal['name'] as String,
        description: 'Your selected lunch meal',
        price: (lunchMeal['price'] as int).toDouble(),
        type: MealType.veg,
        categories: [MealCategory.lunch],
        imageUrl: lunchMeal['image'] as String,
        ingredients: [],
        nutritionalInfo: {},
        allergyInfo: [],
      );
      selectedMeals.add(lunch);
      totalCost += lunch.price;
      mealType = mealType.isEmpty ? 'lunch' : 'breakfast_and_lunch';
    }

    // Create an empty selection manager
    final selectionManager = MealSelectionManager();

    // Navigate to subscription selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionSelectionScreen(
          selectionManager: selectionManager,
          selectedMeals: selectedMeals,
          totalMealCost: totalCost,
          mealType: mealType,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color color,
    IconData icon,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with icon
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Description
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledSection(String mealType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            mealType == 'Breakfast'
                ? Icons.ramen_dining
                : Icons.flatware_rounded,
            color: Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mealType is already in your cart',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Go to your cart to remove it if you want to select a different $mealType.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate color for price badge and buttons
  Color _getTabColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.pink;
      case 'lunch':
        return Colors.green;
      default:
        return AppTheme.purple;
    }
  }

  // New grid-optimized meal card for Order Meal page
  Widget _buildGridMealCard({
    required String name,
    required int price,
    int? basePrice,
    required bool isVeg,
    required bool isRecommended,
    required String imageUrl,
    required String mealType,
    required Color tabColor,
    bool isExpressTab = false,
    required bool isSelected,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? tabColor : Colors.grey.shade200),
        color: isSelected ? tabColor.withOpacity(0.05) : Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _toggleMealSelection(mealType, index);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with checkbox and recommended badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Checkbox for selection
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          _toggleMealSelection(mealType, index);
                        },
                        activeColor: tabColor,
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return tabColor;
                            }
                            return Colors
                                .white; // White background when unchecked
                          },
                        ),
                        side: MaterialStateBorderSide.resolveWith(
                          (states) => const BorderSide(
                            color: Colors.grey, // Grey border
                            width: 1.5,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Recommended badge - HIDDEN
                    // if (isRecommended)
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    //     decoration: BoxDecoration(
                    //       color: Colors.orange,
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: Text(
                    //       'Recommended',
                    //       style: GoogleFonts.poppins(
                    //         fontSize: 10,
                    //         fontWeight: FontWeight.w500,
                    //         color: Colors.white,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),

                const SizedBox(height: 8),

                // Meal image
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          child: Image.asset(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  mealType == 'breakfast'
                                      ? Icons.ramen_dining
                                      : Icons.flatware,
                                  size: 30,
                                  color: tabColor.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Veg icon and meal name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Veg icon
                    const VegIcon(),
                    const SizedBox(width: 6),
                    // Meal name
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToExpressOrder(int price, String mealName, String imageUrl) {
    if (isWithinExpressWindow()) {
      // Create a meal with proper name and image for the express order
      final dummyMeal = Meal(
        id: 'dummy_express',
        name: mealName,
        description: 'Your express meal for same-day delivery',
        price: price.toDouble(),
        type: MealType.veg,
        categories: [MealCategory.expressOneDay],
        imageUrl: imageUrl,
        ingredients: [],
        nutritionalInfo: {},
        allergyInfo: [],
      );

      // Navigate to Single Day plan in subscription screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionSelectionScreen(
            selectionManager: MealSelectionManager(),
            selectedMeals: [dummyMeal],
            totalMealCost: price.toDouble(),
            initialPlanIndex: 0, // Single Day plan (index 0)
            isExpressOrder: true,
            mealType: 'express 1 day lunch',
          ),
        ),
      );
    } else {
      _showExpressTimeMessage(context);
    }
  }
}
