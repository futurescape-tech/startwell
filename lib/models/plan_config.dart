/// Configuration for a student's meal plan
class PlanConfig {
  String mealType; // 'breakfast', 'lunch', or 'express'
  bool isCustomPlan;
  List<bool> selectedWeekdays;
  DateTime startDate;
  DateTime endDate;
  List<DateTime> mealDates;
  double totalAmount;
  bool isExpressOrder;
  String studentId;

  PlanConfig({
    required this.mealType,
    required this.isCustomPlan,
    required this.selectedWeekdays,
    required this.startDate,
    required this.endDate,
    required this.mealDates,
    required this.totalAmount,
    required this.isExpressOrder,
    required this.studentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'isCustomPlan': isCustomPlan,
      'selectedWeekdays': selectedWeekdays,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'mealDates': mealDates.map((date) => date.toIso8601String()).toList(),
      'totalAmount': totalAmount,
      'isExpressOrder': isExpressOrder,
      'studentId': studentId,
    };
  }

  factory PlanConfig.fromJson(Map<String, dynamic> json) {
    return PlanConfig(
      mealType: json['mealType'],
      isCustomPlan: json['isCustomPlan'],
      selectedWeekdays: List<bool>.from(json['selectedWeekdays']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      mealDates: (json['mealDates'] as List<dynamic>?)
              ?.map((dateStr) => DateTime.parse(dateStr.toString()))
              .toList() ??
          [],
      totalAmount: json['totalAmount'],
      isExpressOrder: json['isExpressOrder'],
      studentId: json['studentId'],
    );
  }

  PlanConfig copyWith({
    String? mealType,
    bool? isCustomPlan,
    List<bool>? selectedWeekdays,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? mealDates,
    double? totalAmount,
    bool? isExpressOrder,
    String? studentId,
  }) {
    return PlanConfig(
      mealType: mealType ?? this.mealType,
      isCustomPlan: isCustomPlan ?? this.isCustomPlan,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mealDates: mealDates ?? this.mealDates,
      totalAmount: totalAmount ?? this.totalAmount,
      isExpressOrder: isExpressOrder ?? this.isExpressOrder,
      studentId: studentId ?? this.studentId,
    );
  }
}
