// Strict meal names for StartWell
class MealNames {
  static const String breakfastOfTheDay = 'breakfast of the day';
  static const String indianBreakfast = 'indian breakfast';
  static const String internationalBreakfast = 'international breakfast';
  static const String jainBreakfast = 'jain breakfast';

  static const String lunchOfTheDay = 'lunch of the day';
  static const String indianLunch = 'indian lunch';
  static const String internationalLunch = 'international lunch';
  static const String jainLunch = 'jain lunch';

  static const List<String> breakfastMeals = [
    breakfastOfTheDay,
    indianBreakfast,
    internationalBreakfast,
    jainBreakfast,
  ];
  static const List<String> lunchMeals = [
    lunchOfTheDay,
    indianLunch,
    internationalLunch,
    jainLunch,
  ];
}

String normalizeMealName(String name, String mealType) {
  final n = name.trim().toLowerCase();
  if (mealType == 'breakfast' && MealNames.breakfastMeals.contains(n)) return n;
  if (mealType == 'lunch' && MealNames.lunchMeals.contains(n)) return n;
  // fallback
  return mealType == 'breakfast'
      ? MealNames.breakfastOfTheDay
      : MealNames.lunchOfTheDay;
}

// Strict asset mapping for meal images
String getMealImageAsset(String mealName, String mealType) {
  final name = mealName.trim().toLowerCase();
  if (mealType == 'breakfast') {
    if (name == 'breakfast of the day')
      return 'assets/images/breakfast/breakfast of the day (most recommended).png';
    if (name == 'indian breakfast')
      return 'assets/images/breakfast/Indian Breakfast.png';
    if (name == 'international breakfast')
      return 'assets/images/breakfast/International Breakfast.png';
    if (name == 'jain breakfast')
      return 'assets/images/breakfast/Jain Breakfast.png';
  } else if (mealType == 'lunch') {
    if (name == 'lunch of the day')
      return 'assets/images/lunch/lunch of the day (most recommended).png';
    if (name == 'indian lunch') return 'assets/images/lunch/Indian Lunch.png';
    if (name == 'international lunch')
      return 'assets/images/lunch/International Lunch.png';
    if (name == 'jain lunch') return 'assets/images/lunch/Jain Lunch.png';
  }
  // fallback
  return mealType == 'breakfast'
      ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
      : 'assets/images/lunch/lunch of the day (most recommended).png';
}
