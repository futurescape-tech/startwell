import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/subscription_plan_model.dart';
import 'package:startwell/screens/manage_student_profile_screen.dart';
import 'package:startwell/services/cart_storage_service.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/services/subscription_plan_service.dart';
import 'package:startwell/services/subscription_plan_storage_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/veg_icon.dart';

class CartScreen extends StatefulWidget {
  final String planType;
  final bool isCustomPlan;
  final List<bool> selectedWeekdays;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> mealDates;
  final double totalAmount;
  final List<Meal> selectedMeals;
  final bool isExpressOrder;
  final String mealType;

  const CartScreen({
    Key? key,
    required this.planType,
    required this.isCustomPlan,
    required this.selectedWeekdays,
    required this.startDate,
    required this.endDate,
    required this.mealDates,
    required this.totalAmount,
    required this.selectedMeals,
    required this.isExpressOrder,
    required this.mealType,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // List to store cart items - currently just the selected meal and plan
  // In the future, this could be expanded to support multiple items
  List<Map<String, dynamic>> _cartItems = [];

  // Track meal types in cart
  bool _hasBreakfastInCart = false;
  bool _hasLunchInCart = false;

  // Subscription plan to display
  SubscriptionPlanModel? _subscriptionPlan;

  @override
  void initState() {
    super.initState();
    // Load saved cart items first
    _loadCartItems().then((_) {
      // Add the current selection to cart if it's not empty
      if (widget.selectedMeals.isNotEmpty) {
        _addToCart();
      }
      // Check meal types in cart
      _checkMealTypesInCart();
      // Load subscription plan
      _loadSubscriptionPlan();
    });
  }

  // Load saved subscription plan
  Future<void> _loadSubscriptionPlan() async {
    final plan = await SubscriptionPlanService.getSubscriptionPlan();
    setState(() {
      _subscriptionPlan = plan;
    });
  }

  // Load saved cart items from shared preferences
  Future<void> _loadCartItems() async {
    try {
      final savedCartItems = await CartStorageService.loadCartItems();
      if (savedCartItems.isNotEmpty) {
        setState(() {
          _cartItems = savedCartItems;
        });
      }
    } catch (e) {
      // Handle errors loading cart items
      print('Error loading cart items: $e');
    }
  }

  // Save cart items to shared preferences
  Future<void> _saveCartItems() async {
    try {
      await CartStorageService.saveCartItems(_cartItems);
    } catch (e) {
      // Handle errors saving cart items
      print('Error saving cart items: $e');
    }
  }

  void _checkMealTypesInCart() {
    setState(() {
      _hasBreakfastInCart = _cartItems.any((item) =>
          item['mealType'] == 'breakfast' || item['mealType'] == 'both');
      _hasLunchInCart = _cartItems.any(
          (item) => item['mealType'] == 'lunch' || item['mealType'] == 'both');

      // Update static variables for cross-screen communication
      MealSelectionManager.hasBreakfastInCart = _hasBreakfastInCart;
      MealSelectionManager.hasLunchInCart = _hasLunchInCart;

      // Log meal types in cart
      print(
          'DEBUG: _checkMealTypesInCart - breakfast in cart: $_hasBreakfastInCart');
      print('DEBUG: _checkMealTypesInCart - lunch in cart: $_hasLunchInCart');
    });
  }

  bool get hasBothMealTypesInCart => _hasBreakfastInCart && _hasLunchInCart;

  void _addToCart() {
    // Skip if selectedMeals is empty (happens when loading from storage)
    if (widget.selectedMeals.isEmpty) {
      return;
    }

    // Create a cart item from the current selection
    final cartItem = {
      'planType': widget.planType,
      'isCustomPlan': widget.isCustomPlan,
      'selectedWeekdays': widget.selectedWeekdays,
      'startDate': widget.startDate,
      'endDate': widget.endDate,
      'mealDates': widget.mealDates,
      'totalAmount': widget.totalAmount,
      'selectedMeals': widget.selectedMeals,
      'isExpressOrder': widget.isExpressOrder,
      'mealType': widget.mealType,
    };

    setState(() {
      // Check if we already have this meal type
      int existingItemIndex = -1;
      for (int i = 0; i < _cartItems.length; i++) {
        if (_cartItems[i]['mealType'] == widget.mealType) {
          existingItemIndex = i;
          break;
        }
      }

      // If we have an existing item, update it; otherwise add a new one
      if (existingItemIndex >= 0) {
        _cartItems[existingItemIndex] = cartItem;
      } else {
        _cartItems.add(cartItem);
      }
    });

    // Save to storage
    _saveCartItems();
  }

  void _removeFromCart(int index) async {
    final removedItem = _cartItems[index];
    final removedMealType = removedItem['mealType'];

    setState(() {
      _cartItems.removeAt(index);
      // After removing an item, recalculate what's in the cart
      _checkMealTypesInCart();

      // Update static variables directly in case we need immediate access
      if (removedMealType == 'breakfast') {
        MealSelectionManager.hasBreakfastInCart = false;
      } else if (removedMealType == 'lunch') {
        MealSelectionManager.hasLunchInCart = false;
      }
    });

    // Save updated cart items or clear if empty
    if (_cartItems.isEmpty) {
      await CartStorageService.clearCartItems();
    } else {
      await _saveCartItems();
    }
  }

  void _proceedToStudentSelection() async {
    if (_cartItems.isEmpty) {
      // Show a message if cart is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your cart is empty. Please add items to continue.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if we have both breakfast and lunch in the cart
    bool hasBreakfastInCart = false;
    bool hasLunchInCart = false;
    Map<String, dynamic>? breakfastItem;
    Map<String, dynamic>? lunchItem;

    // Find both meal types
    for (var item in _cartItems) {
      if (item['mealType'] == 'breakfast') {
        hasBreakfastInCart = true;
        breakfastItem = item;
      } else if (item['mealType'] == 'lunch') {
        hasLunchInCart = true;
        lunchItem = item;
      }
    }

    // Update the MealSelectionManager to reflect current state
    MealSelectionManager.hasBreakfastInCart = hasBreakfastInCart;
    MealSelectionManager.hasLunchInCart = hasLunchInCart;

    // Set common values to pass
    String planType;
    bool isCustomPlan;
    List<bool> selectedWeekdays;
    DateTime startDate;
    DateTime endDate;
    List<DateTime> mealDates = [];
    double totalAmount = 0;
    List<Meal> selectedMeals = [];
    bool isExpressOrder = false;
    String mealType;

    // Additional parameters for keeping breakfast and lunch data separate
    DateTime? breakfastStartDate;
    DateTime? breakfastEndDate;
    List<DateTime>? breakfastMealDates;
    List<Meal>? breakfastMeals;
    double? breakfastAmount;
    String? breakfastPlanType;

    DateTime? lunchStartDate;
    DateTime? lunchEndDate;
    List<DateTime>? lunchMealDates;
    List<Meal>? lunchMeals;
    double? lunchAmount;
    String? lunchPlanType;

    // If we have both breakfast and lunch, we need to keep data separate
    if (hasBreakfastInCart && hasLunchInCart) {
      // Set combined meal type
      mealType = 'both';

      // Use plan type from one of the items (should be the same)
      planType = breakfastItem!['planType'];
      isCustomPlan = breakfastItem!['isCustomPlan'];

      // Store breakfast-specific data
      breakfastStartDate = breakfastItem['startDate'];
      breakfastEndDate = breakfastItem['endDate'];
      breakfastMealDates = breakfastItem['mealDates'] as List<DateTime>;
      breakfastMeals = breakfastItem['selectedMeals'] as List<Meal>;
      breakfastAmount = breakfastItem['totalAmount'];
      breakfastPlanType = breakfastItem['planType'];

      // Store lunch-specific data
      lunchStartDate = lunchItem!['startDate'];
      lunchEndDate = lunchItem['endDate'];
      lunchMealDates = lunchItem['mealDates'] as List<DateTime>;
      lunchMeals = lunchItem['selectedMeals'] as List<Meal>;
      lunchAmount = lunchItem['totalAmount'];
      lunchPlanType = lunchItem['planType'];

      // For the combined display, use outer boundaries
      startDate = breakfastStartDate!.isBefore(lunchStartDate!)
          ? breakfastStartDate!
          : lunchStartDate!;

      endDate = breakfastEndDate!.isAfter(lunchEndDate!)
          ? breakfastEndDate!
          : lunchEndDate!;

      // Combine weekdays if custom plan
      selectedWeekdays = List.generate(
          5,
          (index) =>
              breakfastItem!['selectedWeekdays'][index] ||
              lunchItem!['selectedWeekdays'][index]);

      // Combine meal dates and remove duplicates
      mealDates = [
        ...breakfastItem['mealDates'] as List<DateTime>,
        ...lunchItem['mealDates'] as List<DateTime>
      ].toSet().toList();

      // Total amount is sum of both subscription costs
      totalAmount = breakfastItem['totalAmount'] + lunchItem['totalAmount'];

      // Combine selected meals
      selectedMeals = [
        ...breakfastItem['selectedMeals'],
        ...lunchItem['selectedMeals']
      ];

      // Express order if either is express
      isExpressOrder =
          breakfastItem['isExpressOrder'] || lunchItem['isExpressOrder'];
    } else {
      // Just use the single item (either breakfast or lunch)
      final item = hasBreakfastInCart ? breakfastItem! : lunchItem!;

      planType = item['planType'];
      isCustomPlan = item['isCustomPlan'];
      selectedWeekdays = item['selectedWeekdays'];
      startDate = item['startDate'];
      endDate = item['endDate'];
      mealDates = item['mealDates'];
      totalAmount = item['totalAmount'];
      selectedMeals = item['selectedMeals'];
      isExpressOrder = item['isExpressOrder'];
      mealType = item['mealType'];

      if (hasBreakfastInCart) {
        breakfastStartDate = startDate;
        breakfastEndDate = endDate;
        breakfastMealDates = mealDates;
        breakfastMeals = selectedMeals;
        breakfastAmount = totalAmount;
        breakfastPlanType = planType;
      } else if (hasLunchInCart) {
        lunchStartDate = startDate;
        lunchEndDate = endDate;
        lunchMealDates = mealDates;
        lunchMeals = selectedMeals;
        lunchAmount = totalAmount;
        lunchPlanType = planType;
      }
    }

    // Store the subscription plan details
    final String deliveryMode = isCustomPlan ? 'Custom' : 'Regular';

    print('DEBUG: Proceeding to student selection with:');
    print('DEBUG: planType: $planType');
    print('DEBUG: deliveryMode: $deliveryMode');
    print('DEBUG: mealType: $mealType');
    print('DEBUG: hasBreakfastInCart: $hasBreakfastInCart');
    print('DEBUG: hasLunchInCart: $hasLunchInCart');
    print('DEBUG: total amount: $totalAmount');
    print('DEBUG: meal dates count: ${mealDates.length}');
    print('DEBUG: selected meals count: ${selectedMeals.length}');

    if (hasBreakfastInCart && hasLunchInCart) {
      print('DEBUG: breakfast start date: ${breakfastStartDate!.toString()}');
      print('DEBUG: breakfast end date: ${breakfastEndDate!.toString()}');
      print('DEBUG: lunch start date: ${lunchStartDate!.toString()}');
      print('DEBUG: lunch end date: ${lunchEndDate!.toString()}');
    }

    // Save plan details to storage with all meal information
    await SubscriptionPlanStorageService.savePlanDetails(
      selectedPlanType: planType,
      deliveryMode: deliveryMode,
      mealType: mealType,
      hasBreakfastInCart: hasBreakfastInCart,
      hasLunchInCart: hasLunchInCart,
    );

    // Clear cart items as they are being processed
    await CartStorageService.clearCartItems();

    // Reset static flags after saving them to storage
    MealSelectionManager.hasBreakfastInCart = false;
    MealSelectionManager.hasLunchInCart = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageStudentProfileScreen(
          planType: planType,
          isCustomPlan: isCustomPlan,
          selectedWeekdays: selectedWeekdays,
          startDate: startDate,
          endDate: endDate,
          mealDates: mealDates,
          totalAmount: totalAmount,
          selectedMeals: selectedMeals,
          isExpressOrder: isExpressOrder,
          mealType: mealType, // Pass the correctly determined meal type
          // Pass additional parameters for breakfast and lunch specific data
          breakfastStartDate: breakfastStartDate,
          breakfastEndDate: breakfastEndDate,
          breakfastMealDates: breakfastMealDates,
          breakfastSelectedMeals: breakfastMeals,
          breakfastAmount: breakfastAmount,
          breakfastPlanType: breakfastPlanType,
          lunchStartDate: lunchStartDate,
          lunchEndDate: lunchEndDate,
          lunchMealDates: lunchMealDates,
          lunchSelectedMeals: lunchMeals,
          lunchAmount: lunchAmount,
          lunchPlanType: lunchPlanType,
        ),
      ),
    );
  }

  void _navigateToMealPlan() async {
    // Save cart items before navigating
    await _saveCartItems();

    // Determine which meal type to show based on existing subscriptions
    String initialTab = 'breakfast'; // Default to breakfast tab

    if (_hasBreakfastInCart && !_hasLunchInCart) {
      initialTab = 'lunch'; // If breakfast is in cart, show lunch tab
    } else if (!_hasBreakfastInCart && _hasLunchInCart) {
      initialTab = 'breakfast'; // If lunch is in cart, show breakfast tab
    } else if (!_hasBreakfastInCart && !_hasLunchInCart) {
      initialTab = 'breakfast'; // If cart is empty, show breakfast tab
    }

    // Navigate to meal plan screen with the appropriate initial tab
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.mealPlan,
      (route) => false,
      arguments: {'initialTab': initialTab},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Your Cart',
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: _cartItems.isEmpty
                ? _buildEmptyCartState()
                : _buildCartItemsList(),
          ),
          // Bottom section with proceed button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Buy More button
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed:
                          hasBothMealTypesInCart ? null : _navigateToMealPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.purple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(
                            color: hasBothMealTypesInCart
                                ? Colors.grey.withOpacity(0.5)
                                : AppTheme.purple,
                            width: 1.5,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        disabledBackgroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey,
                      ),
                      child: Text(
                        'Buy More',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Proceed button
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: AppTheme.purpleToDeepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepPurple.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty
                          ? null
                          : _proceedToStudentSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.zero,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white.withOpacity(0.6),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add meals to your cart to continue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.mealPlan,
                (route) => false,
              );
            },
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.purple,
            ),
            label: Text(
              'Return to Meal Selection',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlanSummary() {
    if (_subscriptionPlan == null) {
      return const SizedBox.shrink(); // Nothing to display
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Plan Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildPlanDetailRow('Plan Type:', _subscriptionPlan!.planType),
          _buildPlanDetailRow(
              'Delivery Mode:', _subscriptionPlan!.formattedDeliveryMode),
          _buildPlanDetailRow(
              'Start Date:', _subscriptionPlan!.formattedStartDate),
          _buildPlanDetailRow('End Date:', _subscriptionPlan!.formattedEndDate),
        ],
      ),
    );
  }

  Widget _buildPlanDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // List all cart items (subscription plan summary hidden)
        ..._cartItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return _buildCartItem(item, index);
        }).toList(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final meals = item['selectedMeals'] as List<Meal>;
    final String mealType = item['mealType'];
    final String planType = item['planType'];
    final bool isCustomPlan = item['isCustomPlan'];
    final List<bool> selectedWeekdays = item['selectedWeekdays'];
    final DateTime startDate = item['startDate'];
    final DateTime endDate = item['endDate'];
    final double totalAmount = item['totalAmount'];

    // Get primary meal (first in list)
    final Meal primaryMeal = meals.isNotEmpty
        ? meals.first
        : Meal(
            id: '',
            name: '',
            description: '',
            price: 0,
            type: MealType.veg,
            categories: [],
            imageUrl: '',
            ingredients: [],
            nutritionalInfo: {},
            allergyInfo: [],
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Meal image or placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: _getMealImage(primaryMeal, mealType),
                  ),
                ),
                const SizedBox(width: 16),
                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const VegIcon(),
                          const SizedBox(width: 8),
                          Text(
                            mealType.substring(0, 1).toUpperCase() +
                                mealType.substring(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        primaryMeal.name.isNotEmpty
                            ? primaryMeal.name
                            : '${mealType.substring(0, 1).toUpperCase() + mealType.substring(1)} of the Day',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$planType ${isCustomPlan ? '(Custom)' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  onPressed: () => _removeFromCart(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[200],
          ),
          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery details
                _buildDetailRow(
                  'Delivery',
                  isCustomPlan
                      ? _getSelectedWeekdaysText(selectedWeekdays)
                      : 'Monday to Friday',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Start Date',
                  DateFormat('EEE, MMM d, yyyy').format(startDate),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'End Date',
                  DateFormat('EEE, MMM d, yyyy').format(endDate),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Total Meals',
                  '${item['mealDates'].length}',
                ),
                // Price section
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.deepPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getSelectedWeekdaysText(List<bool> selectedWeekdays) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    List<String> selectedDays = [];

    for (int i = 0; i < selectedWeekdays.length; i++) {
      if (selectedWeekdays[i]) {
        selectedDays.add(weekdayNames[i]);
      }
    }

    if (selectedDays.isEmpty) {
      return "None";
    } else if (selectedDays.length == 5) {
      return "All Weekdays";
    } else {
      return selectedDays.join(", ");
    }
  }

  // Get an appropriate meal image based on meal information and type
  Widget _getMealImage(Meal meal, String mealType) {
    // Try to use the meal's image if available
    if (meal.imageUrl.isNotEmpty) {
      return Image.network(
        meal.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default meal image based on type
          return _getDefaultMealImage(mealType);
        },
      );
    }

    // Use default meal image based on type if no meal image is available
    return _getDefaultMealImage(mealType);
  }

  // Get default meal image based on meal type
  Widget _getDefaultMealImage(String mealType) {
    final String defaultImagePath = mealType == 'breakfast'
        ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
        : 'assets/images/lunch/lunch of the day (most recommended).png';

    return Image.asset(
      defaultImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Final fallback is the icon if asset image can't be loaded
        return _buildMealPlaceholder(mealType);
      },
    );
  }

  Widget _buildMealPlaceholder(String mealType) {
    return Center(
      child: Icon(
        mealType == 'breakfast' ? Icons.ramen_dining : Icons.flatware_rounded,
        color: AppTheme.purple,
        size: 32,
      ),
    );
  }
}
