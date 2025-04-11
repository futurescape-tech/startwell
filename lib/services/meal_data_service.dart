import 'package:startwell/models/meal_model.dart';

class MealDataService {
  // Method to get all meals (combined list)
  static List<Meal> getAllMeals() {
    final allMeals = [..._breakfastMeals, ..._lunchMeals, ..._expressMeals];

    // Remove duplicates based on ID
    final uniqueMeals = <String, Meal>{};
    for (var meal in allMeals) {
      uniqueMeals[meal.id] = meal;
    }

    return uniqueMeals.values.toList();
  }

  // Get breakfast meals
  static List<Meal> getBreakfastMeals() {
    return _breakfastMeals;
  }

  // Get lunch meals
  static List<Meal> getLunchMeals() {
    return _lunchMeals;
  }

  // Get express meals (filtered to only include common meals)
  static List<Meal> getExpressMeals() {
    // Extract all valid IDs from breakfast and lunch
    final validExpressIds = {
      ..._breakfastMeals.map((e) => e.id),
      ..._lunchMeals.map((e) => e.id),
    };

    // Filter express meals to only include those with IDs present in breakfast or lunch
    return _expressMeals
        .where((meal) => validExpressIds.contains(meal.id))
        .toList();
  }

  // Method to get meals by category
  static List<Meal> getMealsByCategory(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return getBreakfastMeals();
      case MealCategory.lunch:
        return getLunchMeals();
      case MealCategory.expressOneDay:
        return getExpressMeals();
    }
  }

  // Breakfast meals data
  static final List<Meal> _breakfastMeals = [
    // Sample breakfast meals
    Meal(
      id: 'b1',
      name: 'Poha',
      description: 'Flattened rice cooked with onions, peas, and mild spices.',
      price: 100.0,
      type: MealType.veg,
      categories: [MealCategory.breakfast, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/vYGZVGz.jpg',
      ingredients: [
        'Flattened Rice',
        'Onions',
        'Green Peas',
        'Mustard Seeds',
        'Turmeric'
      ],
      nutritionalInfo: {
        'Calories': '250 kcal',
        'Protein': '5g',
        'Carbs': '45g',
        'Fat': '7g',
      },
      allergyInfo: ['Gluten'],
    ),
    Meal(
      id: 'b2',
      name: 'Idli Sambhar',
      description: 'Soft steamed rice cakes served with lentil soup.',
      price: 120.0,
      type: MealType.veg,
      categories: [MealCategory.breakfast],
      imageUrl: 'https://i.imgur.com/8lK0jYf.jpg',
      ingredients: [
        'Rice',
        'Urad Dal',
        'Fenugreek Seeds',
        'Sambhar',
        'Coconut Chutney'
      ],
      nutritionalInfo: {
        'Calories': '220 kcal',
        'Protein': '8g',
        'Carbs': '40g',
        'Fat': '3g',
      },
      allergyInfo: [],
    ),
    Meal(
      id: 'b3',
      name: 'Omelette',
      description: 'Fluffy eggs cooked with vegetables and cheese.',
      price: 90.0,
      type: MealType.nonVeg,
      categories: [MealCategory.breakfast, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/MeIV5K6.jpg',
      ingredients: ['Eggs', 'Onions', 'Tomatoes', 'Bell Peppers', 'Cheese'],
      nutritionalInfo: {
        'Calories': '180 kcal',
        'Protein': '12g',
        'Carbs': '3g',
        'Fat': '14g',
      },
      allergyInfo: ['Eggs', 'Dairy'],
    ),
    Meal(
      id: 'b4',
      name: 'Fruit Granola Bowl',
      description: 'Crunchy granola with fresh fruits and yogurt.',
      price: 150.0,
      type: MealType.veg,
      categories: [MealCategory.breakfast],
      imageUrl: 'https://i.imgur.com/L9DuRWz.jpg',
      ingredients: [
        'Granola',
        'Greek Yogurt',
        'Strawberries',
        'Blueberries',
        'Honey'
      ],
      nutritionalInfo: {
        'Calories': '320 kcal',
        'Protein': '10g',
        'Carbs': '60g',
        'Fat': '8g',
      },
      allergyInfo: ['Nuts', 'Dairy'],
    ),
  ];

  // Lunch meals data
  static final List<Meal> _lunchMeals = [
    Meal(
      id: 'l1',
      name: 'Paneer Tikka Masala',
      description: 'Cottage cheese cubes in spicy tomato gravy.',
      price: 180.0,
      type: MealType.veg,
      categories: [MealCategory.lunch, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/d5JvIyQ.jpg',
      ingredients: ['Paneer', 'Tomatoes', 'Onions', 'Spices', 'Cream'],
      nutritionalInfo: {
        'Calories': '450 kcal',
        'Protein': '22g',
        'Carbs': '30g',
        'Fat': '25g',
      },
      allergyInfo: ['Dairy'],
    ),
    Meal(
      id: 'l2',
      name: 'Chicken Biryani',
      description: 'Fragrant rice cooked with spiced chicken and herbs.',
      price: 200.0,
      type: MealType.nonVeg,
      categories: [MealCategory.lunch, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/Vje9nsu.jpg',
      ingredients: [
        'Basmati Rice',
        'Chicken',
        'Onions',
        'Tomatoes',
        'Biryani Masala'
      ],
      nutritionalInfo: {
        'Calories': '550 kcal',
        'Protein': '30g',
        'Carbs': '65g',
        'Fat': '18g',
      },
      allergyInfo: [],
    ),
    Meal(
      id: 'l3',
      name: 'Vegetable Pulao',
      description: 'Rice cooked with mixed vegetables and mild spices.',
      price: 150.0,
      type: MealType.veg,
      categories: [MealCategory.lunch],
      imageUrl: 'https://i.imgur.com/vR43quy.jpg',
      ingredients: [
        'Rice',
        'Mixed Vegetables',
        'Onions',
        'Ginger-Garlic Paste',
        'Pulao Masala'
      ],
      nutritionalInfo: {
        'Calories': '380 kcal',
        'Protein': '8g',
        'Carbs': '70g',
        'Fat': '10g',
      },
      allergyInfo: [],
    ),
    Meal(
      id: 'l4',
      name: 'Dal Makhani',
      description: 'Creamy black lentils cooked overnight.',
      price: 170.0,
      type: MealType.veg,
      categories: [MealCategory.lunch],
      imageUrl: 'https://i.imgur.com/OXZyaWm.jpg',
      ingredients: [
        'Black Lentils',
        'Kidney Beans',
        'Butter',
        'Cream',
        'Spices'
      ],
      nutritionalInfo: {
        'Calories': '320 kcal',
        'Protein': '15g',
        'Carbs': '45g',
        'Fat': '12g',
      },
      allergyInfo: ['Dairy'],
    ),
  ];

  // Express 1-Day meals data (will be filtered to only include common meals)
  static final List<Meal> _expressMeals = [
    // Common meals already in Breakfast or Lunch
    Meal(
      id: 'b1', // Poha (same as in breakfast)
      name: 'Poha',
      description: 'Flattened rice cooked with onions, peas, and mild spices.',
      price: 100.0,
      type: MealType.veg,
      categories: [MealCategory.breakfast, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/vYGZVGz.jpg',
      ingredients: [
        'Flattened Rice',
        'Onions',
        'Green Peas',
        'Mustard Seeds',
        'Turmeric'
      ],
      nutritionalInfo: {
        'Calories': '250 kcal',
        'Protein': '5g',
        'Carbs': '45g',
        'Fat': '7g',
      },
      allergyInfo: ['Gluten'],
    ),
    Meal(
      id: 'b3', // Omelette (same as in breakfast)
      name: 'Omelette',
      description: 'Fluffy eggs cooked with vegetables and cheese.',
      price: 90.0,
      type: MealType.nonVeg,
      categories: [MealCategory.breakfast, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/MeIV5K6.jpg',
      ingredients: ['Eggs', 'Onions', 'Tomatoes', 'Bell Peppers', 'Cheese'],
      nutritionalInfo: {
        'Calories': '180 kcal',
        'Protein': '12g',
        'Carbs': '3g',
        'Fat': '14g',
      },
      allergyInfo: ['Eggs', 'Dairy'],
    ),
    Meal(
      id: 'l1', // Paneer Tikka Masala (same as in lunch)
      name: 'Paneer Tikka Masala',
      description: 'Cottage cheese cubes in spicy tomato gravy.',
      price: 180.0,
      type: MealType.veg,
      categories: [MealCategory.lunch, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/d5JvIyQ.jpg',
      ingredients: ['Paneer', 'Tomatoes', 'Onions', 'Spices', 'Cream'],
      nutritionalInfo: {
        'Calories': '450 kcal',
        'Protein': '22g',
        'Carbs': '30g',
        'Fat': '25g',
      },
      allergyInfo: ['Dairy'],
    ),
    Meal(
      id: 'l2', // Chicken Biryani (same as in lunch)
      name: 'Chicken Biryani',
      description: 'Fragrant rice cooked with spiced chicken and herbs.',
      price: 200.0,
      type: MealType.nonVeg,
      categories: [MealCategory.lunch, MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/Vje9nsu.jpg',
      ingredients: [
        'Basmati Rice',
        'Chicken',
        'Onions',
        'Tomatoes',
        'Biryani Masala'
      ],
      nutritionalInfo: {
        'Calories': '550 kcal',
        'Protein': '30g',
        'Carbs': '65g',
        'Fat': '18g',
      },
      allergyInfo: [],
    ),
    // Express-only meal (will be filtered out by getExpressMeals())
    Meal(
      id: 'e1', // Unique to Express - will be filtered out
      name: 'Premium Salad Bowl',
      description: 'Fresh mixed greens with grilled chicken and vinaigrette.',
      price: 210.0,
      type: MealType.nonVeg,
      categories: [MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/H8kkvYC.jpg',
      ingredients: [
        'Mixed Greens',
        'Grilled Chicken',
        'Cherry Tomatoes',
        'Cucumber',
        'Vinaigrette'
      ],
      nutritionalInfo: {
        'Calories': '280 kcal',
        'Protein': '25g',
        'Carbs': '15g',
        'Fat': '14g',
      },
      allergyInfo: ['Nuts'],
    ),
    Meal(
      id: 'e2', // Unique to Express - will be filtered out
      name: 'Vegan Buddha Bowl',
      description:
          'Nutritious bowl with quinoa, avocado, and roasted vegetables.',
      price: 230.0,
      type: MealType.veg,
      categories: [MealCategory.expressOneDay],
      imageUrl: 'https://i.imgur.com/RLOKvhX.jpg',
      ingredients: [
        'Quinoa',
        'Avocado',
        'Roasted Sweet Potato',
        'Chickpeas',
        'Tahini Dressing'
      ],
      nutritionalInfo: {
        'Calories': '420 kcal',
        'Protein': '15g',
        'Carbs': '60g',
        'Fat': '18g',
      },
      allergyInfo: ['Sesame'],
    ),
  ];
}
