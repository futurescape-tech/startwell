class Student {
  final String id;
  final String name;
  final String schoolName;
  final String className;
  final String division;
  final String floor;
  final String allergies;
  final String grade;
  final String section;
  final String profileImageUrl;
  final String? mealPlanType; // 'breakfast', 'lunch', or 'express'
  final DateTime? mealPlanEndDate;

  // Active plan information
  final bool hasActiveBreakfast;
  final bool hasActiveLunch;
  final DateTime? breakfastPlanStartDate; // When breakfast plan starts
  final DateTime? lunchPlanStartDate; // When lunch plan starts
  final DateTime? breakfastPlanEndDate;
  final DateTime? lunchPlanEndDate;

  // Meal preferences
  final String? breakfastPreference; // 'Indian', 'Jain', 'International', etc.
  final String? lunchPreference; // 'Indian', 'Jain', 'International', etc.

  // Separate weekday selections for each meal type
  final List<int>?
      breakfastSelectedWeekdays; // For breakfast custom plans: Mon-1, Tue-2, etc.
  final List<int>?
      lunchSelectedWeekdays; // For lunch custom plans: Mon-1, Tue-2, etc.

  // Deprecated - kept for backward compatibility
  final List<int>? selectedWeekdays;

  // Getter to check if student has any active plan
  bool get hasActivePlan => hasActiveBreakfast || hasActiveLunch;

  // Getter to get the appropriate selected weekdays based on meal type
  List<int>? getSelectedWeekdaysForMealType(String mealType) {
    if (mealType == 'breakfast') {
      return breakfastSelectedWeekdays;
    } else if (mealType == 'lunch' || mealType == 'express') {
      return lunchSelectedWeekdays;
    }
    return null;
  }

  Student({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.className,
    required this.division,
    required this.floor,
    required this.allergies,
    required this.grade,
    required this.section,
    required this.profileImageUrl,
    this.mealPlanType,
    this.mealPlanEndDate,
    this.hasActiveBreakfast = false,
    this.hasActiveLunch = false,
    this.breakfastPlanStartDate,
    this.breakfastPlanEndDate,
    this.lunchPlanStartDate,
    this.lunchPlanEndDate,
    this.breakfastPreference,
    this.lunchPreference,
    this.selectedWeekdays,
    this.breakfastSelectedWeekdays,
    this.lunchSelectedWeekdays,
  });

  // Create a copy of the student with optional new values
  Student copyWith({
    String? id,
    String? name,
    String? schoolName,
    String? className,
    String? division,
    String? floor,
    String? allergies,
    bool? hasActiveBreakfast,
    bool? hasActiveLunch,
    DateTime? breakfastPlanStartDate,
    DateTime? breakfastPlanEndDate,
    DateTime? lunchPlanStartDate,
    DateTime? lunchPlanEndDate,
    String? grade,
    String? section,
    String? profileImageUrl,
    String? mealPlanType,
    DateTime? mealPlanEndDate,
    String? breakfastPreference,
    String? lunchPreference,
    List<int>? selectedWeekdays,
    List<int>? breakfastSelectedWeekdays,
    List<int>? lunchSelectedWeekdays,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      division: division ?? this.division,
      floor: floor ?? this.floor,
      allergies: allergies ?? this.allergies,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mealPlanType: mealPlanType ?? this.mealPlanType,
      mealPlanEndDate: mealPlanEndDate ?? this.mealPlanEndDate,
      hasActiveBreakfast: hasActiveBreakfast ?? this.hasActiveBreakfast,
      hasActiveLunch: hasActiveLunch ?? this.hasActiveLunch,
      breakfastPlanStartDate:
          breakfastPlanStartDate ?? this.breakfastPlanStartDate,
      breakfastPlanEndDate: breakfastPlanEndDate ?? this.breakfastPlanEndDate,
      lunchPlanStartDate: lunchPlanStartDate ?? this.lunchPlanStartDate,
      lunchPlanEndDate: lunchPlanEndDate ?? this.lunchPlanEndDate,
      breakfastPreference: breakfastPreference ?? this.breakfastPreference,
      lunchPreference: lunchPreference ?? this.lunchPreference,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      breakfastSelectedWeekdays:
          breakfastSelectedWeekdays ?? this.breakfastSelectedWeekdays,
      lunchSelectedWeekdays:
          lunchSelectedWeekdays ?? this.lunchSelectedWeekdays,
    );
  }

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schoolName': schoolName,
      'className': className,
      'division': division,
      'floor': floor,
      'allergies': allergies,
      'grade': grade,
      'section': section,
      'profileImageUrl': profileImageUrl,
      'mealPlanType': mealPlanType,
      'mealPlanEndDate': mealPlanEndDate?.toIso8601String(),
      'hasActiveBreakfast': hasActiveBreakfast,
      'hasActiveLunch': hasActiveLunch,
      'breakfastPlanStartDate': breakfastPlanStartDate?.toIso8601String(),
      'breakfastPlanEndDate': breakfastPlanEndDate?.toIso8601String(),
      'lunchPlanStartDate': lunchPlanStartDate?.toIso8601String(),
      'lunchPlanEndDate': lunchPlanEndDate?.toIso8601String(),
      'breakfastPreference': breakfastPreference,
      'lunchPreference': lunchPreference,
      'selectedWeekdays': selectedWeekdays,
      'breakfastSelectedWeekdays': breakfastSelectedWeekdays,
      'lunchSelectedWeekdays': lunchSelectedWeekdays,
    };
  }

  // Create a Student from JSON data
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolName: json['schoolName'] as String,
      className: json['className'] as String,
      division: json['division'] as String,
      floor: json['floor'] as String,
      allergies: json['allergies'] as String,
      grade: json['grade'] as String,
      section: json['section'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      mealPlanType: json['mealPlanType'] as String?,
      mealPlanEndDate: json['mealPlanEndDate'] != null
          ? DateTime.parse(json['mealPlanEndDate'] as String)
          : null,
      hasActiveBreakfast: json['hasActiveBreakfast'] as bool? ?? false,
      hasActiveLunch: json['hasActiveLunch'] as bool? ?? false,
      breakfastPlanStartDate: json['breakfastPlanStartDate'] != null
          ? DateTime.parse(json['breakfastPlanStartDate'] as String)
          : null,
      breakfastPlanEndDate: json['breakfastPlanEndDate'] != null
          ? DateTime.parse(json['breakfastPlanEndDate'] as String)
          : null,
      lunchPlanStartDate: json['lunchPlanStartDate'] != null
          ? DateTime.parse(json['lunchPlanStartDate'] as String)
          : null,
      lunchPlanEndDate: json['lunchPlanEndDate'] != null
          ? DateTime.parse(json['lunchPlanEndDate'] as String)
          : null,
      breakfastPreference: json['breakfastPreference'] as String?,
      lunchPreference: json['lunchPreference'] as String?,
      selectedWeekdays: json['selectedWeekdays'] != null
          ? List<int>.from(json['selectedWeekdays'] as List)
          : null,
      breakfastSelectedWeekdays: json['breakfastSelectedWeekdays'] != null
          ? List<int>.from(json['breakfastSelectedWeekdays'] as List)
          : null,
      lunchSelectedWeekdays: json['lunchSelectedWeekdays'] != null
          ? List<int>.from(json['lunchSelectedWeekdays'] as List)
          : null,
    );
  }

  // Convert a list of students to JSON
  static List<Map<String, dynamic>> studentListToJson(List<Student> students) {
    return students.map((student) => student.toJson()).toList();
  }

  // Create a list of students from JSON data
  static List<Student> studentListFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Student.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Override toString for better logging
  @override
  String toString() {
    String activePlans = '';
    if (hasActiveBreakfast && hasActiveLunch) {
      activePlans = 'B+L';
    } else if (hasActiveBreakfast) {
      activePlans = 'B';
    } else if (hasActiveLunch) {
      activePlans = 'L';
    } else {
      activePlans = 'None';
    }

    return 'Student(id: $id, name: $name, plans: $activePlans)';
  }
}
