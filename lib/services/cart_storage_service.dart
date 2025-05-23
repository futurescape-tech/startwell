import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/models/meal_model.dart';

class CartStorageService {
  static const String cartItemsKey = 'cart_items';

  // Save cart items to shared preferences
  static Future<void> saveCartItems(
      List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert complex objects to simple types for storage
    final List<Map<String, dynamic>> storableCartItems = cartItems.map((item) {
      // Convert DateTime objects to ISO strings
      final Map<String, dynamic> storableItem = {
        'planType': item['planType'],
        'isCustomPlan': item['isCustomPlan'],
        'selectedWeekdays': List<bool>.from(item['selectedWeekdays']),
        'startDate': item['startDate'].toIso8601String(),
        'endDate': item['endDate'].toIso8601String(),
        'mealDates': (item['mealDates'] as List<DateTime>)
            .map((date) => date.toIso8601String())
            .toList(),
        'totalAmount': item['totalAmount'],
        'mealType': item['mealType'],
        'isExpressOrder': item['isExpressOrder'],
      };

      // Convert Meal objects to simple maps
      final List<Map<String, dynamic>> storableMeals =
          (item['selectedMeals'] as List<Meal>)
              .map((meal) => {
                    'id': meal.id,
                    'name': meal.name,
                    'description': meal.description,
                    'price': meal.price,
                    'type': meal.type.index,
                    'categories': meal.categories.map((c) => c.index).toList(),
                    'imageUrl': meal.imageUrl,
                    'ingredients': meal.ingredients,
                    'nutritionalInfo': meal.nutritionalInfo,
                    'allergyInfo': meal.allergyInfo,
                  })
              .toList();

      storableItem['selectedMeals'] = storableMeals;

      return storableItem;
    }).toList();

    // Save as JSON string
    await prefs.setString(cartItemsKey, jsonEncode(storableCartItems));
  }

  // Load cart items from shared preferences
  static Future<List<Map<String, dynamic>>> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();

    final String? cartItemsJson = prefs.getString(cartItemsKey);

    if (cartItemsJson == null || cartItemsJson.isEmpty) {
      return [];
    }

    // Parse JSON string to List of Maps
    final List<dynamic> decodedItems = jsonDecode(cartItemsJson);

    // Convert simple types back to complex objects
    return decodedItems.map<Map<String, dynamic>>((item) {
      // Convert ISO strings back to DateTime objects
      final Map<String, dynamic> loadedItem = {
        'planType': item['planType'],
        'isCustomPlan': item['isCustomPlan'],
        'selectedWeekdays': List<bool>.from(item['selectedWeekdays']),
        'startDate': DateTime.parse(item['startDate']),
        'endDate': DateTime.parse(item['endDate']),
        'mealDates': (item['mealDates'] as List<dynamic>?)
                ?.map((dateStr) => DateTime.parse(dateStr.toString()))
                .toList() ??
            [],
        'totalAmount': item['totalAmount'],
        'mealType': item['mealType'],
        'isExpressOrder': item['isExpressOrder'],
      };

      // Convert simple maps back to Meal objects
      final List<Meal> loadedMeals = (item['selectedMeals'] as List<dynamic>)
          .map((mealMap) => Meal(
                id: mealMap['id'],
                name: mealMap['name'],
                description: mealMap['description'],
                price: mealMap['price'],
                type: MealType.values[mealMap['type']],
                categories: (mealMap['categories'] as List<dynamic>)
                    .map((c) => MealCategory.values[c as int])
                    .toList(),
                imageUrl: mealMap['imageUrl'],
                ingredients: List<String>.from(mealMap['ingredients']),
                nutritionalInfo:
                    Map<String, String>.from(mealMap['nutritionalInfo']),
                allergyInfo: List<String>.from(mealMap['allergyInfo']),
              ))
          .toList();

      loadedItem['selectedMeals'] = loadedMeals;

      return loadedItem;
    }).toList();
  }

  // Clear all cart items
  static Future<void> clearCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartItemsKey);
  }

  // Remove cart items by meal type
  static Future<void> removeCartItemsByMealType(String mealType) async {
    // Get existing cart items
    final List<Map<String, dynamic>> cartItems = await loadCartItems();

    // Filter out items with the specified meal type
    final List<Map<String, dynamic>> filteredItems =
        cartItems.where((item) => item['mealType'] != mealType).toList();

    // Save the filtered list back to storage
    if (filteredItems.isEmpty) {
      await clearCartItems();
    } else {
      await saveCartItems(filteredItems);
    }
  }
}
