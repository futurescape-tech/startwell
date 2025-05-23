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
  final String? initialTab;

  const MealPlanScreen({super.key, this.userProfile, this.initialTab});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Debug print to check initialTab
    print('DEBUG: MealPlanScreen initialTab=${widget.initialTab}');

    // Initialize tab controller with 2 tabs and correct initial index
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'lunch'
          ? 1
          : 0, // Set initial index based on initialTab
    );

    // Add listener to rebuild when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  // Check if breakfast tab should be disabled
  bool get isBreakfastDisabled => MealSelectionManager.hasBreakfastInCart;

  // Check if lunch tab should be disabled
  bool get isLunchDisabled => MealSelectionManager.hasLunchInCart;

  // Show message when disabled tab is tapped
  void _showDisabledTabMessage(BuildContext context, String mealType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$mealType is already in your cart. Remove it from cart to select a different $mealType.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
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
    // Debug the current tab controller index
    print('DEBUG: Current tab index: ${_tabController.index}');
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
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.purple.shade50),
                ),
                child: TabBar(
                  controller: _tabController,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    return states.contains(MaterialState.focused)
                        ? null
                        : Colors.transparent;
                  }),
                  onTap: (index) {
                    // Check if tab is disabled (in cart)
                    if ((index == 0 && isBreakfastDisabled) ||
                        (index == 1 && isLunchDisabled)) {
                      // Show message and prevent tab change
                      _showDisabledTabMessage(
                        context,
                        index == 0 ? 'Breakfast' : 'Lunch',
                      );
                      // Keep current tab selected
                      _tabController.animateTo(_tabController.index);
                    }
                  },
                  indicator: BoxDecoration(
                    color: _getSelectedTabColor(
                      _tabController.index,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: _getSelectedTabColor(_tabController.index),
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
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.ramen_dining,
                            size: 16,
                            color: isBreakfastDisabled
                                ? Colors.grey.withOpacity(0.5)
                                : null,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Breakfast',
                            style: TextStyle(
                              color: isBreakfastDisabled
                                  ? Colors.grey.withOpacity(0.5)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flatware,
                            size: 16,
                            color: isLunchDisabled
                                ? Colors.grey.withOpacity(0.5)
                                : null,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Lunch',
                            style: TextStyle(
                              color: isLunchDisabled
                                  ? Colors.grey.withOpacity(0.5)
                                  : null,
                            ),
                          ),
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
                  controller: _tabController,
                  children: [
                    isBreakfastDisabled
                        ? _buildDisabledTabContent('Breakfast')
                        : _buildBreakfastTab(),
                    isLunchDisabled
                        ? _buildDisabledTabContent('Lunch')
                        : _buildLunchTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                Icon(Icons.ramen_dining, color: Colors.pink, size: 24),
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
                Icon(Icons.flatware, color: Colors.green, size: 24),
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
    final String mealTypeLabel =
        mealType == 'breakfast' ? 'Breakfast' : 'Lunch';

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
            // Temporarily commented out to hide meal details page
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => MealDetailPage(
            //       meal: mealData,
            //       sourceTab: mealType,
            //       isExpressTab: isExpressTab,
            //     ),
            //   ),
            // );
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
                                : Icons.flatware,
                            size: 60,
                            color: tabColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),

                  // Selected meal badge
                  if (shouldShowRecommendedTag)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                            horizontal: 16,
                            vertical: 8,
                          ),
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

                    const SizedBox(height: 0),

                    // Price and meal info row
                    Row(
                        // children: [
                        //   Icon(
                        //     isVeg ? Icons.restaurant_menu : Icons.food_bank,
                        //     color: Colors.green,
                        //     size: 20,
                        //   ),
                        // const SizedBox(width: 8),
                        // Expanded(
                        //   child: Text(
                        //     mealDescription,
                        //     style: GoogleFonts.poppins(
                        //       fontSize: 16,
                        //       color: Colors.grey.shade700,
                        //     ),
                        //   ),// ),
                        // Price with tab color
                        // ],
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
                                  colors: [
                                    Colors.purple,
                                    Colors.deepOrange,
                                  ],
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
                    const SizedBox(height: 0),

                    // Choose plan button - for all cards
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.purpleToDeepPurple,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Create a meal with proper name and image
                              final mealCategory = mealType == 'breakfast'
                                  ? MealCategory.breakfast
                                  : MealCategory.lunch;
                              final dummyMeal = Meal(
                                id: 'dummy',
                                name: name,
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
                                  builder: (context) =>
                                      SubscriptionSelectionScreen(
                                    selectionManager: selectionManager,
                                    selectedMeals: [dummyMeal],
                                    totalMealCost: price.toDouble(),
                                    mealType: mealType,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              'Choose Plan',
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
    // Express order functionality is temporarily disabled
    if (isExpressTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Express orders are temporarily unavailable.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _navigateToSubscriptionPlan(price, mealType, name, imageUrl);
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

  Widget _buildDisabledTabContent(String mealType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mealType == 'Breakfast'
                ? Icons.ramen_dining
                : Icons.flatware_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            '$mealType is already in your cart',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Go to your cart to remove it if you want to select a different $mealType.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.purpleToDeepPurple,
                borderRadius: BorderRadius.circular(50),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.cart);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Go to Cart',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
