import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/screens/subscription_selection_screen.dart';
import 'package:startwell/services/meal_data_service.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:startwell/screens/meal_detail_page.dart';
import 'package:startwell/widgets/common/veg_icon.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

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
    },
    {
      'name': 'Indian Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/Indian Breakfast.png',
    },
    {
      'name': 'International Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/International Breakfast.png',
    },
    {
      'name': 'Jain Breakfast',
      'price': 75,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/breakfast/jain breakfast.png',
    },
  ];

  final List<Map<String, dynamic>> _lunchMeals = [
    {
      'name': 'Lunch of the Day',
      'price': 125,
      'isVeg': true,
      'isRecommended': true,
      'image': 'assets/images/lunch/lunch of the day (most recommended).png',
    },
    {
      'name': 'Indian Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/Indian Lunch.png',
    },
    {
      'name': 'International Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/International Lunch.png',
    },
    {
      'name': 'Jain Lunch',
      'price': 125,
      'isVeg': true,
      'isRecommended': false,
      'image': 'assets/images/lunch/Jain Lunch.png',
    },
  ];

  // Check if current time is within Express window (12:00 AM to 8:00 AM IST)
  bool isWithinExpressWindow() {
    // Convert to IST time (UTC + 5:30)
    DateTime now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowHour = now.hour;
    return nowHour >= 0 && nowHour < 8;
  }

  // Show Express time window message
  void _showExpressTimeMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Express 1 Day orders are only available from 12:00 AM to 8:00 AM.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Meal Plans',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.purple,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: AppTheme.purple,
              child: TabBar(
                labelColor: AppTheme.textDark,
                unselectedLabelColor: Colors.white.withOpacity(0.8),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Breakfast'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Lunch'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Express 1-Day'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: MediaQuery.of(context).size.width > 900
            ? Center(
                child: SizedBox(
                  width: 900, // Max content width for larger screens
                  child: TabBarView(
                    children: [
                      _buildBreakfastTab(),
                      _buildLunchTab(),
                      _buildExpressTab(),
                    ],
                  ),
                ),
              )
            : TabBarView(
                children: [
                  _buildBreakfastTab(),
                  _buildLunchTab(),
                  _buildExpressTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildBreakfastTab() {
    // Static breakfast meals list
    final breakfastMeals = [
      {
        'name': 'Breakfast of the Day',
        'price': 75,
        'isVeg': true,
        'isRecommended': true,
        'image':
            'assets/images/breakfast/breakfast of the day (most recommended).png',
      },
      {
        'name': 'Indian Breakfast',
        'price': 75,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/breakfast/Indian Breakfast.png',
      },
      {
        'name': 'International Breakfast',
        'price': 75,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/breakfast/International Breakfast.png',
      },
      {
        'name': 'Jain Breakfast',
        'price': 75,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/breakfast/Jain Breakfast.png',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Info about breakfast timing
          InfoBanner(
            title: "Breakfast ",
            message:
                "Good mornings Wake up to warm, fresh breakfast on school days",
            type: InfoBannerType.info,
          ),
          const SizedBox(height: 16),

          // Breakfast meal cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breakfastMeals.length,
            itemBuilder: (context, index) {
              final meal = breakfastMeals[index];
              return _buildMealCard(
                name: meal['name'] as String,
                price: meal['price'] as int,
                isVeg: meal['isVeg'] as bool,
                isRecommended: meal['isRecommended'] as bool,
                imageUrl: meal['image'] as String,
                isExpressTab: false,
                mealType: 'breakfast',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLunchTab() {
    // Static lunch meals list
    final lunchMeals = [
      {
        'name': 'Lunch of the Day',
        'price': 125,
        'isVeg': true,
        'isRecommended': true,
        'image': 'assets/images/lunch/lunch of the day (most recommended).png',
      },
      {
        'name': 'Indian Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/Indian Lunch.png',
      },
      {
        'name': 'International Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/International Lunch.png',
      },
      {
        'name': 'Jain Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/Jain Lunch.png',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Info about lunch timing
          InfoBanner(
            title: "Lunch",
            message:
                "Fuel your afternoon with fresh lunches on all school days",
            type: InfoBannerType.info,
          ),
          const SizedBox(height: 16),

          // Lunch meal cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lunchMeals.length,
            itemBuilder: (context, index) {
              final meal = lunchMeals[index];
              return _buildMealCard(
                name: meal['name'] as String,
                price: meal['price'] as int,
                isVeg: meal['isVeg'] as bool,
                isRecommended: meal['isRecommended'] as bool,
                imageUrl: meal['image'] as String,
                isExpressTab: false,
                mealType: 'lunch',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpressTab() {
    final bool isExpressAvailable = isWithinExpressWindow();
    final String timeWindowStatus = isExpressAvailable
        ? "Express ordering is currently OPEN"
        : "Express ordering is currently CLOSED";

    // Create express meals list with static images
    final List<Map<String, dynamic>> expressMeals = [
      {
        'name': 'Lunch of the Day',
        'price': 125,
        'isVeg': true,
        'isRecommended': true,
        'image': 'assets/images/lunch/lunch of the day (most recommended).png',
      },
      {
        'name': 'Indian Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/Indian Lunch.png',
      },
      {
        'name': 'International Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/International Lunch.png',
      },
      {
        'name': 'Jain Lunch',
        'price': 125,
        'isVeg': true,
        'isRecommended': false,
        'image': 'assets/images/lunch/Jain Lunch.png',
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate content padding based on screen width
      final double horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;

      return SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Express 1 Day Delivery',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              InfoBanner(
                title: isExpressAvailable
                    ? "Express Ordering Open"
                    : "Express Ordering Closed",
                message:
                    "This meal includes a ₹50 express fee for same-day delivery only. $timeWindowStatus. Orders can only be placed between 12:00 AM to 8:00 AM (IST).",
                type: isExpressAvailable
                    ? InfoBannerType.success
                    : InfoBannerType.warning,
              ),
              const SizedBox(height: 16),

              // Express meal cards
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expressMeals.length,
                itemBuilder: (context, index) {
                  final meal = expressMeals[index];
                  // Adding express fee to base price
                  final expressPrice = meal['price'] + 50;
                  return _buildMealCard(
                    name: meal['name'] as String,
                    price: expressPrice,
                    basePrice: meal['price'] as int,
                    isVeg: true, // Force Veg icon for Express tab
                    isRecommended: meal['isRecommended'] as bool,
                    imageUrl: meal['image'] as String,
                    isExpressTab: true,
                    mealType: 'express 1 day lunch',
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMealCard({
    required String name,
    required int price,
    int? basePrice,
    required bool isVeg,
    required bool isRecommended,
    required String imageUrl,
    required bool isExpressTab,
    required String mealType,
  }) {
    // For Express tab, check if we're within the ordering window
    final bool expressOrderEnabled = !isExpressTab || isWithinExpressWindow();

    // Determine if we should show veg icon - always true for Breakfast and Lunch tabs
    final bool showVegIcon = isExpressTab ? isVeg : true;

    // Determine if meal should show the "Most Recommended" tag based on tab and name
    final bool shouldShowRecommendedTag =
        _shouldShowMostRecommendedTag(mealType, name);

    // Create meal data map for detail page
    final mealData = {
      'name': name,
      'price': price,
      'isVeg': isVeg,
      'isRecommended': isRecommended,
      'image': imageUrl,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Prevent navigation to meal detail for Express tab outside ordering hours
          if (isExpressTab && !expressOrderEnabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Express orders are currently closed. Please check back during ordering hours.',
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          // Allow navigation for non-Express tabs or during express ordering hours
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailPage(
                meal: mealData,
                sourceTab: mealType,
                isExpressTab: isExpressTab,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal image with Most Recommended tag overlay
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Image.asset(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isExpressTab
                                  ? (isVeg ? Icons.stop : Icons.restaurant)
                                  : Icons.stop,
                              size: 40,
                              color: isExpressTab
                                  ? (isVeg ? Colors.green : Colors.brown)
                                  : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
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

                // Most Recommended tag with gradient background and animation
                if (shouldShowRecommendedTag)
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

                // Express time window badge (only for Express tab outside window)
                if (isExpressTab && !expressOrderEnabled)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      child: Text(
                        'Available 12:00 AM - 8:00 AM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Meal info section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal name with Veg icon
                  Row(
                    children: [
                      const VegIcon(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price display with responsive layout
                  LayoutBuilder(builder: (context, constraints) {
                    // Adjust layout based on available width
                    final bool useCompactLayout = constraints.maxWidth < 300;

                    if (isExpressTab && basePrice != null) {
                      return useCompactLayout
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '₹$basePrice',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹$price per meal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.purple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(+₹50 express fee)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  '₹$basePrice',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹$price per meal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.purple,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(+₹50 express fee)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            );
                    } else {
                      return Text(
                        '₹$price per meal',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.purple,
                        ),
                      );
                    }
                  }),

                  const SizedBox(height: 8),

                  // Discount info - only for Breakfast and Lunch tabs
                  if (!isExpressTab)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Express fee info - only for Express tab
                  if (isExpressTab)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Express Fee: ₹50 for same-day delivery',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Choose plan button with responsive width
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        isExpressTab ? 'Order Express' : 'Choose Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: isExpressTab
                          ? (expressOrderEnabled
                              ? () => _handleChoosePlanTap(
                                  name, price, imageUrl, mealType, true)
                              : () => _showExpressTimeMessage(context))
                          : () => _handleChoosePlanTap(
                              name, price, imageUrl, mealType, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: expressOrderEnabled
                            ? isExpressTab
                                ? Colors.orange
                                : AppTheme.purple
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
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

  void _navigateToSubscriptionPlan(
      int price, String mealType, String mealName, String imageUrl) {
    // Create a meal with proper name and image to pass to the subscription screen
    final mealCategory = mealType == 'breakfast'
        ? MealCategory.breakfast
        : mealType == 'express 1 day lunch'
            ? MealCategory.expressOneDay
            : MealCategory.lunch;

    final dummyMeal = Meal(
      id: 'dummy',
      name: mealName,
      description: 'Your selected meal',
      price: price.toDouble(),
      type: MealType.veg,
      categories: [mealCategory],
      imageUrl: imageUrl,
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
          totalMealCost: price.toDouble(),
          mealType: mealType,
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

  bool _shouldShowMostRecommendedTag(String mealType, String name) {
    final String lowerName = name.toLowerCase();

    // For breakfast tab - show tag on "Breakfast of the Day"
    if (mealType == 'breakfast' && lowerName == 'breakfast of the day') {
      return true;
    }

    // For lunch tab - show tag on "Lunch of the Day"
    if (mealType == 'lunch' && lowerName == 'lunch of the day') {
      return true;
    }

    // For express tab - show tag on "Lunch of the Day"
    if (mealType == 'express 1 day lunch' && lowerName == 'lunch of the day') {
      return true;
    }

    // Default case - don't show tag
    return false;
  }

  // Handle "Choose Plan" button tap
  void _handleChoosePlanTap(String name, int price, String imageUrl,
      String mealType, bool isExpressTab) {
    if (isExpressTab) {
      _navigateToExpressOrder(price, name, imageUrl);
    } else {
      _navigateToSubscriptionPlan(price, mealType, name, imageUrl);
    }
  }
}
