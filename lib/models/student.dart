import 'package:intl/intl.dart';

/// Model class for representing a student in the system.
class Student {
  final String id;
  final String name;
  final int age;
  final String? grade;
  final String? parentId;
  final String? parentName;

  // Meal plan details
  final bool hasActiveBreakfast;
  final DateTime? breakfastPlanStartDate;
  final DateTime? breakfastPlanEndDate;
  final String? breakfastPreference;
  final List<int>? breakfastSelectedWeekdays;

  final bool hasActiveLunch;
  final DateTime? lunchPlanStartDate;
  final DateTime? lunchPlanEndDate;
  final String? lunchPreference;
  final List<int>? lunchSelectedWeekdays;
  final String? mealPlanType; // 'lunch' or 'express'

  // Legacy field - will be deprecated
  final List<int>? selectedWeekdays;

  Student({
    required this.id,
    required this.name,
    required this.age,
    this.grade,
    this.parentId,
    this.parentName,
    this.hasActiveBreakfast = false,
    this.breakfastPlanStartDate,
    this.breakfastPlanEndDate,
    this.breakfastPreference,
    this.breakfastSelectedWeekdays,
    this.hasActiveLunch = false,
    this.lunchPlanStartDate,
    this.lunchPlanEndDate,
    this.lunchPreference,
    this.lunchSelectedWeekdays,
    this.mealPlanType = 'lunch',
    this.selectedWeekdays,
  });

  /// Factory constructor to create a Student from a map (JSON data)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      grade: map['grade'] as String?,
      parentId: map['parentId'] as String?,
      parentName: map['parentName'] as String?,
      hasActiveBreakfast: map['hasActiveBreakfast'] as bool? ?? false,
      breakfastPlanStartDate: map['breakfastPlanStartDate'] != null
          ? DateTime.parse(map['breakfastPlanStartDate'] as String)
          : null,
      breakfastPlanEndDate: map['breakfastPlanEndDate'] != null
          ? DateTime.parse(map['breakfastPlanEndDate'] as String)
          : null,
      breakfastPreference: map['breakfastPreference'] as String?,
      breakfastSelectedWeekdays: map['breakfastSelectedWeekdays'] != null
          ? List<int>.from(map['breakfastSelectedWeekdays'] as List)
          : null,
      hasActiveLunch: map['hasActiveLunch'] as bool? ?? false,
      lunchPlanStartDate: map['lunchPlanStartDate'] != null
          ? DateTime.parse(map['lunchPlanStartDate'] as String)
          : null,
      lunchPlanEndDate: map['lunchPlanEndDate'] != null
          ? DateTime.parse(map['lunchPlanEndDate'] as String)
          : null,
      lunchPreference: map['lunchPreference'] as String?,
      lunchSelectedWeekdays: map['lunchSelectedWeekdays'] != null
          ? List<int>.from(map['lunchSelectedWeekdays'] as List)
          : null,
      mealPlanType: map['mealPlanType'] as String? ?? 'lunch',
      selectedWeekdays: map['selectedWeekdays'] != null
          ? List<int>.from(map['selectedWeekdays'] as List)
          : null,
    );
  }

  /// Convert this Student instance to a map (JSON data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'grade': grade,
      'parentId': parentId,
      'parentName': parentName,
      'hasActiveBreakfast': hasActiveBreakfast,
      'breakfastPlanStartDate': breakfastPlanStartDate?.toIso8601String(),
      'breakfastPlanEndDate': breakfastPlanEndDate?.toIso8601String(),
      'breakfastPreference': breakfastPreference,
      'breakfastSelectedWeekdays': breakfastSelectedWeekdays,
      'hasActiveLunch': hasActiveLunch,
      'lunchPlanStartDate': lunchPlanStartDate?.toIso8601String(),
      'lunchPlanEndDate': lunchPlanEndDate?.toIso8601String(),
      'lunchPreference': lunchPreference,
      'lunchSelectedWeekdays': lunchSelectedWeekdays,
      'mealPlanType': mealPlanType,
      'selectedWeekdays': selectedWeekdays,
    };
  }

  @override
  String toString() {
    final breakfastEndStr = breakfastPlanEndDate != null
        ? DateFormat('yyyy-MM-dd').format(breakfastPlanEndDate!)
        : 'N/A';
    final lunchEndStr = lunchPlanEndDate != null
        ? DateFormat('yyyy-MM-dd').format(lunchPlanEndDate!)
        : 'N/A';

    return 'Student(id: $id, name: $name, breakfast: $hasActiveBreakfast until $breakfastEndStr, lunch: $hasActiveLunch until $lunchEndStr)';
  }
}
