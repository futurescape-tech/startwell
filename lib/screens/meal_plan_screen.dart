import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/screens/subscription_selection_screen.dart';
import 'package:startwell/services/meal_data_service.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/screens/meal_detail_page.dart';
import 'package:startwell/widgets/common/veg_icon.dart';
import 'package:startwell/utils/routes.dart';

class MealPlanScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const MealPlanScreen({super.key, this.userProfile});

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
              Icon(
                Icons.access_time_rounded,
                color: Colors.orange,
                size: 24,
              ),
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
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);

          // Add listener to rebuild when tab changes
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              setState(() {});
            }
          });

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Meal Plans',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleToDeepPurple,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: widget.userProfile != null
                      ? ProfileAvatar(
                          userProfile: widget.userProfile,
                          radius: 18,
                          onAvatarTap: () {
                            Navigator.pushNamed(
                                context, Routes.profileSettings);
                          },
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.account_circle,
                            color: AppTheme.white,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                                context, Routes.profileSettings);
                          },
                        ),
                ),
              ],
            ),
            body: Padding(
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

                  // Custom segmented control
                  Container(
                    decoration: BoxDecoration(
                      // color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.purple.shade50),
                    ),
                    child: TabBar(
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        // Use the default focused overlay color
                        return states.contains(MaterialState.focused)
                            ? null
                            : Colors.transparent;
                      }),
                      indicator: BoxDecoration(
                        color: _getSelectedTabColor(tabController.index)
                            .withOpacity(0.1),
                        //color: Colors.gre.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black.withOpacity(0.1),
                        //     blurRadius: 4,
                        //     offset: const Offset(0, 2),
                        //   ),
                        // ],
                      ),
                      labelColor: _getSelectedTabColor(tabController.index),
                      unselectedLabelColor: AppTheme.textMedium,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ramen_dining, size: 16),
                              SizedBox(width: 6),
                              Text('Breakfast'),
                            ],
                          ),
                        ),
                        Tab(
                          icon: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lunch_dining, size: 16),
                              SizedBox(width: 6),
                              Text('Lunch'),
                            ],
                          ),
                        ),
                        Tab(
                          icon: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delivery_dining, size: 16),
                              SizedBox(width: 6),
                              Text('Express'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Meal description card
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBreakfastTab(),
                        _buildLunchTab(),
                        _buildExpressTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to get tab color based on index
  Color _getSelectedTabColor(int index) {
    switch (index) {
      case 0:
        return Colors.pink; // Breakfast
      case 1:
        return Colors.green; // Lunch
      case 2:
        return Colors.orange; // Express
      default:
        return AppTheme.purple;
    }
  }

  // Get appropriate color for price badge and buttons
  Color _getTabColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.pink;
      case 'lunch':
        return Colors.green;
      case 'express':
        return Colors.blue;
      default:
        return AppTheme.purple;
    }
  }

  Widget _buildBreakfastTab() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.ramen_dining,
                  color: Colors.pink,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nutritious breakfast delivered to your child before school starts.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal Selection Cards
          for (var meal in breakfastMeals)
            _buildMealSelectionCard(
              name: meal['name'] as String,
              price: meal['price'] as int,
              isVeg: meal['isVeg'] as bool,
              isRecommended: meal['isRecommended'] as bool,
              imageUrl: meal['image'] as String,
              mealType: 'breakfast',
              tabColor: Colors.pink,
            ),
        ],
      ),
    );
  }

  Widget _buildLunchTab() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lunch_dining,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nutritious lunch delivered to your child during school lunch hours.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal Selection Cards
          for (var meal in lunchMeals)
            _buildMealSelectionCard(
              name: meal['name'] as String,
              price: meal['price'] as int,
              isVeg: meal['isVeg'] as bool,
              isRecommended: meal['isRecommended'] as bool,
              imageUrl: meal['image'] as String,
              mealType: 'lunch',
              tabColor: Colors.green,
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Express availability info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Same-day delivery with express fee',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeWindowStatus. Orders can only be placed between 12:00 AM to 8:00 AM (IST).',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Express Meal Selection Cards
          for (var meal in expressMeals)
            _buildMealSelectionCard(
              name: meal['name'] as String,
              price: (meal['price'] as int) + 50, // Adding express fee
              basePrice: meal['price'] as int,
              isVeg: meal['isVeg'] as bool,
              isRecommended: meal['isRecommended'] as bool,
              imageUrl: meal['image'] as String,
              mealType: 'express',
              isExpressTab: true,
              tabColor: Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildMealSelectionCard({
    required String name,
    required int price,
    int? basePrice,
    required bool isVeg,
    required bool isRecommended,
    required String imageUrl,
    required String mealType,
    required Color tabColor,
    bool isExpressTab = false,
  }) {
    // Check if it's the most recommended meal to highlight it
    final bool shouldShowRecommendedTag = _shouldShowMostRecommendedTag(
      mealType,
      name,
    );

    // Create meal data map for detail page and selection
    final mealData = {
      'name': name,
      'price': price,
      'isVeg': isVeg,
      'isRecommended': isRecommended,
      'image': imageUrl,
    };

    // For Express tab, check if we're within the ordering window
    final bool expressOrderEnabled = !isExpressTab || isWithinExpressWindow();

    // Get appropriate meal type label
    final String mealTypeLabel = mealType == 'breakfast'
        ? 'Breakfast'
        : mealType == 'express'
            ? 'Express'
            : 'Lunch';

    // Get appropriate meal description
    final String mealDescription =
        mealType == 'breakfast' ? 'Breakfast Meal' : 'Lunch Meal';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
            // Prevent navigation to meal detail for Express tab outside ordering hours
            if (isExpressTab && !expressOrderEnabled) {
              _showExpressTimeMessage(context);
              return;
            }

            // Navigate to meal detail page
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
              // Meal image with tag
              Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.asset(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(
                            mealType == 'breakfast'
                                ? Icons.ramen_dining
                                : mealType == 'express'
                                    ? Icons.delivery_dining
                                    : Icons.lunch_dining,
                            size: 60,
                            color: tabColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),

                  // Meal type label
                  // Positioned(
                  //   bottom: 0,
                  //   left: 0,
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 12, vertical: 6),
                  //     decoration: BoxDecoration(
                  //       color: tabColor.withOpacity(0.8),
                  //       borderRadius: const BorderRadius.only(
                  //         topRight: Radius.circular(12),
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(
                  //           mealType == 'breakfast'
                  //               ? Icons.ramen_dining
                  //               : mealType == 'express'
                  //                   ? Icons.delivery_dining
                  //                   : Icons.lunch_dining,
                  //           color: Colors.white,
                  //           size: 16,
                  //         ),
                  //         const SizedBox(width: 6),
                  //         Text(
                  //           mealTypeLabel,
                  //           style: GoogleFonts.poppins(
                  //             color: Colors.white,
                  //             fontSize: 14,
                  //             fontWeight: FontWeight.w500,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  // Selected meal badge
                  if (shouldShowRecommendedTag)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.orange, Colors.purple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
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
                              'Top Pick',
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

              // Meal details section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal name row with veg icon
                    Row(
                      children: [
                        // Veg icon instead of checkbox
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            // shape: BoxShape.circle,
                          ),
                          child: const VegIcon(),
                        ),
                        const SizedBox(width: 12),

                        // Meal name
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '₹$price',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price and meal info row
                    Row(
                      children: [
                        Icon(
                          isVeg ? Icons.restaurant_menu : Icons.food_bank,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mealDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        // Price with tab color
                      ],
                    ),

                    // Express fee info (only for Express tab)
                    if (isExpressTab && basePrice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 28), // Align with text above
                            Text(
                              'Includes ₹50 express fee',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Annual offer section - for all tabs except Express
                    if (!isExpressTab)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.deepOrange.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.savings_rounded,
                                color: Colors.purple,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [Colors.purple, Colors.deepOrange],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds),
                                child: Text(
                                  'Save 20% on Annual - 200 days',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // This will be masked by the gradient
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Add some space before the button
                    const SizedBox(height: 16),

                    // Choose plan button - for all cards
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.purpleToDeepPurple,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade400.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isExpressTab
                                ? (expressOrderEnabled
                                    ? () => _handleChoosePlanTap(
                                          name,
                                          price,
                                          imageUrl,
                                          mealType,
                                          true,
                                        )
                                    : () => _showExpressTimeMessage(context))
                                : () => _handleChoosePlanTap(
                                      name,
                                      price,
                                      imageUrl,
                                      mealType,
                                      false,
                                    ),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChoosePlanTap(
    String name,
    int price,
    String imageUrl,
    String mealType,
    bool isExpressTab,
  ) {
    if (isExpressTab) {
      _navigateToExpressOrder(price, name, imageUrl);
    } else {
      _navigateToSubscriptionPlan(price, mealType, name, imageUrl);
    }
  }

  void _navigateToSubscriptionPlan(
    int price,
    String mealType,
    String mealName,
    String imageUrl,
  ) {
    // Create a meal with proper name and image to pass to the subscription screen
    final mealCategory =
        mealType == 'breakfast' ? MealCategory.breakfast : MealCategory.lunch;

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
}
