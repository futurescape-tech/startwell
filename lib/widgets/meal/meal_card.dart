import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final MealCategory currentTab;
  final MealSelectionManager selectionManager;
  final VoidCallback onAddPressed;

  const MealCard({
    super.key,
    required this.meal,
    required this.currentTab,
    required this.selectionManager,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isVeg = meal.type == MealType.veg;
    final price = meal.getPriceWithSurcharge(
        isExpressTab: currentTab == MealCategory.expressOneDay);
    final isSelected = selectionManager.isMealSelected(meal.id);
    final isSelectedInCurrentTab =
        selectionManager.isMealSelectedInTab(meal.id, currentTab);
    final canSelect = selectionManager.canSelectMeal(meal, currentTab);
    final quantity = selectionManager.getMealQuantity(meal.id, currentTab);
    final totalPrice = price * quantity;

    // Get screen width to make card responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2) - 24; // Account for padding and spacing

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelectedInCurrentTab
            ? BorderSide(color: AppTheme.purple, width: 2)
            : currentTab == MealCategory.expressOneDay
                ? BorderSide(
                    color: AppTheme.orange.withOpacity(0.4), width: 1.5)
                : BorderSide.none,
      ),
      child: Stack(
        children: [
          Container(
            width: cardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal image with veg/non-veg badge and selection indicator
                Stack(
                  children: [
                    // Image container (replace with actual image when available)
                    Hero(
                      tag: 'meal-image-${meal.id}',
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isVeg
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : AppTheme.orange.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: meal.imageUrl.startsWith('http')
                              ? Image.network(
                                  meal.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 140,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback if image fails to load
                                    return Center(
                                      child: Icon(
                                        isVeg ? Icons.eco : Icons.restaurant,
                                        size: 50,
                                        color: isVeg
                                            ? const Color(0xFF4CAF50)
                                            : AppTheme.orange,
                                      ),
                                    );
                                  },
                                )
                              : meal.imageUrl.startsWith('assets/')
                                  ? Image.asset(
                                      meal.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 140,
                                    )
                                  : Center(
                                      child: Icon(
                                        isVeg ? Icons.eco : Icons.restaurant,
                                        size: 50,
                                        color: isVeg
                                            ? const Color(0xFF4CAF50)
                                            : AppTheme.orange,
                                      ),
                                    ),
                        ),
                      ),
                    ),

                    // Veg/Non-veg badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isVeg
                              ? const Color(0xFF4CAF50).withOpacity(0.9)
                              : AppTheme.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isVeg ? 'Veg' : 'Non-Veg',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Selected indicator with quantity
                    if (isSelectedInCurrentTab)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'x$quantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Express badge
                    if (currentTab == MealCategory.expressOneDay)
                      Positioned(
                        top: 50,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Express',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Meal info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Spacer(),

                        // Price and quantity controls
                        isSelectedInCurrentTab
                            ? _buildQuantitySelector()
                            : _buildPriceAndAddButton(
                                price, canSelect, context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Disabled overlay (when meal can't be selected)
          if (!canSelect && !isSelectedInCurrentTab)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.block,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectionManager.getSelectionRestrictionMessage(
                                meal, currentTab),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceAndAddButton(
      double price, bool canSelect, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Price with surcharge indicator for express tab
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            currentTab == MealCategory.expressOneDay && meal.isCommonMeal
                ? Row(
                    children: [
                      Text(
                        '₹${meal.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textMedium,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.purple,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.purple,
                    ),
                  ),
            if (currentTab == MealCategory.expressOneDay)
              Tooltip(
                message: meal.isCommonMeal
                    ? 'This meal is available in both Regular and Express tabs. ₹${meal.expressSurcharge.toStringAsFixed(0)} express fee added.'
                    : 'Express 1-Day delivery fee: ₹${meal.expressSurcharge.toStringAsFixed(0)}',
                child: Text(
                  meal.isCommonMeal
                      ? '(+₹${meal.expressSurcharge.toStringAsFixed(0)})'
                      : '(+₹${meal.expressSurcharge.toStringAsFixed(0)})',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.orange,
                  ),
                ),
              ),
          ],
        ),

        // Add button
        GestureDetector(
          onTap: () {
            if (canSelect) {
              selectionManager.incrementMealQuantity(meal, currentTab);
              HapticFeedback.lightImpact();
            } else {
              // Show why it can't be selected
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectionManager.getSelectionRestrictionMessage(
                        meal, currentTab),
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canSelect ? AppTheme.purple : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    final quantity = selectionManager.getMealQuantity(meal.id, currentTab);
    final price = meal.getPriceWithSurcharge(
        isExpressTab: currentTab == MealCategory.expressOneDay);
    final totalPrice = price * quantity;
    final isMaxReached = quantity >= MealSelectionManager.MAX_QUANTITY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total price
        Text(
          '₹${totalPrice.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.purple,
          ),
        ),
        const SizedBox(height: 4),

        // Quantity stepper
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Quantity label
            Text(
              'Quantity:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textMedium,
              ),
            ),

            // Stepper controls
            Row(
              children: [
                // Decrement button
                GestureDetector(
                  onTap: () {
                    selectionManager.decrementMealQuantity(meal, currentTab);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.purple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

                // Quantity display
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),

                // Increment button
                GestureDetector(
                  onTap: isMaxReached
                      ? null
                      : () {
                          selectionManager.incrementMealQuantity(
                              meal, currentTab);
                          HapticFeedback.lightImpact();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          isMaxReached ? Colors.grey.shade300 : AppTheme.purple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
