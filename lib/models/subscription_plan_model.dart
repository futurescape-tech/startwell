import 'package:intl/intl.dart';

class SubscriptionPlanModel {
  final String planType;
  final dynamic deliveryMode; // Can be String or List<String>
  final DateTime startDate;
  final DateTime endDate;

  SubscriptionPlanModel({
    required this.planType,
    required this.deliveryMode,
    required this.startDate,
    required this.endDate,
  });

  // Check if delivery mode is custom (list of days) or standard (Mon to Fri)
  bool get isCustomDelivery => deliveryMode is List<String>;

  // Format delivery mode for display
  String get formattedDeliveryMode {
    if (isCustomDelivery) {
      final customDays = deliveryMode as List<String>;
      return 'Custom (${customDays.join(', ')})';
    } else {
      return deliveryMode as String;
    }
  }

  // Format dates for display
  String get formattedStartDate => DateFormat('dd MMM yyyy').format(startDate);
  String get formattedEndDate => DateFormat('dd MMM yyyy').format(endDate);

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'planType': planType,
      'deliveryMode': deliveryMode is List
          ? (deliveryMode as List<String>).toList()
          : deliveryMode,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    dynamic deliveryMode = json['deliveryMode'];
    if (deliveryMode is List) {
      deliveryMode = List<String>.from(deliveryMode);
    }

    return SubscriptionPlanModel(
      planType: json['planType'],
      deliveryMode: deliveryMode,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }
}
