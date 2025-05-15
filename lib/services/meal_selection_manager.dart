import 'package:flutter/material.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/services/meal_data_service.dart';

/// Enum to track which tab a meal was selected from
enum SelectedTab { none, breakfast, lunch, express }

class MealSelectionManager extends ChangeNotifier {
  // Map to track selected meal IDs and which tab they were selected from
  final Map<String, SelectedTab> _selectedMeals = {};

  // Maps to track quantities for each meal ID in each tab
  final Map<String, int> _breakfastQuantities = {};
  final Map<String, int> _lunchQuantities = {};
  final Map<String, int> _expressQuantities = {};

  // Maximum quantity allowed per meal
  static const int MAX_QUANTITY = 10;

  // Get all selected meal IDs
  Set<String> get selectedMealIds => _selectedMeals.keys.toSet();

  // Quantity map getters
  Map<String, int> get breakfastQuantities =>
      Map.unmodifiable(_breakfastQuantities);
  Map<String, int> get lunchQuantities => Map.unmodifiable(_lunchQuantities);
  Map<String, int> get expressQuantities =>
      Map.unmodifiable(_expressQuantities);

  // Get quantity for a specific meal in a specific tab
  int getMealQuantity(String mealId, MealCategory tabCategory) {
    switch (tabCategory) {
      case MealCategory.breakfast:
        return _breakfastQuantities[mealId] ?? 0;
      case MealCategory.lunch:
        return _lunchQuantities[mealId] ?? 0;
      case MealCategory.expressOneDay:
        return _expressQuantities[mealId] ?? 0;
    }
  }

  // Get total selected quantity across all tabs
  int get totalQuantity {
    int total = 0;
    _breakfastQuantities.values.forEach((qty) => total += qty);
    _lunchQuantities.values.forEach((qty) => total += qty);
    _expressQuantities.values.forEach((qty) => total += qty);
    return total;
  }

  // Check if breakfast tab has selections
  bool get hasBreakfastSelections =>
      _selectedMeals.values.contains(SelectedTab.breakfast);

  // Check if lunch tab has selections
  bool get hasLunchSelections =>
      _selectedMeals.values.contains(SelectedTab.lunch);

  // Check if express tab has selections
  bool get hasExpressSelections =>
      _selectedMeals.values.contains(SelectedTab.express);

  // Check if any regular meal (breakfast or lunch) is selected
  bool get hasRegularMealSelections =>
      hasBreakfastSelections || hasLunchSelections;

  // Check if a meal is selected
  bool isMealSelected(String mealId) {
    return _selectedMeals.containsKey(mealId);
  }

  // Check if a meal is selected in the current tab
  bool isMealSelectedInTab(String mealId, MealCategory tabCategory) {
    if (!_selectedMeals.containsKey(mealId)) {
      return false;
    }

    SelectedTab selectedTab = _selectedMeals[mealId]!;

    // Check if the meal is selected in the current tab
    switch (tabCategory) {
      case MealCategory.breakfast:
        return selectedTab == SelectedTab.breakfast;
      case MealCategory.lunch:
        return selectedTab == SelectedTab.lunch;
      case MealCategory.expressOneDay:
        return selectedTab == SelectedTab.express;
    }
  }

  // Get all selected meals
  List<Meal> getSelectedMeals(List<Meal> allMeals) {
    return allMeals
        .where((meal) => _selectedMeals.containsKey(meal.id))
        .toList();
  }

  // Get number of selected meals (unique items, not quantities)
  int get selectedCount => _selectedMeals.length;

  // Check if meal can be selected based on tab exclusivity rules
  bool canSelectMeal(Meal meal, MealCategory currentTab) {
    // Temporarily disable express meal selection
    if (currentTab == MealCategory.expressOneDay) {
      return false;
    }

    final mealId = meal.id;

    // If already selected in current tab, allow toggling off
    if (_selectedMeals.containsKey(mealId) &&
        ((currentTab == MealCategory.breakfast &&
                _selectedMeals[mealId] == SelectedTab.breakfast) ||
            (currentTab == MealCategory.lunch &&
                _selectedMeals[mealId] == SelectedTab.lunch) ||
            (currentTab == MealCategory.expressOneDay &&
                _selectedMeals[mealId] == SelectedTab.express))) {
      return true;
    }

    // If already selected in another tab, don't allow selection
    if (_selectedMeals.containsKey(mealId)) {
      return false;
    }

    // Apply tab exclusivity rules

    // Scenario 1 & 2: If Breakfast or Lunch has selections, Express is disabled
    if (currentTab == MealCategory.expressOneDay && hasRegularMealSelections) {
      return false;
    }

    // Scenario 3: If Express has selections, both Breakfast and Lunch are disabled
    if ((currentTab == MealCategory.breakfast ||
            currentTab == MealCategory.lunch) &&
        hasExpressSelections) {
      return false;
    }

    // Default: Allow selection if no exclusivity rule is violated
    return true;
  }

  // Get the message explaining why a meal can't be selected
  String getSelectionRestrictionMessage(Meal meal, MealCategory currentTab) {
    if (canSelectMeal(meal, currentTab)) {
      return ""; // No restriction
    }

    // Already selected in another tab
    if (_selectedMeals.containsKey(meal.id)) {
      SelectedTab selectedTab = _selectedMeals[meal.id]!;
      String tabName = "";

      switch (selectedTab) {
        case SelectedTab.breakfast:
          tabName = "Breakfast";
          break;
        case SelectedTab.lunch:
          tabName = "Lunch";
          break;
        case SelectedTab.express:
          tabName = "Express 1-Day";
          break;
        default:
          break;
      }

      return "This meal is already selected in the $tabName tab";
    }

    // Express is disabled when Regular meals are selected
    if (currentTab == MealCategory.expressOneDay && hasRegularMealSelections) {
      if (hasBreakfastSelections && hasLunchSelections) {
        return "You can't select Express 1-Day meals when both Breakfast and Lunch meals are already selected";
      } else if (hasBreakfastSelections) {
        return "You can't select Express 1-Day meals when Breakfast meals are already selected";
      } else {
        return "You can't select Express 1-Day meals when Lunch meals are already selected";
      }
    }

    // Regular meals are disabled when Express is selected
    if ((currentTab == MealCategory.breakfast ||
            currentTab == MealCategory.lunch) &&
        hasExpressSelections) {
      return "You can't select ${currentTab == MealCategory.breakfast ? 'Breakfast' : 'Lunch'} meals when Express 1-Day meals are already selected";
    }

    return "This meal cannot be selected";
  }

  // Increment meal quantity in a specific tab
  void incrementMealQuantity(Meal meal, MealCategory currentTab) {
    final mealId = meal.id;

    // If the meal isn't selected yet, select it first
    if (!isMealSelectedInTab(mealId, currentTab)) {
      if (!canSelectMeal(meal, currentTab)) {
        return; // Can't select this meal due to tab exclusivity rules
      }

      // Add to selected meals
      SelectedTab selectedTabForCurrentTab;
      switch (currentTab) {
        case MealCategory.breakfast:
          selectedTabForCurrentTab = SelectedTab.breakfast;
          break;
        case MealCategory.lunch:
          selectedTabForCurrentTab = SelectedTab.lunch;
          break;
        case MealCategory.expressOneDay:
          selectedTabForCurrentTab = SelectedTab.express;
          break;
      }
      _selectedMeals[mealId] = selectedTabForCurrentTab;

      // Initialize quantity to 0 (will be incremented below)
      switch (currentTab) {
        case MealCategory.breakfast:
          _breakfastQuantities[mealId] = 0;
          break;
        case MealCategory.lunch:
          _lunchQuantities[mealId] = 0;
          break;
        case MealCategory.expressOneDay:
          _expressQuantities[mealId] = 0;
          break;
      }
    }

    // Now increment the quantity if below max
    switch (currentTab) {
      case MealCategory.breakfast:
        if (_breakfastQuantities[mealId]! < MAX_QUANTITY) {
          _breakfastQuantities[mealId] =
              (_breakfastQuantities[mealId] ?? 0) + 1;
        }
        break;
      case MealCategory.lunch:
        if (_lunchQuantities[mealId]! < MAX_QUANTITY) {
          _lunchQuantities[mealId] = (_lunchQuantities[mealId] ?? 0) + 1;
        }
        break;
      case MealCategory.expressOneDay:
        if (_expressQuantities[mealId]! < MAX_QUANTITY) {
          _expressQuantities[mealId] = (_expressQuantities[mealId] ?? 0) + 1;
        }
        break;
    }

    notifyListeners();
  }

  // Decrement meal quantity in a specific tab
  void decrementMealQuantity(Meal meal, MealCategory currentTab) {
    final mealId = meal.id;

    // If the meal isn't selected in this tab, do nothing
    if (!isMealSelectedInTab(mealId, currentTab)) {
      return;
    }

    // Decrement quantity
    switch (currentTab) {
      case MealCategory.breakfast:
        if (_breakfastQuantities[mealId]! > 1) {
          _breakfastQuantities[mealId] = _breakfastQuantities[mealId]! - 1;
        } else {
          // If quantity would go to 0, remove from selection
          _breakfastQuantities.remove(mealId);
          _selectedMeals.remove(mealId);
        }
        break;
      case MealCategory.lunch:
        if (_lunchQuantities[mealId]! > 1) {
          _lunchQuantities[mealId] = _lunchQuantities[mealId]! - 1;
        } else {
          // If quantity would go to 0, remove from selection
          _lunchQuantities.remove(mealId);
          _selectedMeals.remove(mealId);
        }
        break;
      case MealCategory.expressOneDay:
        if (_expressQuantities[mealId]! > 1) {
          _expressQuantities[mealId] = _expressQuantities[mealId]! - 1;
        } else {
          // If quantity would go to 0, remove from selection
          _expressQuantities.remove(mealId);
          _selectedMeals.remove(mealId);
        }
        break;
    }

    notifyListeners();
  }

  // Toggle meal selection for a specific tab
  void toggleMealSelection(Meal meal, MealCategory currentTab) {
    final mealId = meal.id;
    SelectedTab selectedTabForCurrentTab;

    // Map the current tab to a SelectedTab enum
    switch (currentTab) {
      case MealCategory.breakfast:
        selectedTabForCurrentTab = SelectedTab.breakfast;
        break;
      case MealCategory.lunch:
        selectedTabForCurrentTab = SelectedTab.lunch;
        break;
      case MealCategory.expressOneDay:
        selectedTabForCurrentTab = SelectedTab.express;
        break;
    }

    // If meal is already selected in current tab, remove it
    if (_selectedMeals.containsKey(mealId) &&
        _selectedMeals[mealId] == selectedTabForCurrentTab) {
      _selectedMeals.remove(mealId);

      // Also remove from quantity maps
      switch (currentTab) {
        case MealCategory.breakfast:
          _breakfastQuantities.remove(mealId);
          break;
        case MealCategory.lunch:
          _lunchQuantities.remove(mealId);
          break;
        case MealCategory.expressOneDay:
          _expressQuantities.remove(mealId);
          break;
      }

      notifyListeners();
      return;
    }

    // Check if selection is allowed
    if (!canSelectMeal(meal, currentTab)) {
      return;
    }

    // Add meal to selection
    _selectedMeals[mealId] = selectedTabForCurrentTab;

    // Initialize quantity to 1
    switch (currentTab) {
      case MealCategory.breakfast:
        _breakfastQuantities[mealId] = 1;
        break;
      case MealCategory.lunch:
        _lunchQuantities[mealId] = 1;
        break;
      case MealCategory.expressOneDay:
        _expressQuantities[mealId] = 1;
        break;
    }

    notifyListeners();
  }

  // Calculate total price of selected meals with quantities
  double calculateTotalPrice(List<Meal> allMeals) {
    double total = 0.0;

    // Calculate breakfast meals
    for (var meal in allMeals.where((m) =>
        m.isInCategory(MealCategory.breakfast) &&
        _selectedMeals.containsKey(m.id) &&
        _selectedMeals[m.id] == SelectedTab.breakfast)) {
      int quantity = _breakfastQuantities[meal.id] ?? 0;
      total += meal.price * quantity;
    }

    // Calculate lunch meals
    for (var meal in allMeals.where((m) =>
        m.isInCategory(MealCategory.lunch) &&
        _selectedMeals.containsKey(m.id) &&
        _selectedMeals[m.id] == SelectedTab.lunch)) {
      int quantity = _lunchQuantities[meal.id] ?? 0;
      total += meal.price * quantity;
    }

    // Calculate express meals (with surcharge)
    for (var meal in allMeals.where((m) =>
        m.isInCategory(MealCategory.expressOneDay) &&
        _selectedMeals.containsKey(m.id) &&
        _selectedMeals[m.id] == SelectedTab.express)) {
      int quantity = _expressQuantities[meal.id] ?? 0;
      total += meal.getPriceWithSurcharge(isExpressTab: true) * quantity;
    }

    return total;
  }

  // Filter meals for display in each tab
  List<Meal> filterMealsByTab(List<Meal> meals, MealCategory currentTab) {
    return meals;
  }

  // Clear all selections
  void clearSelections() {
    _selectedMeals.clear();
    _breakfastQuantities.clear();
    _lunchQuantities.clear();
    _expressQuantities.clear();
    notifyListeners();
  }

  // Get total number of items (considering quantities)
  int get totalItemCount {
    int count = 0;
    _breakfastQuantities.values.forEach((qty) => count += qty);
    _lunchQuantities.values.forEach((qty) => count += qty);
    _expressQuantities.values.forEach((qty) => count += qty);
    return count;
  }
}
