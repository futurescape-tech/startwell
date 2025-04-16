import 'dart:async';
import 'dart:developer';

/// Simple event bus to communicate between components
class EventBusService {
  // Singleton instance
  static final EventBusService _instance = EventBusService._internal();
  factory EventBusService() => _instance;
  EventBusService._internal();

  // Stream controllers for different event types
  final StreamController<MealCancelledEvent> _mealCancelledController =
      StreamController<MealCancelledEvent>.broadcast();

  // Event streams
  Stream<MealCancelledEvent> get onMealCancelled =>
      _mealCancelledController.stream;

  // Fire events
  void fireMealCancelled(MealCancelledEvent event) {
    log("cancel meal flow: Firing meal cancelled event - subscription: ${event.subscriptionId}, date: ${event.date}");
    _mealCancelledController.add(event);
    log("cancel meal flow: Event dispatched to ${_mealCancelledController.hasListener ? 'active listeners' : 'no listeners'}");
  }

  // Dispose resources
  void dispose() {
    _mealCancelledController.close();
  }
}

/// Event for when a meal is cancelled
class MealCancelledEvent {
  final String subscriptionId;
  final DateTime date;
  final String? studentId;
  final bool shouldNavigateToTab;

  // Add fields for the cancelled meal details
  final String mealName;
  final String studentName;
  final DateTime cancellationTimestamp;
  final String reason;

  MealCancelledEvent(
    this.subscriptionId,
    this.date, {
    this.studentId,
    this.shouldNavigateToTab = false,
    // Add required parameters for the new fields
    required this.mealName,
    required this.studentName,
    required this.cancellationTimestamp,
    required this.reason,
  });

  @override
  String toString() {
    return 'MealCancelledEvent(subscriptionId: $subscriptionId, date: $date, studentId: $studentId, navigate: $shouldNavigateToTab, mealName: $mealName)';
  }
}

/// Global instance for easy access
final eventBus = EventBusService();
