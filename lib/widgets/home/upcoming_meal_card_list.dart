import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';

enum MealType { veg, nonVeg }

class MealInfo {
  final String name;
  final String deliveryTime;
  final MealType type;

  MealInfo({
    required this.name,
    required this.deliveryTime,
    required this.type,
  });
}

class UpcomingMealCardList extends StatelessWidget {
  final List<MealInfo> meals;

  const UpcomingMealCardList({
    super.key,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildMealCard(context, meals[index]),
        );
      },
    );
  }

  Widget _buildMealCard(BuildContext context, MealInfo meal) {
    final isVeg = meal.type == MealType.veg;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.mealDetails,
          arguments: meal,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Meal type icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isVeg
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : AppTheme.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isVeg ? Icons.eco : Icons.restaurant,
                  size: 24,
                  color: isVeg ? const Color(0xFF4CAF50) : AppTheme.orange,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Meal info
            Expanded(
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
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal.deliveryTime,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Veg/Non-veg badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isVeg
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : AppTheme.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isVeg ? 'Veg' : 'Non-Veg',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isVeg ? const Color(0xFF4CAF50) : AppTheme.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
