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
    log("EventBus: Firing meal cancelled event - ${event.subscriptionId} on ${event.date}");
    _mealCancelledController.add(event);
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

  MealCancelledEvent(this.subscriptionId, this.date,
      {this.shouldNavigateToTab = true});
}

/// Global instance for easy access
final eventBus = EventBusService();
