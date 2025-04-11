import 'package:flutter/material.dart';

enum MealType { veg, nonVeg }

enum MealCategory { breakfast, lunch, expressOneDay }

class Meal {
  final String id;
  final String name;
  final String description;
  final double price;
  final MealType type;
  final List<MealCategory> categories;
  final String imageUrl;
  final List<String> ingredients;
  final Map<String, String> nutritionalInfo;
  final List<String> allergyInfo;

  const Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.categories,
    required this.imageUrl,
    required this.ingredients,
    required this.nutritionalInfo,
    required this.allergyInfo,
  });

  // Get the express surcharge amount
  double get expressSurcharge => 50.0;

  // Check if this is a common meal (appears in both Express and Regular tabs)
  bool get isCommonMeal {
    bool inRegular = categories.contains(MealCategory.breakfast) ||
        categories.contains(MealCategory.lunch);
    bool inExpress = categories.contains(MealCategory.expressOneDay);

    return inRegular && inExpress;
  }

  // Get price with the express meal surcharge applied if applicable
  double getPriceWithSurcharge({required bool isExpressTab}) {
    if (isExpressTab) {
      // Add the express surcharge for all meals in Express tab
      return price + expressSurcharge;
    }
    return price;
  }

  // Get the price for the current tab
  double getPriceForTab(MealCategory currentTab) {
    if (currentTab == MealCategory.expressOneDay) {
      return getPriceWithSurcharge(isExpressTab: true);
    }
    return price;
  }

  // Check if meal belongs to a specific category
  bool isInCategory(MealCategory category) {
    return categories.contains(category);
  }

  // Create a copy of this Meal with modified properties
  Meal copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    MealType? type,
    List<MealCategory>? categories,
    String? imageUrl,
    List<String>? ingredients,
    Map<String, String>? nutritionalInfo,
    List<String>? allergyInfo,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      allergyInfo: allergyInfo ?? this.allergyInfo,
    );
  }
}
