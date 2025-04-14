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
  final bool shouldNavigateToTab;
  final String? studentId;

  MealCancelledEvent(this.subscriptionId, this.date,
      {this.shouldNavigateToTab = true, this.studentId});

  @override
  String toString() =>
      'MealCancelledEvent(subscriptionId: $subscriptionId, date: $date, studentId: ${studentId ?? 'unknown'}, shouldNavigateToTab: $shouldNavigateToTab)';
}

/// Global instance for easy access
final eventBus = EventBusService();
