import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/info_banner.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({
    super.key,
  });

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation immediately
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Meal meal = args['meal'] as Meal;
    final MealCategory currentTab = args['currentTab'] as MealCategory;
    final MealSelectionManager selectionManager =
        args['selectionManager'] as MealSelectionManager;
    final String heroTag = args['heroTag'] as String;

    final isVeg = meal.type == MealType.veg;
    final isExpressTab = currentTab == MealCategory.expressOneDay;
    final price = meal.getPriceWithSurcharge(isExpressTab: isExpressTab);
    final isSelected = selectionManager.isMealSelected(meal.id);
    final isSelectedInCurrentTab =
        selectionManager.isMealSelectedInTab(meal.id, currentTab);
    final canSelect = selectionManager.canSelectMeal(meal, currentTab);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppTheme.purple,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: heroTag,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleToDeepPurple,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display image based on URL type
                        meal.imageUrl.startsWith('http')
                            ? Image.network(
                                meal.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if image fails to load
                                  return Center(
                                    child: Icon(
                                      isVeg ? Icons.eco : Icons.restaurant,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  );
                                },
                              )
                            : meal.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    meal.imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(
                                      isVeg ? Icons.eco : Icons.restaurant,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  ),
                        // Overlay to darken the image
                        Container(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Express meal banner (for express tab only)
                      if (isExpressTab)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InfoBanner(
                            title: "Express 1-Day Meal",
                            message:
                                "This meal includes a ₹${meal.expressSurcharge.toStringAsFixed(0)} express fee for same-day delivery only",
                            type: InfoBannerType.info,
                            customIcon: Icons.flash_on,
                          ),
                        ),

                      // Meal name
                      Text(
                        meal.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Meal Type Badge and Price Row
                      Row(
                        children: [
                          _buildMealTypeBadge(isVeg),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              isExpressTab
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₹${meal.price.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: AppTheme.textMedium,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '₹${price.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.purple,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '₹${price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.purple,
                                      ),
                                    ),
                              if (isExpressTab)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flash_on,
                                        size: 14,
                                        color: AppTheme.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Express +₹${meal.expressSurcharge.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      if (isExpressTab)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.textMedium,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Same-day delivery with express fee',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textMedium,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(
                        meal.description,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.textMedium,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Ingredients
                      _buildSectionTitle('Ingredients'),
                      const SizedBox(height: 15),
                      _buildIngredientsList(meal.ingredients, isTablet),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Nutritional Values
                      _buildSectionTitle('Nutritional Values'),
                      const SizedBox(height: 15),
                      _buildNutritionalInfo(meal.nutritionalInfo, isTablet),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Allergy Information
                      _buildSectionTitle('Allergy Information'),
                      const SizedBox(height: 15),
                      _buildAllergyInfo(meal.allergyInfo),
                      const SizedBox(height: 64), // Space for button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Add/Remove Button
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection restriction message
            if (!isSelectedInCurrentTab && !canSelect)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InfoBanner(
                  title: _getRestrictionTitle(currentTab, selectionManager),
                  message: selectionManager.getSelectionRestrictionMessage(
                      meal, currentTab),
                  type: InfoBannerType.error,
                ),
              ),

            _buildAddButton(
              isSelected: isSelectedInCurrentTab,
              onPressed: () {
                if (isSelectedInCurrentTab || canSelect) {
                  selectionManager.toggleMealSelection(meal, currentTab);
                  setState(() {});
                  HapticFeedback.mediumImpact();
                } else {
                  // If can't select, provide feedback
                  HapticFeedback.heavyImpact();
                }
              },
              isDisabled: !isSelectedInCurrentTab && !canSelect,
            ),
          ],
        ),
      ),
    );
  }

  String _getRestrictionTitle(
      MealCategory currentTab, MealSelectionManager selectionManager) {
    if (selectionManager.hasExpressSelections &&
        (currentTab == MealCategory.breakfast ||
            currentTab == MealCategory.lunch)) {
      return "Express meals already selected";
    } else if (selectionManager.hasBreakfastSelections &&
        selectionManager.hasLunchSelections &&
        currentTab == MealCategory.expressOneDay) {
      return "Breakfast & Lunch meals already selected";
    } else if (selectionManager.hasBreakfastSelections &&
        !selectionManager.hasLunchSelections &&
        currentTab == MealCategory.expressOneDay) {
      return "Breakfast meals already selected";
    } else if (!selectionManager.hasBreakfastSelections &&
        selectionManager.hasLunchSelections &&
        currentTab == MealCategory.expressOneDay) {
      return "Lunch meals already selected";
    } else {
      return "Selection not available";
    }
  }

  Widget _buildMealTypeBadge(bool isVeg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isVeg
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : AppTheme.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVeg
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : AppTheme.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVeg ? Icons.eco : Icons.restaurant,
            size: 16,
            color: isVeg ? const Color(0xFF4CAF50) : AppTheme.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isVeg ? 'Vegetarian' : 'Non-Vegetarian',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isVeg ? const Color(0xFF4CAF50) : AppTheme.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildIngredientsList(List<String> ingredients, bool isTablet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ingredients.map((ingredient) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.deepPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            ingredient,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.deepPurple,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionalInfo(
      Map<String, String> nutritionalInfo, bool isTablet) {
    if (isTablet) {
      // For tablets, show in a grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
        ),
        itemCount: nutritionalInfo.entries.length,
        itemBuilder: (context, index) {
          final entry = nutritionalInfo.entries.elementAt(index);
          return _buildNutritionItem(entry.key, entry.value);
        },
      );
    } else {
      // For phones, show in a column
      return Column(
        children: nutritionalInfo.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNutritionItem(entry.key, entry.value),
          );
        }).toList(),
      );
    }
  }

  Widget _buildNutritionItem(String key, String value) {
    return Row(
      children: [
        Container(
          width: 110,
          child: Text(
            key,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyInfo(List<String> allergyInfo) {
    if (allergyInfo.isEmpty) {
      return Text(
        'No common allergens found in this meal.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This meal contains the following allergens:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allergyInfo.map((allergen) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                allergen,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.error,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddButton({
    required bool isSelected,
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? Colors.grey.shade300
            : (isSelected ? Colors.red : AppTheme.purple),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      icon: Icon(
          isSelected ? Icons.remove_shopping_cart : Icons.add_shopping_cart),
      label: Text(
        isSelected ? 'Remove from Selection' : 'Add to Selection',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
