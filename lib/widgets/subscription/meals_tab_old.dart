// import 'dart:developer';
// import 'dart:developer' as dev;

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:startwell/screens/meal_plan_screen.dart';
// import 'package:startwell/services/event_bus_service.dart';
// import 'package:startwell/themes/app_theme.dart';
// import 'package:startwell/widgets/subscription/meal_card.dart';
// import 'package:intl/intl.dart';
// import 'package:startwell/services/meal_service.dart';
// import 'package:startwell/services/student_profile_service.dart';
// import 'package:startwell/models/student_model.dart';
// import 'package:startwell/models/subscription_model.dart';
// import 'package:startwell/screens/my_subscription_screen.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'dart:math' as math;

// class UpcomingMealsTab extends StatefulWidget {
//   final String? selectedStudentId;
//   final DateTime? startDate;
//   final DateTime? endDate;

//   const UpcomingMealsTab({
//     Key? key,
//     this.selectedStudentId,
//     this.startDate,
//     this.endDate,
//   }) : super(key: key);

//   @override
//   State<UpcomingMealsTab> createState() => _UpcomingMealsTabState();
// }

// // Class to store meal data for calendar view
// class MealData {
//   final String studentName;
//   final String name;
//   final String planType;
//   final List<String> items;
//   final String studentId;
//   final String subscriptionId;
//   String status; // Scheduled / Swapped
//   final Subscription subscription;
//   final bool canSwap;
//   final DateTime date;

//   MealData({
//     required this.studentName,
//     required this.name,
//     required this.planType,
//     required this.items,
//     required this.status,
//     required this.subscription,
//     required this.canSwap,
//     required this.date,
//     required this.studentId,
//     required this.subscriptionId,
//   });

//   // Helper to check if this is an express plan (no swap allowed)
//   bool get isExpressPlan => subscription.planType == 'express';

//   // Override toString for better logging
//   @override
//   String toString() {
//     return 'MealData(student: $studentName, meal: $name, type: $planType, status: $status, date: ${DateFormat('yyyy-MM-dd').format(date)}, canSwap: $canSwap)';
//   }
// }

// class _UpcomingMealsTabState extends State<UpcomingMealsTab> {
//   bool _isCalendarView = false;
//   bool _isLoading = true;
//   final MealService _mealService = MealService();
//   final StudentProfileService _studentProfileService = StudentProfileService();
//   final SubscriptionService _subscriptionService = SubscriptionService();

//   List<Subscription> _activeSubscriptions = [];
//   String? _selectedStudentId;
//   List<Student> _studentsWithMealPlans = [];
//   List<Map<String, dynamic>> _allScheduledMeals = [];

//   // Calendar view variables
//   DateTime _focusedDay = DateTime.now();
//   DateTime _selectedDay = DateTime.now();
//   Map<DateTime, List<MealData>> _mealsMap = {};
//   List<MealData> _selectedDateMeals = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadStudentsWithMealPlans();
//   }

//   // Get the earliest subscription start date
//   DateTime _getEarliestSubscriptionStartDate() {
//     if (_activeSubscriptions.isEmpty) {
//       return DateTime.now();
//     }

//     DateTime earliestDate = _activeSubscriptions.first.startDate;
//     for (final subscription in _activeSubscriptions) {
//       if (subscription.startDate.isBefore(earliestDate)) {
//         earliestDate = subscription.startDate;
//       }
//     }

//     // If the earliest date is in the past, use today
//     final today = DateTime.now();
//     if (earliestDate.isBefore(today)) {
//       return today;
//     }

//     return earliestDate;
//   }

//   // Get the latest subscription end date
//   DateTime _getLatestSubscriptionEndDate() {
//     if (_activeSubscriptions.isEmpty) {
//       // Default to 1 year from now if no active subscriptions
//       return DateTime.now().add(const Duration(days: 365));
//     }

//     DateTime latestDate = _activeSubscriptions.first.endDate;
//     for (final subscription in _activeSubscriptions) {
//       if (subscription.endDate.isAfter(latestDate)) {
//         latestDate = subscription.endDate;
//       }
//     }

//     // Add 30 days buffer for better UX
//     return latestDate.add(const Duration(days: 30));
//   }

//   // Ensure focused day is valid and within range
//   void _ensureValidFocusedDay() {
//     final DateTime firstDay = _getEarliestSubscriptionStartDate();
//     final DateTime lastDay = _getLatestSubscriptionEndDate();

//     // Add debug logging
//     log('[Calendar Init] firstDay: ${DateFormat('yyyy-MM-dd').format(firstDay)}');
//     log('[Calendar Init] lastDay: ${DateFormat('yyyy-MM-dd').format(lastDay)}');
//     log('[Calendar Init] original focusedDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');

//     // Ensure focusedDay is not before firstDay
//     if (_focusedDay.isBefore(firstDay)) {
//       _focusedDay = firstDay;
//       log('[Calendar Init] focusedDay adjusted to firstDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');
//     }

//     // Ensure focusedDay is not after lastDay
//     if (_focusedDay.isAfter(lastDay)) {
//       _focusedDay = lastDay;
//       log('[Calendar Init] focusedDay adjusted to lastDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');
//     }

//     // Ensure selectedDay matches focusedDay if it's outside range
//     if (_selectedDay.isBefore(firstDay) || _selectedDay.isAfter(lastDay)) {
//       _selectedDay = _focusedDay;
//       log('[Calendar Init] selectedDay adjusted to match focusedDay: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}');
//     }
//   }

//   Future<void> _loadStudentsWithMealPlans() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Get students with active meal plans
//       final List<String> studentIds =
//           await _mealService.getStudentsWithMealPlans();
//       final List<Student> students =
//           await _studentProfileService.getStudentProfiles();

//       log("Students with meal plans: ${students.length}");

//       //print list of students
//       for (final student in students) {
//         log("Student List: ${student.name} ${student.id}");
//       }

//       _studentsWithMealPlans =
//           students.where((student) => studentIds.contains(student.id)).toList();

//       if (_studentsWithMealPlans.isNotEmpty) {
//         // If a specific student ID was passed, use it
//         if (widget.selectedStudentId != null &&
//             _studentsWithMealPlans
//                 .any((s) => s.id == widget.selectedStudentId)) {
//           _selectedStudentId = widget.selectedStudentId;
//         } else {
//           // Otherwise default to the first student
//           _selectedStudentId = _studentsWithMealPlans.first.id;
//         }

//         await _loadSubscriptionsForStudent(_selectedStudentId!,
//             skipCancelled: true);
//       } else {
//         _activeSubscriptions = [];
//       }
//     } catch (e) {
//       print('Error loading students with meal plans: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadSubscriptionsForStudent(String studentId,
//       {bool skipCancelled = false}) async {
//     log('[CancelMealFlow] UpcomingMealsTab: Starting _loadSubscriptionsForStudent for $studentId');
//     setState(() {
//       _isLoading = true;
//     });
//     log("Loading subscriptions for student ID: $studentId");

//     // Improved logging for collections
//     if (_activeSubscriptions.isNotEmpty) {
//       log("Current active subscriptions count: ${_activeSubscriptions.length}");
//       for (int i = 0; i < _activeSubscriptions.length; i++) {
//         log("Active subscription[$i]: ${_activeSubscriptions[i]}");
//       }
//     } else {
//       log("No active subscriptions currently loaded");
//     }

//     if (_studentsWithMealPlans.isNotEmpty) {
//       log("Students with meal plans count: ${_studentsWithMealPlans.length}");
//       for (int i = 0; i < _studentsWithMealPlans.length; i++) {
//         log("Student[$i]: ${_studentsWithMealPlans[i]}");
//       }
//     } else {
//       log("No students with meal plans found");
//     }

//     log("Selected student ID: $_selectedStudentId");

//     // Log summary of meal map
//     if (_mealsMap.isNotEmpty) {
//       log("Current meal map entries: ${_mealsMap.length}");
//       // Log first 3 entries at most
//       int count = 0;
//       _mealsMap.forEach((date, meals) {
//         if (count < 3) {
//           log("Meal map[${DateFormat('yyyy-MM-dd').format(date)}]: ${meals.length} meals");
//           count++;
//         }
//       });
//     } else {
//       log("Meal map is empty");
//     }

//     if (_selectedDateMeals.isNotEmpty) {
//       log("Selected date meals count: ${_selectedDateMeals.length}");
//     } else {
//       log("No meals for selected date");
//     }

//     try {
//       // Get active subscriptions based on the student's actual meal plans
//       _activeSubscriptions = await _subscriptionService
//           .getActiveSubscriptionsForStudent(studentId);

//       // Debug log for Express plans
//       final expressPlans = _activeSubscriptions
//           .where((sub) => sub.planType == 'express')
//           .toList();
//       if (expressPlans.isNotEmpty) {
//         log("📱 FOUND EXPRESS PLANS: ${expressPlans.length}");
//         for (final plan in expressPlans) {
//           log("  📱 Express Plan ID: ${plan.id}");
//           log("  📱 Express Plan Date: ${DateFormat('yyyy-MM-dd').format(plan.startDate)}");
//           SubscriptionService.logSubscriptionDetails(plan);
//         }
//       } else {
//         log("📱 NO EXPRESS PLANS FOUND for student $studentId");
//       }

//       // Generate meal map for calendar view
//       _generateMealMap();

//       // Ensure focused day is valid before showing calendar
//       _ensureValidFocusedDay();
//     } catch (e) {
//       print('Error loading subscriptions: $e');
//       _activeSubscriptions = [];
//       _mealsMap = {};
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   // Generate a map of dates to meal data for the calendar view
//   void _generateMealMap() {
//     _mealsMap = {};

//     for (final subscription in _activeSubscriptions) {
//       // Find the correct student for this subscription
//       final student = _studentsWithMealPlans.firstWhere(
//         (s) => s.id == subscription.studentId,
//         orElse: () => _studentsWithMealPlans.first,
//       );

//       // Get all the scheduled dates for this subscription
//       log("=== Generating schedule dates for subscription ===");
//       log("Subscription ID: ${subscription.id}");
//       log("Student ID: ${subscription.studentId}, Student name: ${student.name}");
//       log("Plan Type: ${subscription.planType}");
//       log("Start Date: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)}");
//       log("End Date: ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
//       log("Selected Weekdays: ${subscription.selectedWeekdays}");
//       log("Custom Plan: ${subscription.selectedWeekdays.isNotEmpty && subscription.selectedWeekdays.length < 5}");

//       // Log detailed subscription info
//       SubscriptionService.logSubscriptionDetails(subscription);

//       // Debug log for subscription duration
//       log("Subscription duration: ${subscription.duration}");
//       log("Duration display name: ${subscription.durationDisplayName}");
//       log("Days between start and end: ${subscription.endDate.difference(subscription.startDate).inDays}");

//       // Generate scheduled dates specifically for this subscription's weekdays
//       final scheduledDates = _generateScheduleDates(
//         subscription.startDate,
//         subscription.endDate,
//         subscription.selectedWeekdays,
//         subscription.planType,
//       );

//       log("Total Scheduled Dates: ${scheduledDates.length}");
//       if (scheduledDates.isNotEmpty) {
//         log("First Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.first)}");
//         log("Last Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.last)}");
//       }
//       log("=== End of scheduled dates generation ===");

//       // Create a MealData object for each date
//       for (final date in scheduledDates) {
//         final normalized = DateTime(date.year, date.month, date.day);

//         // Skip dates in the past, but always include Express plans
//         if (normalized.isBefore(DateTime.now()) &&
//             !normalized.isAtSameMomentAs(DateTime.now()) &&
//             subscription.planType != 'express') {
//           continue;
//         }

//         // Check if swap is allowed for this date
//         final bool canSwap = _isSwapAllowed(date, subscription.planType);

//         // Create a MealData object for this date
//         final mealData = MealData(
//           studentName: student.name,
//           name: subscription.getMealNameForDate(date),
//           planType: _getFormattedPlanType(subscription),
//           items: subscription.getMealItems(),
//           status:
//               subscription.getMealNameForDate(date) != subscription.mealItemName
//                   ? "Swapped"
//                   : "Scheduled",
//           subscription: subscription,
//           canSwap: canSwap,
//           date: date,
//           studentId: student.id,
//           subscriptionId: subscription.id,
//         );

//         // Add to the map
//         if (_mealsMap.containsKey(normalized)) {
//           _mealsMap[normalized]!.add(mealData);
//         } else {
//           _mealsMap[normalized] = [mealData];
//         }
//       }
//     }

//     // Update the selected day's meals
//     _updateSelectedDayMeals();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildViewControls(),
//         if (_isLoading)
//           const Expanded(
//             child: Center(
//               child: CircularProgressIndicator(),
//             ),
//           )
//         else
//           Expanded(
//             child: _studentsWithMealPlans.isEmpty
//                 ? _buildNoSubscriptionsView()
//                 : _isCalendarView
//                     ? _buildCalendarView() // Already wrapped in SingleChildScrollView
//                     : _buildListView(),
//           ),
//       ],
//     );
//   }

//   Widget _buildViewControls() {
//     return Column(
//       children: [
//         if (_studentsWithMealPlans.isNotEmpty)
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: DropdownButtonFormField<String>(
//               decoration: InputDecoration(
//                 labelText: 'Select Student',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//               value: _selectedStudentId,
//               items: _studentsWithMealPlans.map((student) {
//                 return DropdownMenuItem<String>(
//                   value: student.id,
//                   child: Text(student.name),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null && value != _selectedStudentId) {
//                   setState(() {
//                     _selectedStudentId = value;
//                   });
//                   _loadSubscriptionsForStudent(value, skipCancelled: true);
//                 }
//               },
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Upcoming Meals',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: AppTheme.textDark,
//                 ),
//               ),
//               ToggleButtons(
//                 isSelected: [!_isCalendarView, _isCalendarView],
//                 onPressed: (index) {
//                   setState(() {
//                     _isCalendarView = index == 1;
//                   });
//                 },
//                 borderRadius: BorderRadius.circular(8),
//                 selectedColor: Colors.white,
//                 fillColor: AppTheme.purple,
//                 color: AppTheme.textMedium,
//                 constraints: const BoxConstraints(
//                   minHeight: 36,
//                   minWidth: 60,
//                 ),
//                 children: const [
//                   Icon(Icons.list),
//                   Icon(Icons.calendar_today),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildListView() {
//     // Check for errors first
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     // Check if we have active subscriptions
//     if (_activeSubscriptions.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.restaurant_menu,
//               size: 48,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "No active subscriptions for this student",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Subscribe to a meal plan to see upcoming meals here",
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppTheme.textMedium,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     // Generate a list of all scheduled meal dates across all active subscriptions
//     List<Map<String, dynamic>> allScheduledMeals = [];

//     for (final subscription in _activeSubscriptions) {
//       // Calculate days between start and end dates
//       final int days =
//           subscription.endDate.difference(subscription.startDate).inDays;

//       // For each day within range, check if it matches subscription weekdays
//       for (int i = 0; i <= days; i++) {
//         final DateTime date = subscription.startDate.add(Duration(days: i));
//         final DateTime today = DateTime.now();
//         final DateTime todayNormalized =
//             DateTime(today.year, today.month, today.day);

//         // Skip dates that are in the past
//         if (date.isBefore(todayNormalized)) {
//           continue;
//         }

//         // Skip weekends if this is a regular school day subscription
//         if (subscription.selectedWeekdays.isEmpty &&
//             (date.weekday == DateTime.saturday ||
//                 date.weekday == DateTime.sunday)) {
//           continue;
//         }

//         // Skip days that don't match selected weekdays for custom plans
//         if (subscription.selectedWeekdays.isNotEmpty &&
//             !subscription.selectedWeekdays.contains(date.weekday)) {
//           continue;
//         }

//         // Get the student for this subscription
//         final student = _studentsWithMealPlans.firstWhere(
//             (student) => student.id == subscription.studentId,
//             orElse: () => Student(
//                   id: "unknown",
//                   name: "Unknown Student",
//                   schoolName: "",
//                   className: "",
//                   floor: "",
//                   division: "",
//                   allergies: "",
//                   schoolAddress: "",
//                   profileImageUrl: "",
//                   grade: "",
//                   section: "",
//                 ));

//         // Check if swap allowed for this date
//         final bool canSwap = _isSwapAllowed(date, subscription.planType);

//         // Add to scheduled meals
//         allScheduledMeals.add({
//           'date': date,
//           'subscription': subscription,
//           'student': student,
//           'canSwap': canSwap,
//         });
//       }
//     }

//     // Sort by date
//     allScheduledMeals.sort((a, b) {
//       final DateTime dateA = a['date'] as DateTime;
//       final DateTime dateB = b['date'] as DateTime;
//       return dateA.compareTo(dateB);
//     });

//     // No meals to display
//     if (allScheduledMeals.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.calendar_today,
//               size: 48,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "No upcoming meals found",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Check back later for upcoming meals",
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppTheme.textMedium,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: () async {
//         if (_selectedStudentId != null) {
//           await _loadSubscriptionsForStudent(_selectedStudentId!);
//         }
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         itemCount: allScheduledMeals.length,
//         itemBuilder: (context, index) {
//           final mealData = allScheduledMeals[index];
//           final date = mealData['date'] as DateTime;
//           final subscription = mealData['subscription'] as Subscription;
//           final student = mealData['student'] as Student;
//           final canSwap = mealData['canSwap'] as bool;
//           final isBreakfast = subscription.planType == 'breakfast';

//           // Define meal status - this would typically come from the subscription data
//           String mealStatus = "Scheduled"; // Default status

//           // Display a date header if this is the first meal of the day or the first item
//           final bool showDateHeader = index == 0 ||
//               (index > 0 &&
//                   !isSameDay(
//                       date, allScheduledMeals[index - 1]['date'] as DateTime));

//           // Create a MealData object to match calendar view's pattern
//           final mealDataObj = MealData(
//             studentName: student.name,
//             name: subscription.getMealNameForDate(date),
//             planType: _getFormattedPlanType(subscription),
//             items: subscription.getMealItems(),
//             status: "Scheduled",
//             subscription: subscription,
//             canSwap: canSwap,
//             date: date,
//             studentId: student.id,
//             subscriptionId: subscription.id,
//           );

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Date header
//               if (showDateHeader)
//                 Padding(
//                   padding:
//                       const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         DateFormat('EEEE, MMMM d, yyyy').format(date),
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: AppTheme.textDark,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${mealStatus == "Scheduled" ? "Upcoming" : mealStatus} Meal${isBreakfast ? " (Breakfast)" : " (Lunch)"}',
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           color: AppTheme.textMedium,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Meal Card
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: isBreakfast
//                                   ? AppTheme.purple.withOpacity(0.1)
//                                   : Colors.green.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               isBreakfast
//                                   ? Icons.free_breakfast
//                                   : Icons.lunch_dining,
//                               color:
//                                   isBreakfast ? AppTheme.purple : Colors.green,
//                               size: 24,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   subscription.mealItemName,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   student.name,
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 14,
//                                     color: AppTheme.textMedium,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color:
//                                   _getStatusColor(mealStatus).withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Text(
//                               mealStatus,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: _getStatusColor(mealStatus),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       const Divider(),
//                       const SizedBox(height: 16),
//                       _buildDetailRow(Icons.restaurant_menu, "Meal Item",
//                           subscription.mealItemName),
//                       const SizedBox(height: 8),
//                       _buildDetailRow(
//                         Icons.calendar_today,
//                         "Subscription Plan",
//                         mealDataObj.planType,
//                       ),
//                       const SizedBox(height: 8),
//                       if (subscription.selectedWeekdays.isNotEmpty &&
//                           subscription.selectedWeekdays.length < 5)
//                         _buildDetailRow(
//                           Icons.today,
//                           "Delivery Days",
//                           _formatWeekdays(subscription.selectedWeekdays),
//                         ),
//                       if (subscription.selectedWeekdays.isNotEmpty &&
//                           subscription.selectedWeekdays.length < 5)
//                         const SizedBox(height: 8),
//                       _buildDetailRow(Icons.event, "Scheduled Date",
//                           DateFormat('EEE dd, MMM yyyy').format(date)),
//                       const SizedBox(height: 8),
//                       _buildDetailRow(Icons.lunch_dining, "Items",
//                           subscription.getMealItems().join(", ")),

//                       const SizedBox(height: 20),

//                       // Action buttons - Only show for non-express plans
//                       if (!subscription.isExpressPlan) ...[
//                         Padding(
//                           padding: const EdgeInsets.only(top: 16),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               // SWAP BUTTON
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: mealDataObj.canSwap
//                                       ? () {
//                                           log("swap flow: Swap button tapped in list view ${mealDataObj.name}");
//                                           log("swap flow: Meal data: $mealDataObj");
//                                           _showSwapMealBottomSheetWithMealData(
//                                               mealDataObj);
//                                         }
//                                       : null,
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: mealDataObj.canSwap
//                                           ? Colors.blue.withOpacity(0.2)
//                                           : Colors.grey.withOpacity(0.2),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.swap_horiz,
//                                           color: mealDataObj.canSwap
//                                               ? Colors.blue
//                                               : Colors.grey,
//                                           size: 20,
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           "Swap",
//                                           style: GoogleFonts.poppins(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w500,
//                                             color: mealDataObj.canSwap
//                                                 ? Colors.blue
//                                                 : Colors.grey,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Messaging for disabled buttons
//                         if (!mealDataObj.canSwap)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8, left: 4),
//                             child: Text(
//                               "You can only make changes until 11:59 PM the previous day.",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade600,
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ),
//                       ] else
//                         // Message for Express Plans
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8, left: 4),
//                           child: Text(
//                             "Actions not allowed for Express 1-Day plans.",
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // Helper to check if two dates are the same day
//   bool isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   Widget _buildCalendarView() {
//     // Calendar view implementation
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     // Check if we have active subscriptions
//     if (_activeSubscriptions.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.restaurant_menu,
//               size: 48,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "No active subscriptions for this student",
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Subscribe to a meal plan to see upcoming meals here",
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppTheme.textMedium,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     // Log calendar parameters for debugging
//     log('[Calendar Build] Setting up unrestricted calendar navigation');

//     // Define a very wide date range for unlimited navigation
//     final firstDay = DateTime(2020);
//     final lastDay = DateTime(2100);

//     // Use today's date as focused day if current focused day is invalid
//     final today = DateTime.now();
//     final focusedDay = _focusedDay;

//     // Wrap the entire content in a SingleChildScrollView for full scrollability
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       child: Column(
//         children: [
//           // Calendar
//           Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TableCalendar(
//                 firstDay: firstDay,
//                 lastDay: lastDay,
//                 focusedDay: focusedDay,
//                 selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                 calendarFormat: CalendarFormat.month,
//                 // Enable only today and future dates
//                 enabledDayPredicate: (date) => !date.isBefore(DateTime(
//                     DateTime.now().year,
//                     DateTime.now().month,
//                     DateTime.now().day)),
//                 eventLoader: (day) {
//                   // Use our new event function to show both meal and cancelled markers
//                   return _getEventsForDay(day);
//                 },
//                 onDaySelected: (selectedDay, focusedDay) {
//                   setState(() {
//                     _selectedDay = selectedDay;
//                     _focusedDay = focusedDay;
//                     _updateSelectedDayMeals();

//                     // Show toast if no meals are scheduled for this date
//                     if (_selectedDateMeals.isEmpty) {
//                       _showSnackBar(
//                         message:
//                             'No meals scheduled for ${DateFormat('EEE dd, MMM yyyy').format(selectedDay)}',
//                         backgroundColor: Colors.orange,
//                       );
//                     }
//                   });
//                 },
//                 onPageChanged: (focusedDay) {
//                   setState(() {
//                     _focusedDay = focusedDay;
//                   });
//                 },
//                 calendarStyle: CalendarStyle(
//                   todayDecoration: BoxDecoration(
//                     color: AppTheme.purple.withOpacity(0.5),
//                     shape: BoxShape.circle,
//                   ),
//                   selectedDecoration: const BoxDecoration(
//                     color: AppTheme.purple,
//                     shape: BoxShape.circle,
//                   ),
//                   markerDecoration: const BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.circle,
//                   ),
//                   // Grey out disabled dates
//                   disabledTextStyle: GoogleFonts.poppins(
//                     color: Colors.grey.shade400,
//                   ),
//                   // Grey out dates outside subscription periods
//                   outsideTextStyle: GoogleFonts.poppins(
//                     color: Colors.grey.shade300,
//                   ),
//                   // Make weekends slightly different to distinguish them
//                   weekendTextStyle: GoogleFonts.poppins(
//                     color: Colors.redAccent.withOpacity(0.7),
//                   ),
//                 ),
//                 headerStyle: HeaderStyle(
//                   formatButtonVisible: false,
//                   titleCentered: true,
//                   titleTextStyle: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.textDark,
//                   ),
//                   leftChevronIcon: Icon(
//                     Icons.chevron_left,
//                     color: AppTheme.purple,
//                     size: 28,
//                   ),
//                   rightChevronIcon: Icon(
//                     Icons.chevron_right,
//                     color: AppTheme.purple,
//                     size: 28,
//                   ),
//                   headerPadding: const EdgeInsets.symmetric(vertical: 10),
//                 ),
//                 calendarBuilders: CalendarBuilders(
//                   // Add disabledBuilder for past dates
//                   disabledBuilder: (context, date, _) => Center(
//                     child: Text(
//                       '${date.day}',
//                       style: GoogleFonts.poppins(
//                         color: Colors.grey.shade400,
//                       ),
//                     ),
//                   ),
//                   markerBuilder: (context, date, events) {
//                     if (events.isEmpty) return const SizedBox.shrink();

//                     // Use our custom marker builder for showing meal and cancelled markers
//                     return Positioned(
//                       bottom: 1,
//                       child:
//                           _buildCalendarMarker(events as List<dynamic>, date),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),

//           // Legend for calendar markers
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Legend:',
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppTheme.textDark,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildLegendItem(
//                             AppTheme.purple,
//                             'Breakfast',
//                           ),
//                         ),
//                         Expanded(
//                           child: _buildLegendItem(
//                             Colors.green,
//                             'Lunch',
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildLegendItem(
//                             Colors.blueAccent,
//                             'Express 1-Day',
//                           ),
//                         ),
//                         Expanded(
//                           child: _buildLegendItem(
//                             Colors.orange,
//                             'Swapped',
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildLegendItem(
//                             Colors.red,
//                             'Cancelled',
//                           ),
//                         ),
//                         Expanded(
//                           child: Container(), // Empty to balance the row
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Meal details for selected day - No longer in an Expanded widget
//           _selectedDateMeals.isEmpty
//               ? _buildNoMealsForSelectedDay()
//               : _buildMealDetailsForSelectedDayScrollable(),

//           // Add bottom padding to ensure content isn't cut off
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   // Modified version of _buildMealDetailsForSelectedDay that works within a SingleChildScrollView
//   Widget _buildMealDetailsForSelectedDayScrollable() {
//     // Sort meals by type (breakfast first, then lunch)
//     final sortedMeals = List<MealData>.from(_selectedDateMeals)
//       ..sort((a, b) {
//         if (a.subscription.planType == 'breakfast' &&
//             b.subscription.planType != 'breakfast') {
//           return -1;
//         } else if (a.subscription.planType != 'breakfast' &&
//             b.subscription.planType == 'breakfast') {
//           return 1;
//         } else {
//           return 0;
//         }
//       });

//     return Column(
//       children: [
//         // Meal count header
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               Text(
//                 'Meals for ${DateFormat('EEE, MMM d').format(_selectedDay)}',
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: AppTheme.textDark,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppTheme.purple.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${sortedMeals.length}',
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: AppTheme.purple,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Meal cards
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           itemCount: sortedMeals.length,
//           itemBuilder: (context, index) {
//             final meal = sortedMeals[index];
//             final bool isBreakfast = meal.subscription.planType == 'breakfast';
//             final bool isExpressPlan = meal.isExpressPlan;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 16, top: 8),
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header with status pill
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               isBreakfast
//                                   ? Icons.breakfast_dining
//                                   : Icons.lunch_dining,
//                               color: isBreakfast
//                                   ? AppTheme.purple
//                                   : Colors.green.shade700,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               isBreakfast ? "Breakfast" : "Lunch",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 color: isBreakfast
//                                     ? AppTheme.purple
//                                     : Colors.green.shade700,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Text(
//                             meal.status,
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.green.shade800,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 16),

//                     // Meal details
//                     _buildDetailRow(Icons.person, "Student", meal.studentName),
//                     const SizedBox(height: 8),
//                     _buildDetailRow(
//                         Icons.restaurant_menu, "Meal Item", meal.name),
//                     const SizedBox(height: 8),
//                     _buildDetailRow(
//                       Icons.calendar_today,
//                       "Subscription Plan",
//                       meal.planType,
//                     ),
//                     const SizedBox(height: 8),
//                     if (meal.subscription.selectedWeekdays.isNotEmpty &&
//                         meal.subscription.selectedWeekdays.length < 5)
//                       _buildDetailRow(
//                         Icons.today,
//                         "Delivery Days",
//                         _formatWeekdays(meal.subscription.selectedWeekdays),
//                       ),
//                     if (meal.subscription.selectedWeekdays.isNotEmpty &&
//                         meal.subscription.selectedWeekdays.length < 5)
//                       const SizedBox(height: 8),
//                     _buildDetailRow(Icons.event, "Scheduled Date",
//                         DateFormat('EEE dd, MMM yyyy').format(_selectedDay)),
//                     const SizedBox(height: 8),
//                     _buildDetailRow(
//                         Icons.lunch_dining, "Items", meal.items.join(", ")),

//                     const SizedBox(height: 20),

//                     // Action buttons - Only show for non-express plans
//                     if (!isExpressPlan) ...[
//                       Padding(
//                         padding: const EdgeInsets.only(top: 16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             // SWAP BUTTON
//                             Expanded(
//                               child: GestureDetector(
//                                 onTap: meal.canSwap
//                                     ? () {
//                                         log("swap flow: Swap button tapped in calendar view ${meal.name}");
//                                         log("swap flow: Meal data: $meal");
//                                         _showSwapMealBottomSheetWithMealData(
//                                             meal);
//                                       }
//                                     : null,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 12,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: meal.canSwap
//                                         ? Colors.blue.withOpacity(0.2)
//                                         : Colors.grey.withOpacity(0.2),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.swap_horiz,
//                                         color: meal.canSwap
//                                             ? Colors.blue
//                                             : Colors.grey,
//                                         size: 20,
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Text(
//                                         "Swap",
//                                         style: GoogleFonts.poppins(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w500,
//                                           color: meal.canSwap
//                                               ? Colors.blue
//                                               : Colors.grey,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Messaging for disabled buttons
//                       if (!meal.canSwap)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8, left: 4),
//                           child: Text(
//                             "You can only make changes until 11:59 PM the previous day.",
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                         ),
//                     ] else
//                       // Message for Express Plans
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8, left: 4),
//                         child: Text(
//                           "Actions not allowed for Express 1-Day plans.",
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             color: Colors.grey.shade600,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // Helper method to build legend items
//   Widget _buildLegendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 12,
//             color: AppTheme.textMedium,
//           ),
//         ),
//       ],
//     );
//   }

//   // Build widget when no meals are scheduled for selected day
//   Widget _buildNoMealsForSelectedDay() {
//     return Padding(
//       padding: const EdgeInsets.all(32.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.no_food,
//             size: 48,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "No meals scheduled for ${DateFormat('EEE dd, MMM yyyy').format(_selectedDay)}",
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: AppTheme.textDark,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper to build a detail row for dialogs
//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 18,
//           color: AppTheme.purple,
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppTheme.textDark,
//               ),
//               children: [
//                 TextSpan(
//                   text: "$label: ",
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 TextSpan(
//                   text: value,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNoSubscriptionsView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.restaurant_menu,
//             size: 64,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 24),
//           Text(
//             "No Active Meal Plans",
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: AppTheme.textDark,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Subscribe to a meal plan to see upcoming meals here.",
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: AppTheme.textMedium,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               // Navigate to meal plan screen - index 3 in bottom navigation
//               final navigationState = Navigator.of(context);

//               // Pop until we get to the main screen
//               while (navigationState.canPop()) {
//                 navigationState.pop();
//               }

//               // Navigate to the meal plan tab

//               // MealPlanScreen

//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => const MealPlanScreen(),
//                 ),
//               );

//               // Navigator.of(context).pushReplacementNamed(
//               //   '/',
//               //   arguments: 3, // Meal Plan tab
//               // );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.purple,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: Text(
//               'Browse Meal Plans',
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper method to update meal name after successful swap
//   void _updateMealNameAfterSwap(String subscriptionId, String newMealName) {
//     log("[meal swap flow] Updating meal name after swap for subscription ID: $subscriptionId");
//     log("[meal swap flow] New meal name: $newMealName");

//     bool needsUpdate = false;

//     // Get the swap date - this will be either the calendar selected date or the subscription's next delivery date
//     final DateTime swapDate = _isCalendarView
//         ? _selectedDay
//         : _activeSubscriptions
//             .firstWhere(
//               (s) => s.id == subscriptionId,
//               orElse: () => _activeSubscriptions.first,
//             )
//             .nextDeliveryDate;

//     log("[meal swap logic] Swap is for specific date: ${DateFormat('yyyy-MM-dd').format(swapDate)}");

//     // 1. Update the subscription's swapped meals map
//     final subscription = _activeSubscriptions.firstWhere(
//       (s) => s.id == subscriptionId,
//       orElse: () => _activeSubscriptions.first,
//     );
//     subscription.swapMeal(subscriptionId, newMealName, swapDate);
//     log("[meal swap logic] Updated subscription's swapped meals map");

//     // 2. Update MealData objects for the specific swap date
//     _mealsMap.forEach((date, meals) {
//       final normalizedDate = DateTime(date.year, date.month, date.day);
//       final normalizedSwapDate =
//           DateTime(swapDate.year, swapDate.month, swapDate.day);

//       // Only update meals for the specific date that was swapped
//       if (normalizedDate.isAtSameMomentAs(normalizedSwapDate)) {
//         log("[meal swap logic] Found matching date in _mealsMap: ${DateFormat('yyyy-MM-dd').format(date)}");

//         for (int i = 0; i < meals.length; i++) {
//           if (meals[i].subscription.id == subscriptionId) {
//             log("[meal swap logic] Updating meal in _mealsMap for date: ${DateFormat('yyyy-MM-dd').format(date)}");
//             // Create a new MealData with the updated name
//             meals[i] = MealData(
//               studentName: meals[i].studentName,
//               name: newMealName, // Update the name
//               planType: meals[i].planType,
//               items: meals[i].items,
//               status: "Swapped", // Mark as swapped
//               subscription:
//                   meals[i].subscription, // Keep the original subscription
//               canSwap: meals[i].canSwap,
//               date: meals[i].date,
//               studentId: meals[i].studentId, // Add studentId
//               subscriptionId: meals[i].subscriptionId, // Add subscriptionId
//             );
//             needsUpdate = true;
//           }
//         }
//       }
//     });

//     // 3. Update _selectedDateMeals if the selected date is the swap date
//     final normalizedSelectedDate =
//         DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
//     final normalizedSwapDate =
//         DateTime(swapDate.year, swapDate.month, swapDate.day);

//     if (normalizedSelectedDate.isAtSameMomentAs(normalizedSwapDate)) {
//       log("[meal swap logic] Updating _selectedDateMeals for swap date");

//       for (int i = 0; i < _selectedDateMeals.length; i++) {
//         if (_selectedDateMeals[i].subscription.id == subscriptionId) {
//           log("[meal swap logic] Updating meal in _selectedDateMeals");
//           _selectedDateMeals[i] = MealData(
//             studentName: _selectedDateMeals[i].studentName,
//             name: newMealName, // Update the name
//             planType: _selectedDateMeals[i].planType,
//             items: _selectedDateMeals[i].items,
//             status: "Swapped", // Mark as swapped
//             subscription: _selectedDateMeals[i]
//                 .subscription, // Keep the original subscription
//             canSwap: _selectedDateMeals[i].canSwap,
//             date: _selectedDateMeals[i].date,
//             studentId: _selectedDateMeals[i].studentId, // Add studentId
//             subscriptionId:
//                 _selectedDateMeals[i].subscriptionId, // Add subscriptionId
//           );
//           needsUpdate = true;
//         }
//       }
//     }

//     if (needsUpdate) {
//       setState(() {
//         // Trigger UI refresh
//         log("[meal swap logic] Triggering UI refresh with updated meal data");

//         if (_isCalendarView) {
//           // For Calendar View, update the selected day's meals
//           log("[meal swap logic] Refreshing calendar view to update event markers");
//           _updateSelectedDayMeals();
//         } else {
//           // For List View, update the specific meal card
//           log("[meal swap logic] Updating specific meal card in List View");

//           // Find and update the meal in the list view
//           final allScheduledMeals = _generateAllScheduledMeals();
//           final updatedMeals = allScheduledMeals.map((meal) {
//             if (meal['subscription'].id == subscriptionId &&
//                 isSameDay(meal['date'] as DateTime, swapDate)) {
//               return {
//                 ...meal,
//                 'subscription': subscription, // Use the updated subscription
//               };
//             }
//             return meal;
//           }).toList();

//           // Update the list view with the new data
//           setState(() {
//             _allScheduledMeals = updatedMeals;
//           });
//         }
//       });
//     }
//   }

//   // Helper method to generate all scheduled meals for List View
//   List<Map<String, dynamic>> _generateAllScheduledMeals() {
//     List<Map<String, dynamic>> allScheduledMeals = [];

//     for (final subscription in _activeSubscriptions) {
//       // Calculate days between start and end dates
//       final int days =
//           subscription.endDate.difference(subscription.startDate).inDays;

//       // For each day within range, check if it matches subscription weekdays
//       for (int i = 0; i <= days; i++) {
//         final DateTime date = subscription.startDate.add(Duration(days: i));
//         final DateTime today = DateTime.now();
//         final DateTime todayNormalized =
//             DateTime(today.year, today.month, today.day);

//         // Skip dates that are in the past
//         if (date.isBefore(todayNormalized)) {
//           continue;
//         }

//         // Skip weekends if this is a regular school day subscription
//         if (subscription.selectedWeekdays.isEmpty &&
//             (date.weekday == DateTime.saturday ||
//                 date.weekday == DateTime.sunday)) {
//           continue;
//         }

//         // Skip days that don't match selected weekdays for custom plans
//         if (subscription.selectedWeekdays.isNotEmpty &&
//             !subscription.selectedWeekdays.contains(date.weekday)) {
//           continue;
//         }

//         // Get the student for this subscription
//         final student = _studentsWithMealPlans.firstWhere(
//             (student) => student.id == subscription.studentId,
//             orElse: () => Student(
//                   id: "unknown",
//                   name: "Unknown Student",
//                   schoolName: "",
//                   className: "",
//                   floor: "",
//                   division: "",
//                   allergies: "",
//                   schoolAddress: "",
//                   profileImageUrl: "",
//                   grade: "",
//                   section: "",
//                 ));

//         // Check if swap allowed for this date
//         final bool canSwap = _isSwapAllowed(date, subscription.planType);

//         // Add to scheduled meals
//         allScheduledMeals.add({
//           'date': date,
//           'subscription': subscription,
//           'student': student,
//           'canSwap': canSwap,
//         });
//       }
//     }

//     // Sort by date
//     allScheduledMeals.sort((a, b) {
//       final DateTime dateA = a['date'] as DateTime;
//       final DateTime dateB = b['date'] as DateTime;
//       return dateA.compareTo(dateB);
//     });

//     return allScheduledMeals;
//   }

//   // Improved swap meal bottom sheet that uses MealData to ensure date-specific swapping
//   Future<void> _showSwapMealBottomSheetWithMealData(MealData mealData) async {
//     log("swap flow: Start opening swap bottom sheet for ${mealData.name} on ${DateFormat('yyyy-MM-dd').format(mealData.date)}");

//     final subscription = mealData.subscription;
//     final targetDate = mealData.date;

//     // Express plans cannot be swapped
//     if (subscription.planType == 'express') {
//       log("swap flow: Express plan detected, showing error and exiting");
//       _showSnackBar(
//         message: 'Swapping not allowed for Express 1-Day plans',
//         backgroundColor: Colors.redAccent,
//       );
//       return;
//     }

//     if (!mounted) {
//       log("swap flow: Widget not mounted, aborting bottom sheet");
//       return;
//     }

//     // Check if swap is allowed for this date
//     final cutoffDate =
//         DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59)
//             .subtract(const Duration(days: 1));

//     final now = DateTime.now();
//     if (now.isAfter(cutoffDate)) {
//       log("swap flow: Swap window closed for this meal at cutoff: ${cutoffDate.toString()}");
//       _showSnackBar(
//         message: 'Swap window closed for this meal',
//         backgroundColor: Colors.redAccent,
//       );
//       return;
//     }

//     // Generate available options based on meal type
//     final List<Map<String, String>> swapOptions =
//         _getSwapOptionsForMealType(subscription.planType);

//     log("swap flow: Showing modal bottom sheet with ${swapOptions.length} swap options");

//     try {
//       // Use await to properly handle the bottom sheet's lifecycle
//       await showModalBottomSheet(
//         context: context,
//         isScrollControlled: true, // Add this to prevent content overflow issues
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         builder: (BuildContext sheetContext) => StatefulBuilder(
//           builder: (BuildContext context, StateSetter setSheetState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//                 left: 16.0,
//                 right: 16.0,
//                 top: 16.0,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Swap Meal',
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () {
//                           log("swap flow: User closed the swap sheet manually");
//                           Navigator.pop(context);
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Current: ${mealData.name}',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w500,
//                       color: AppTheme.textDark,
//                     ),
//                   ),
//                   Text(
//                     'Date: ${DateFormat('EEE dd, MMM yyyy').format(targetDate)}',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w500,
//                       color: AppTheme.textDark,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Select a new meal to swap with:',
//                     style: GoogleFonts.poppins(
//                       color: AppTheme.textMedium,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Divider(),
//                   // Available meal options for swapping - limit height to prevent overflow
//                   ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxHeight: MediaQuery.of(context).size.height * 0.5,
//                     ),
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: swapOptions.length,
//                       itemBuilder: (context, index) {
//                         final option = swapOptions[index];
//                         // Don't show the current meal as an option
//                         if (option['name'] == mealData.name) {
//                           return const SizedBox.shrink();
//                         }

//                         return ListTile(
//                           leading: const Icon(Icons.food_bank,
//                               color: AppTheme.purple),
//                           title: Text(
//                             option['name'] ?? '',
//                             style: GoogleFonts.poppins(),
//                           ),
//                           subtitle: Text(
//                             option['description'] ?? '',
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: AppTheme.textMedium,
//                             ),
//                           ),
//                           onTap: () async {
//                             log("swap flow: User selected: ${option['name']}");
//                             // Close the bottom sheet first to prevent UI stacking
//                             Navigator.pop(context);

//                             // Ensure we're still mounted
//                             if (!mounted) {
//                               log("swap flow: Widget no longer mounted after selection");
//                               return;
//                             }

//                             // Show loading indicator
//                             _showSnackBar(
//                               message: 'Swapping meal...',
//                               duration: const Duration(seconds: 1),
//                             );

//                             final newMealName = option['name'] ?? '';
//                             log("swap flow: Processing swap to: $newMealName");

//                             try {
//                               log("meal swap logic: Swapping meal for specific date: ${DateFormat('yyyy-MM-dd').format(targetDate)}");

//                               final success =
//                                   await _subscriptionService.swapMeal(
//                                 subscription.id,
//                                 newMealName,
//                                 targetDate,
//                               );

//                               // Check mounted again after async operation
//                               if (!mounted) {
//                                 log("swap flow: Widget not mounted after swap operation");
//                                 return;
//                               }

//                               if (success) {
//                                 log("swap flow: Swap successful, updating UI");
//                                 // Update MealData objects with the new meal name
//                                 _updateMealNameAfterSwap(
//                                     subscription.id, newMealName);

//                                 final String formattedDate =
//                                     DateFormat('EEE, MMM d').format(targetDate);
//                                 _showSnackBar(
//                                   message:
//                                       'Successfully swapped to $newMealName for $formattedDate',
//                                   backgroundColor: Colors.green,
//                                 );
//                               } else {
//                                 log("swap flow: Swap failed");
//                                 _showSnackBar(
//                                   message:
//                                       'Failed to swap meal. Please try again.',
//                                   backgroundColor: Colors.red,
//                                 );
//                               }
//                             } catch (e) {
//                               log("swap flow: Error during swap: $e");
//                               if (mounted) {
//                                 _showSnackBar(
//                                   message:
//                                       'An error occurred while swapping meal',
//                                   backgroundColor: Colors.red,
//                                 );
//                               }
//                             }
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//       log("swap flow: Bottom sheet closed normally");
//     } catch (e) {
//       log("swap flow: Error showing bottom sheet: $e");
//       if (mounted) {
//         _showSnackBar(
//           message: 'Could not open swap options. Please try again.',
//           backgroundColor: Colors.red,
//         );
//       }
//     }
//   }

//   List<Map<String, String>> _getSwapOptionsForMealType(String planType) {
//     if (planType == 'breakfast') {
//       return [
//         {
//           'name': 'Indian Breakfast',
//           'description': 'Traditional Indian breakfast with tea',
//         },
//         {
//           'name': 'Jain Breakfast',
//           'description': 'Jain-friendly breakfast items with tea',
//         },
//         {
//           'name': 'International Breakfast',
//           'description': 'Continental breakfast options',
//         },
//         {
//           'name': 'Breakfast of the Day',
//           'description': 'Chef\'s special breakfast selection',
//         },
//       ];
//     } else if (planType == 'lunch') {
//       return [
//         {
//           'name': 'Indian Lunch',
//           'description': 'Traditional Indian lunch with roti/rice',
//         },
//         {
//           'name': 'Jain Lunch',
//           'description': 'Jain-friendly lunch options',
//         },
//         {
//           'name': 'International Lunch',
//           'description': 'Global cuisine lunch options',
//         },
//         {
//           'name': 'Lunch of the Day',
//           'description': 'Chef\'s special lunch selection',
//         },
//       ];
//     }

//     // Default empty list for express or other meal types
//     return [];
//   }

//   // Generate schedule dates for a subscription
//   List<DateTime> _generateScheduleDates(
//     DateTime startDate,
//     DateTime endDate,
//     List<int> selectedWeekdays,
//     String planType,
//   ) {
//     // Log all args for debugging
//     log('=== Generating schedule dates for subscription ===');
//     log('Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}');
//     log('End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}');
//     log('Selected Weekdays: $selectedWeekdays');
//     log('Plan Type: $planType');

//     List<DateTime> scheduledDates = [];

//     // Calculate the number of days between start and end
//     final int days = endDate.difference(startDate).inDays;

//     // Log for debugging
//     log('Days between start and end: $days');

//     // Use actual start date
//     log('Using actual start date: ${DateFormat('yyyy-MM-dd').format(startDate)}');

//     // Check if this is a custom plan (has specific weekdays)
//     final bool isCustomPlan =
//         selectedWeekdays.isNotEmpty && selectedWeekdays.length < 5;
//     log('Is custom plan: $isCustomPlan');

//     // Determine which weekdays to include
//     List<int> weekdaysToInclude;
//     if (selectedWeekdays.isEmpty) {
//       // If no weekdays specified, default to Monday-Friday (1-5)
//       weekdaysToInclude = [1, 2, 3, 4, 5]; // Monday to Friday
//       log('Using weekdays: $weekdaysToInclude');
//     } else {
//       weekdaysToInclude = selectedWeekdays;
//       log('Using weekdays: $weekdaysToInclude');
//     }

//     // For each day in the range, check if it's a valid delivery day
//     for (int i = 0; i <= days; i++) {
//       final DateTime date = startDate.add(Duration(days: i));

//       // Skip weekends unless explicitly included
//       if (!weekdaysToInclude.contains(date.weekday)) {
//         continue;
//       }

//       // Add this date to the scheduled dates
//       scheduledDates.add(date);
//     }

//     // Log results
//     log('Generated ${scheduledDates.length} dates from ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');

//     // Log a sample of dates for verification
//     log('Sample dates for this subscription:');
//     final sampleSize = math.min(5, scheduledDates.length);
//     for (int i = 0; i < sampleSize; i++) {
//       final date = scheduledDates[i];
//       final weekday = [
//         '',
//         'Monday',
//         'Tuesday',
//         'Wednesday',
//         'Thursday',
//         'Friday',
//         'Saturday',
//         'Sunday'
//       ][date.weekday];
//       log('  Date ${i + 1}: ${DateFormat('yyyy-MM-dd').format(date)} ($weekday)');
//     }

//     log('Total Scheduled Dates: ${scheduledDates.length}');
//     if (scheduledDates.isNotEmpty) {
//       log('First Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.first)}');
//       log('Last Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.last)}');
//     }
//     log('=== End of scheduled dates generation ===');

//     return scheduledDates;
//   }

//   // Helper function to check if swap is allowed for a date
//   bool _isSwapAllowed(DateTime date, String planType) {
//     // Express plans cannot be swapped
//     if (planType == 'express') {
//       log("Swap not allowed: Express 1-Day plans can never be swapped");
//       return false;
//     }

//     // Check if we're past the cutoff time (11:59 PM the day before)
//     final now = DateTime.now();
//     final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
//         .subtract(const Duration(days: 1));

//     final bool allowed = now.isBefore(cutoffDate);
//     if (!allowed) {
//       log("Swap not allowed: Past cutoff time for date ${DateFormat('yyyy-MM-dd').format(date)}");
//     }

//     return allowed;
//   }

//   // Helper method to show SnackBars with proper context
//   void _showSnackBar({
//     required String message,
//     Color backgroundColor = Colors.black,
//     bool isLoading = false,
//     Duration duration = const Duration(seconds: 2),
//   }) {
//     if (!mounted) return;

//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     scaffoldMessenger.clearSnackBars();

//     scaffoldMessenger.showSnackBar(
//       SnackBar(
//         content: isLoading
//             ? Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     message,
//                     style: GoogleFonts.poppins(),
//                   ),
//                 ],
//               )
//             : Text(
//                 message,
//                 style: GoogleFonts.poppins(),
//               ),
//         duration: duration,
//         backgroundColor: backgroundColor,
//       ),
//     );
//   }

//   // Method to remove a cancelled meal from all views
//   void _removeCancelledMealFromViews(MealData cancelledMeal) {
//     log('[Meal Cancellation] Starting removal of cancelled meal from views: ${cancelledMeal.toString()}');

//     // Get the subscription ID
//     final String subscriptionId = cancelledMeal.subscription.id;

//     log('[Meal Cancellation] Working with subscription ID: $subscriptionId');

//     // Update meal status
//     cancelledMeal.status = 'Cancelled';
//     log('[Meal Cancellation] Updated meal status to: ${cancelledMeal.status}');

//     // Add the date to cancelled dates set for UI indication
//     final DateTime deliveryDate = cancelledMeal.date;
//     _cancelledMealDates.add(deliveryDate);
//     log('[Meal Cancellation] Added ${DateFormat('yyyy-MM-dd').format(deliveryDate)} to cancelled dates');

//     // Find the date key for the meal in _mealsMap
//     DateTime? dateKey;
//     for (final date in _mealsMap.keys) {
//       if (date.year == deliveryDate.year &&
//           date.month == deliveryDate.month &&
//           date.day == deliveryDate.day) {
//         dateKey = date;
//         break;
//       }
//     }

//     if (dateKey != null) {
//       log('[Meal Cancellation] Found date key: ${DateFormat('yyyy-MM-dd').format(dateKey)}');

//       // Get meals for this date
//       final List<MealData> mealsForDate = _mealsMap[dateKey] ?? [];

//       // Find the index of the cancelled meal
//       final int cancelledMealIndex = mealsForDate.indexWhere((meal) =>
//           meal.subscription.id == subscriptionId &&
//           meal.date.day == deliveryDate.day &&
//           meal.date.month == deliveryDate.month &&
//           meal.date.year == deliveryDate.year);

//       if (cancelledMealIndex != -1) {
//         log('[Meal Cancellation] Found meal at index: $cancelledMealIndex for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');

//         // If this is the only meal for that date, remove the whole entry
//         if (mealsForDate.length == 1) {
//           _mealsMap.remove(dateKey);
//           log('[Meal Cancellation] Removed entire entry for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');
//         }
//       } else {
//         log('[Meal Cancellation] Warning: Cancelled meal not found in _mealsMap for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');
//       }
//     } else {
//       log('[Meal Cancellation] Warning: Date key not found for cancelled meal: ${DateFormat('yyyy-MM-dd').format(deliveryDate)}');
//     }

//     // Update UI
//     if (mounted) {
//       setState(() {
//         // Update _selectedDateMeals if the cancelled meal was for the selected day
//         if (_selectedDay.year == deliveryDate.year &&
//             _selectedDay.month == deliveryDate.month &&
//             _selectedDay.day == deliveryDate.day) {
//           _selectedDateMeals = _mealsMap[_selectedDay] ?? [];
//           log('[Meal Cancellation] Updated _selectedDateMeals, new count: ${_selectedDateMeals.length}');
//         }
//       });
//     } else {
//       log('[Meal Cancellation] Widget no longer mounted, skipping UI update');
//     }
//   }

//   // Show dialog to confirm cancelling a meal
//   Future<void> _showCancelMealDialog(MealData meal) async {
//     log('[Meal Flow] Showing dialog for meal: ${meal.name}');

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Meal Action'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('This functionality has been removed per requirements.'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   // New Helper Method to remove meal from local state structures
//   void _removeMealFromLocalState(MealData mealToRemove) {
//     final dateKey = DateTime(
//         mealToRemove.date.year, mealToRemove.date.month, mealToRemove.date.day);

//     // Remove from _mealsMap (Calendar View)
//     if (_mealsMap.containsKey(dateKey)) {
//       _mealsMap[dateKey]!.removeWhere(
//           (meal) => meal.subscription.id == mealToRemove.subscription.id);
//       if (_mealsMap[dateKey]!.isEmpty) {
//         _mealsMap.remove(dateKey);
//       }
//       log("[meal cancel flow] Removed meal ${mealToRemove.subscription.id} from _mealsMap for date $dateKey");
//     }

//     // Add to cancelled dates set for calendar marker
//     _cancelledMealDates.add(dateKey);
//     log("[meal cancel flow] Added date $dateKey to _cancelledMealDates set");

//     // Remove from _selectedDateMeals if it matches the selected day
//     if (isSameDay(_selectedDay, dateKey)) {
//       _selectedDateMeals.removeWhere(
//           (meal) => meal.subscription.id == mealToRemove.subscription.id);
//       log("[meal cancel flow] Removed meal ${mealToRemove.subscription.id} from _selectedDateMeals");
//     }

//     // Note: We are not directly modifying _activeSubscriptions here.
//     // The background reload (_loadSubscriptionsForStudent) will handle refreshing that list from the service.
//   }

//   // Modified _showSnackBar to accept a ScaffoldMessengerInstance
//   void _showSnackBarWithMessenger({
//     required ScaffoldMessengerState messenger,
//     required String message,
//     Color backgroundColor = Colors.black,
//     bool isLoading = false,
//     Duration duration = const Duration(seconds: 2),
//   }) {
//     messenger.clearSnackBars();
//     messenger.showSnackBar(
//       SnackBar(
//         content: isLoading
//             ? Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     message,
//                     style: GoogleFonts.poppins(),
//                   ),
//                 ],
//               )
//             : Text(
//                 message,
//                 style: GoogleFonts.poppins(),
//               ),
//         duration: duration,
//         backgroundColor: backgroundColor,
//       ),
//     );
//   }

//   // Helper to get formatted plan type display text
//   String _getFormattedPlanType(Subscription subscription) {
//     // Get custom plan status
//     bool isCustomPlan = subscription.selectedWeekdays.isNotEmpty &&
//         subscription.selectedWeekdays.length < 5;
//     String customBadge = isCustomPlan ? " (Custom)" : " (Regular)";

//     // Debug logging
//     log("📊 Plan: ${subscription.id}, Type: ${subscription.planType}");
//     log("📊 Date Range: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)} to ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
//     log("📊 Selected Weekdays: ${subscription.selectedWeekdays}");

//     // Handle Express plans
//     if (subscription.planType == 'express') {
//       return "Express 1-Day Lunch Plan";
//     }

//     // Handle Single Day plans
//     if (subscription.endDate.difference(subscription.startDate).inDays <= 1) {
//       return "Single Day ${subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch'} Plan";
//     }

//     // Get the meal type
//     String mealType =
//         subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch';

//     // Calculate total delivery duration for plan name determination
//     String planPeriod;

//     if (isCustomPlan) {
//       // For custom plans, calculate based on actual delivery occurrences
//       int totalDeliveryDays = _calculateTotalDeliveryDays(
//           subscription.startDate,
//           subscription.endDate,
//           subscription.selectedWeekdays);

//       log("📊 Custom Plan: Total delivery days calculated: $totalDeliveryDays");

//       // Apply the day range mapping to determine plan name
//       if (totalDeliveryDays <= 7) {
//         planPeriod = "Weekly";
//       } else if (totalDeliveryDays <= 31) {
//         planPeriod = "Monthly";
//       } else if (totalDeliveryDays <= 90) {
//         planPeriod = "Quarterly";
//       } else if (totalDeliveryDays <= 180) {
//         planPeriod = "Half-Yearly";
//       } else {
//         planPeriod = "Annual";
//       }
//     } else {
//       // For regular plans, use the standard day range between start and end
//       int days = subscription.endDate.difference(subscription.startDate).inDays;
//       log("📊 Regular Plan: Total days in range: $days");

//       // Apply the day range mapping to determine plan name
//       if (days <= 7) {
//         planPeriod = "Weekly";
//       } else if (days <= 31) {
//         planPeriod = "Monthly";
//       } else if (days <= 90) {
//         planPeriod = "Quarterly";
//       } else if (days <= 180) {
//         planPeriod = "Half-Yearly";
//       } else {
//         planPeriod = "Annual";
//       }
//     }

//     log("📊 Final Plan Period: $planPeriod");

//     // Return the correct formatted plan name
//     return "$planPeriod $mealType Plan$customBadge";
//   }

//   // Helper to calculate the total actual delivery days for a custom plan
//   int _calculateTotalDeliveryDays(
//       DateTime startDate, DateTime endDate, List<int> selectedWeekdays) {
//     // For empty weekdays (standard Mon-Fri), use weekdays 1-5
//     List<int> weekdays =
//         selectedWeekdays.isEmpty ? [1, 2, 3, 4, 5] : selectedWeekdays;

//     // If the plan spans less than a week, it's a partial week
//     if (endDate.difference(startDate).inDays < 7) {
//       int count = 0;
//       DateTime current = startDate;
//       while (!current.isAfter(endDate)) {
//         if (weekdays.contains(current.weekday)) {
//           count++;
//         }
//         current = current.add(const Duration(days: 1));
//       }
//       return count;
//     }

//     // Calculate how many of each weekday occurs in the date range
//     int totalOccurrences = 0;

//     // Count full weeks
//     int fullWeeks = endDate.difference(startDate).inDays ~/ 7;
//     totalOccurrences += fullWeeks * weekdays.length;

//     // Handle remaining days
//     DateTime remainingStart = startDate.add(Duration(days: fullWeeks * 7));
//     DateTime current = remainingStart;

//     while (!current.isAfter(endDate)) {
//       if (weekdays.contains(current.weekday)) {
//         totalOccurrences++;
//       }
//       current = current.add(const Duration(days: 1));
//     }

//     log("📊 Plan covers $totalOccurrences delivery days over ${endDate.difference(startDate).inDays} calendar days");
//     return totalOccurrences;
//   }

//   // Helper function to format weekdays list to readable string
//   String _formatWeekdays(List<int> weekdays) {
//     const Map<int, String> weekdayNames = {
//       1: 'Monday',
//       2: 'Tuesday',
//       3: 'Wednesday',
//       4: 'Thursday',
//       5: 'Friday',
//       6: 'Saturday',
//       7: 'Sunday',
//     };

//     List<String> days =
//         weekdays.map((day) => weekdayNames[day] ?? 'Unknown').toList();
//     return days.join(', ');
//   }

//   // Add a date to the cancelled dates for red dot marker in calendar
//   void _addCancelledDateMarker(DateTime date) {
//     final normalizedDate = DateTime(date.year, date.month, date.day);
//     _cancelledMealDates.add(normalizedDate);
//   }

//   // Override calendar builder to show red dots for cancelled meal dates
//   Widget _calendarBuilder(
//       BuildContext context, DateTime day, DateTime focusedDay) {
//     final normalizedDay = DateTime(day.year, day.month, day.day);
//     final hasMeals = _mealsMap.containsKey(normalizedDay) &&
//         _mealsMap[normalizedDay]!.isNotEmpty;
//     final isCancelled = _cancelledMealDates.contains(normalizedDay);

//     final isSelected = isSameDay(day, _selectedDay);
//     final isToday = isSameDay(day, DateTime.now());

//     // Initialize decorations
//     List<Widget> dots = [];

//     // Add meal indicator (green dot)
//     if (hasMeals) {
//       dots.add(
//         Positioned(
//           bottom: 5,
//           left: 18,
//           child: Container(
//             width: 6,
//             height: 6,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.green,
//             ),
//           ),
//         ),
//       );
//     }

//     // Add cancelled meal indicator (red dot)
//     if (isCancelled) {
//       dots.add(
//         Positioned(
//           bottom: 5,
//           right: 18,
//           child: Container(
//             width: 6,
//             height: 6,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.red,
//             ),
//           ),
//         ),
//       );
//     }

//     return Container(
//       margin: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color:
//             isSelected ? AppTheme.purple.withOpacity(0.1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected
//               ? AppTheme.purple
//               : isToday
//                   ? AppTheme.purple.withOpacity(0.3)
//                   : Colors.transparent,
//           width: 1,
//         ),
//       ),
//       child: Stack(
//         children: [
//           Center(
//             child: Text(
//               day.day.toString(),
//               style: GoogleFonts.poppins(
//                 color: isSelected
//                     ? AppTheme.purple
//                     : day.month == focusedDay.month
//                         ? AppTheme.textDark
//                         : AppTheme.textLight,
//                 fontWeight:
//                     isSelected || isToday ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//           ...dots,
//         ],
//       ),
//     );
//   }

//   // Function to find and show the appropriate action dialog based on meal status
//   void _showActionDialogForMeal(MealData meal) {
//     if (meal.status == "Paused") {
//       // For paused meals, show the resume dialog
//       _showResumeMealDialogWithMeal(meal);
//     } else {
//       // For active meals, show the cancel dialog
//       _showCancelMealDialog(meal);
//     }
//   }

//   // Show cancel meal dialog - overloaded version with Subscription and date
//   void _showCancelMealDialogWithSubscription(
//       Subscription subscription, DateTime targetDate) {
//     // Create MealData from subscription and date
//     final meal = _createMealDataFromSubscription(subscription, targetDate);
//     _showCancelMealDialog(meal);
//   }

//   // Adapter method for showing cancel dialog using MealData
//   void showCancelDialogForMealData(MealData meal) {
//     log("meal delete flow: Using adapter method to show dialog for MealData");
//     _showCancelMealDialog(meal);
//   }

//   // Helper adapter for showing cancel dialog for MealData objects
//   void cancelMealDialogFromMealData(MealData meal) {
//     log("meal delete flow: Using MealData adapter to show dialog");
//     _showCancelMealDialog(meal);
//   }

//   // Helper to create a MealData object from a Subscription and date
//   MealData _createMealDataFromSubscription(
//       Subscription subscription, DateTime date) {
//     // Find the student for this subscription
//     final student = _studentsWithMealPlans.firstWhere(
//       (s) => s.id == subscription.studentId,
//       orElse: () => Student(
//         id: subscription.studentId,
//         name: "Unknown Student",
//         schoolName: "",
//         className: "",
//         division: "",
//         floor: "",
//         allergies: "",
//         schoolAddress: "",
//         grade: "",
//         section: "",
//         profileImageUrl: "",
//       ),
//     );

//     // Check if cancel/swap is allowed for this date
//     final bool canSwap = _isSwapAllowed(date, subscription.planType);

//     // Get the meal name for this specific date (handles swapped meals)
//     final String mealName = subscription.getMealNameForDate(date);

//     // Determine if this meal has been swapped
//     final String status =
//         mealName != subscription.mealItemName ? "Swapped" : "Scheduled";

//     // Log meal details for debugging
//     log("meal swap logic: Created MealData for date ${DateFormat('yyyy-MM-dd').format(date)}");
//     log("meal swap logic: Original meal name: ${subscription.mealItemName}");
//     log("meal swap logic: Actual meal name for date: $mealName");
//     log("meal swap logic: Meal status: $status");

//     // Create a MealData object
//     return MealData(
//       studentName: student.name,
//       name: mealName,
//       planType: _getFormattedPlanType(subscription),
//       items: subscription.getMealItems(),
//       status: status, // Set status based on whether meal was swapped
//       subscription: subscription,
//       canSwap: canSwap,
//       date: date,
//       studentId: student.id, // Add studentId
//       subscriptionId: subscription.id, // Add subscriptionId
//     );
//   }

//   // Show dialog to pause a meal with Subscription and date
//   void _showPauseMealDialog(Subscription subscription, DateTime targetDate) {
//     // Create MealData from subscription and date
//     final meal = _createMealDataFromSubscription(subscription, targetDate);
//     _showPauseMealDialogWithMeal(meal);
//   }

//   // Show dialog to pause a meal using MealData
//   void _showPauseMealDialogWithMeal(MealData meal) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Pause Meal',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.orange.shade700,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Would you like to pause this meal delivery?',
//               style: GoogleFonts.poppins(),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Date: ${DateFormat('EEE dd, MMM yyyy').format(meal.date)}',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//             Text(
//               'Meal: ${meal.name}',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.poppins(
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               // Close the dialog first
//               Navigator.pop(context);

//               if (!mounted) return;

//               // Show loading indicator
//               _showSnackBar(
//                 message: 'Pausing meal...',
//                 duration: const Duration(seconds: 1),
//               );

//               try {
//                 // Pause the meal for the specific date
//                 final success = await _subscriptionService.pauseMealDelivery(
//                   meal.subscription.id,
//                   meal.date,
//                 );

//                 if (!mounted) return;

//                 if (success) {
//                   // Update meal status in the UI
//                   if (_isCalendarView) {
//                     final normalizedDate = DateTime(_selectedDay.year,
//                         _selectedDay.month, _selectedDay.day);
//                     if (_mealsMap.containsKey(normalizedDate)) {
//                       for (final mealItem in _mealsMap[normalizedDate]!) {
//                         if (mealItem.subscription.id == meal.subscription.id) {
//                           setState(() {
//                             mealItem.status = "Paused";
//                             _updateSelectedDayMeals();
//                           });
//                         }
//                       }
//                     }
//                   } else {
//                     // Force reload for list view
//                     await _loadSubscriptionsForStudent(_selectedStudentId!,
//                         skipCancelled: true);
//                   }

//                   // Show success message
//                   _showSnackBar(
//                     message: 'Meal paused successfully!',
//                     backgroundColor: Colors.orange,
//                   );
//                 } else {
//                   _showSnackBar(
//                     message: 'Failed to pause meal. Please try again.',
//                     backgroundColor: Colors.red,
//                   );
//                 }
//               } catch (e) {
//                 log("Error pausing meal: $e");
//                 if (mounted) {
//                   _showSnackBar(
//                     message: 'An error occurred: $e',
//                     backgroundColor: Colors.red,
//                   );
//                 }
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//             ),
//             child: Text(
//               'Pause Meal',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Show dialog to resume a meal (overloaded version with Subscription and date)
//   void _showResumeMealDialog(Subscription subscription, DateTime targetDate) {
//     // Create MealData from subscription and date
//     final meal = _createMealDataFromSubscription(subscription, targetDate);
//     _showResumeMealDialogWithMeal(meal);
//   }

//   // Show dialog to resume a meal using MealData
//   void _showResumeMealDialogWithMeal(MealData meal) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           'Resume Meal',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Would you like to resume this meal delivery?',
//               style: GoogleFonts.poppins(),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Date: ${DateFormat('EEE dd, MMM yyyy').format(meal.date)}',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//             Text(
//               'Meal: ${meal.name}',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w500,
//                 color: AppTheme.textDark,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancel',
//               style: GoogleFonts.poppins(
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               // Close the dialog first
//               Navigator.pop(context);

//               if (!mounted) return;

//               // Show loading indicator
//               _showSnackBar(
//                 message: 'Resuming meal...',
//                 duration: const Duration(seconds: 1),
//               );

//               try {
//                 // Resume the meal for the specific date
//                 final success = await _subscriptionService.resumeMealDelivery(
//                   meal.subscription.id,
//                   meal.date,
//                 );

//                 if (!mounted) return;

//                 if (success) {
//                   // Update meal status in the UI
//                   if (_isCalendarView) {
//                     final normalizedDate = DateTime(_selectedDay.year,
//                         _selectedDay.month, _selectedDay.day);
//                     if (_mealsMap.containsKey(normalizedDate)) {
//                       for (final mealItem in _mealsMap[normalizedDate]!) {
//                         if (mealItem.subscription.id == meal.subscription.id) {
//                           setState(() {
//                             mealItem.status = "Scheduled";
//                             _updateSelectedDayMeals();
//                           });
//                         }
//                       }
//                     }
//                   } else {
//                     // Force reload for list view
//                     await _loadSubscriptionsForStudent(_selectedStudentId!,
//                         skipCancelled: true);
//                   }

//                   // Show success message
//                   _showSnackBar(
//                     message: 'Meal resumed successfully!',
//                     backgroundColor: Colors.green,
//                   );
//                 } else {
//                   _showSnackBar(
//                     message: 'Failed to resume meal. Please try again.',
//                     backgroundColor: Colors.red,
//                   );
//                 }
//               } catch (e) {
//                 log("Error resuming meal: $e");
//                 if (mounted) {
//                   _showSnackBar(
//                     message: 'An error occurred: $e',
//                     backgroundColor: Colors.red,
//                   );
//                 }
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//             child: Text(
//               'Resume',
//               style: GoogleFonts.poppins(),
//             ),
//           ),
//         ],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   // Update the calendar markers to include cancelled dates
//   List<dynamic> _getEventsForDay(DateTime day) {
//     final normalizedDay = DateTime(day.year, day.month, day.day);
//     final events = _mealsMap[normalizedDay] ?? [];
//     return events;
//   }

//   // Helper to get formatted plan type display text
//   String _getFormattedPlanType(Subscription subscription) {
//     // Get custom plan status
//     bool isCustomPlan = subscription.selectedWeekdays.isNotEmpty &&
//         subscription.selectedWeekdays.length < 5;
//     String customBadge = isCustomPlan ? " (Custom)" : " (Regular)";

//     // Debug logging
//     log("📊 Plan: ${subscription.id}, Type: ${subscription.planType}");
//     log("📊 Date Range: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)} to ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
//     log("📊 Selected Weekdays: ${subscription.selectedWeekdays}");

//     // Handle Express plans
//     if (subscription.planType == 'express') {
//       return "Express 1-Day Lunch Plan";
//     }

//     // Handle Single Day plans
//     if (subscription.endDate.difference(subscription.startDate).inDays <= 1) {
//       return "Single Day ${subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch'} Plan";
//     }

//     // Get the meal type
//     String mealType =
//         subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch';

//     // Calculate total delivery duration for plan name determination
//     String planPeriod;

//     if (isCustomPlan) {
//       // For custom plans, calculate based on actual delivery occurrences
//       int totalDeliveryDays = _calculateTotalDeliveryDays(
//           subscription.startDate,
//           subscription.endDate,
//           subscription.selectedWeekdays);

//       log("📊 Custom Plan: Total delivery days calculated: $totalDeliveryDays");

//       // Apply the day range mapping to determine plan name
//       if (totalDeliveryDays <= 7) {
//         planPeriod = "Weekly";
//       } else if (totalDeliveryDays <= 31) {
//         planPeriod = "Monthly";
//       } else if (totalDeliveryDays <= 90) {
//         planPeriod = "Quarterly";
//       } else if (totalDeliveryDays <= 180) {
//         planPeriod = "Half-Yearly";
//       } else {
//         planPeriod = "Annual";
//       }
//     } else {
//       // For regular plans, use the standard day range between start and end
//       int days = subscription.endDate.difference(subscription.startDate).inDays;
//       log("📊 Regular Plan: Total days in range: $days");

//       // Apply the day range mapping to determine plan name
//       if (days <= 7) {
//         planPeriod = "Weekly";
//       } else if (days <= 31) {
//         planPeriod = "Monthly";
//       } else if (days <= 90) {
//         planPeriod = "Quarterly";
//       } else if (days <= 180) {
//         planPeriod = "Half-Yearly";
//       } else {
//         planPeriod = "Annual";
//       }
//     }

//     log("📊 Final Plan Period: $planPeriod");

//     // Return the correct formatted plan name
//     return "$planPeriod $mealType Plan$customBadge";
//   }

//   // Helper to calculate the total actual delivery days for a custom plan
//   int _calculateTotalDeliveryDays(
//       DateTime startDate, DateTime endDate, List<int> selectedWeekdays) {
//     // For empty weekdays (standard Mon-Fri), use weekdays 1-5
//     List<int> weekdays =
//         selectedWeekdays.isEmpty ? [1, 2, 3, 4, 5] : selectedWeekdays;

//     // If the plan spans less than a week, it's a partial week
//     if (endDate.difference(startDate).inDays < 7) {
//       int count = 0;
//       DateTime current = startDate;
//       while (!current.isAfter(endDate)) {
//         if (weekdays.contains(current.weekday)) {
//           count++;
//         }
//         current = current.add(const Duration(days: 1));
//       }
//       return count;
//     }

//     // Calculate how many of each weekday occurs in the date range
//     int totalOccurrences = 0;

//     // Count full weeks
//     int fullWeeks = endDate.difference(startDate).inDays ~/ 7;
//     totalOccurrences += fullWeeks * weekdays.length;

//     // Handle remaining days
//     DateTime remainingStart = startDate.add(Duration(days: fullWeeks * 7));
//     DateTime current = remainingStart;

//     while (!current.isAfter(endDate)) {
//       if (weekdays.contains(current.weekday)) {
//         totalOccurrences++;
//       }
//       current = current.add(const Duration(days: 1));
//     }

//     log("📊 Plan covers $totalOccurrences delivery days over ${endDate.difference(startDate).inDays} calendar days");
//     return totalOccurrences;
//   }

//   // Helper function to format weekdays list to readable string
//   String _formatWeekdays(List<int> weekdays) {
//     const Map<int, String> weekdayNames = {
//       1: 'Monday',
//       2: 'Tuesday',
//       3: 'Wednesday',
//       4: 'Thursday',
//       5: 'Friday',
//       6: 'Saturday',
//       7: 'Sunday',
//     };

//     List<String> days =
//         weekdays.map((day) => weekdayNames[day] ?? 'Unknown').toList();
//     return days.join(', ');
//   }

//   // Helper to get Student for a subscription
//   Future<Student?> _getStudentForSubscription(Subscription subscription) async {
//     // If we already have the student loaded, return it
//     if (_studentsWithMealPlans.any((s) => s.id == subscription.studentId)) {
//       return _studentsWithMealPlans
//           .firstWhere((s) => s.id == subscription.studentId);
//     }

//     // Otherwise load the student from the service
//     try {
//       final student =
//           await _studentProfileService.getStudentById(subscription.studentId);
//       return student;
//     } catch (e) {
//       log('Error loading student: $e');
//       return null;
//     }
//   }

//   // Helper adapter for handling MealData objects
//   void cancelMealFromMealData(MealData meal) {
//     log("meal delete flow: Using MealData adapter to cancel meal");
//     _removeCancelledMealFromViews(meal);
//   }

//   // Adapter method for cancelling a meal using MealData
//   void handleMealDataCancellation(MealData meal) {
//     log("meal delete flow: Using adapter method to cancel MealData");
//     _removeCancelledMealFromViews(meal);
//   }

//   // Helper method to get color for meal status
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'paused':
//         return Colors.orange.shade800;
//       case 'cancelled':
//         return Colors.red.shade800;
//       case 'swapped':
//         return Colors.blue.shade800;
//       case 'scheduled':
//       default:
//         return Colors.green.shade800;
//     }
//   }

//   // Update the button actions in the bottom sheet to use the correct method
//   void _handleButtonActionInBottomSheet(MealData meal) {
//     Navigator.pop(context);
//     _showCancelMealDialog(meal);
//   }

//   // Legacy method - wrapper for backward compatibility
//   Future<void> _showSwapMealBottomSheet(Subscription subscription) async {
//     log("swap flow: Using legacy swap method, converting to MealData version");
//     final targetDate =
//         _isCalendarView ? _selectedDay : subscription.nextDeliveryDate;

//     // Create a MealData object for the selected subscription and date
//     final mealData = _createMealDataFromSubscription(subscription, targetDate);

//     // Call the new method with MealData
//     await _showSwapMealBottomSheetWithMealData(mealData);
//   }

//   // Handle the meal cancellation process
//   Future<void> _cancelMeal(MealData meal) async {
//     log('[CancelMealFlow] Processing meal cancellation');

//     try {
//       final subscriptionService = SubscriptionService();
//       final success = await subscriptionService.cancelMealDelivery(
//         meal.subscriptionId,
//         meal.date,
//         studentId: meal.studentId,
//       );

//       if (success) {
//         log('[CancelMealFlow] Meal cancelled successfully');

//         // Update UI by removing the cancelled meal
//         setState(() {
//           final index = _allScheduledMeals.indexWhere((m) =>
//               m['subscriptionId'] == meal.subscriptionId &&
//               DateTime.parse(m['date']).year == meal.date.year &&
//               DateTime.parse(m['date']).month == meal.date.month &&
//               DateTime.parse(m['date']).day == meal.date.day);

//           if (index != -1) {
//             _allScheduledMeals.removeAt(index);
//             log('[CancelMealFlow] Removed meal from UI');
//           }
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Meal cancelled successfully')),
//         );
//       } else {
//         log('[CancelMealFlow] Failed to cancel meal');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to cancel meal')),
//         );
//       }
//     } catch (e) {
//       log('[CancelMealFlow] Error cancelling meal: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   // Update meals for the selected day
//   void _updateSelectedDayMeals() {
//     final normalizedSelectedDay =
//         DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
//     _selectedDateMeals = _mealsMap[normalizedSelectedDay] ?? [];
//   }

//   // Custom calendar marker builder for TableCalendar
//   Widget _buildCalendarMarker(List<dynamic> events, DateTime day) {
//     if (events.isEmpty) {
//       return Container(); // Return empty container for days without events
//     }

//     // Collect meal information for proper display
//     bool hasBreakfast = false;
//     bool hasLunch = false;
//     bool hasExpress = false;
//     bool hasSwappedMeal = false;

//     // Process MealData objects
//     for (final event in events) {
//       if (event is MealData) {
//         // Check meal type
//         if (event.planType.toLowerCase().contains('breakfast')) {
//           hasBreakfast = true;
//         } else if (event.planType.toLowerCase().contains('lunch')) {
//           hasLunch = true;
//         } else if (event.isExpressPlan ||
//             event.planType.toLowerCase().contains('express')) {
//           hasExpress = true;
//         }

//         // Check meal status
//         if (event.status.toLowerCase() == 'swapped') {
//           hasSwappedMeal = true;
//         }
//       }
//     }

//     // Build dots based on meal types and status present for this day
//     List<Widget> dots = [];

//     // Add breakfast marker (purple dot)
//     if (hasBreakfast) {
//       dots.add(
//         Container(
//           width: 6,
//           height: 6,
//           margin: const EdgeInsets.symmetric(horizontal: 1),
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppTheme.purple,
//           ),
//         ),
//       );
//     }

//     // Add lunch marker (green dot)
//     if (hasLunch) {
//       dots.add(
//         Container(
//           width: 6,
//           height: 6,
//           margin: const EdgeInsets.symmetric(horizontal: 1),
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.green,
//           ),
//         ),
//       );
//     }

//     // Add express marker (blue dot)
//     if (hasExpress) {
//       dots.add(
//         Container(
//           width: 6,
//           height: 6,
//           margin: const EdgeInsets.symmetric(horizontal: 1),
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.blueAccent,
//           ),
//         ),
//       );
//     }

//     // Add swapped meal marker (orange dot)
//     if (hasSwappedMeal) {
//       dots.add(
//         Container(
//           width: 6,
//           height: 6,
//           margin: const EdgeInsets.symmetric(horizontal: 1),
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.orange,
//           ),
//         ),
//       );
//     }

//     // Limit to max 3 dots if we have too many to display
//     if (dots.length > 3) {
//       dots = dots.sublist(0, 3);
//     }

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: dots,
//     );
//   }

//   // Helper to get status color based on meal status
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'scheduled':
//         return Colors.green;
//       case 'swapped':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   // Simplified _handleMealCancelled method that doesn't use _cancelledMealDates
//   void _handleMealCancelled(String subscriptionId, DateTime date) {
//     // Simply log the event without adding to _cancelledMealDates
//     log('[Meal Flow] Processing meal cancellation for subscription $subscriptionId on date ${DateFormat('yyyy-MM-dd').format(date)}');

//     // Reload data to reflect changes
//     if (_selectedStudentId != null) {
//       _loadSubscriptionsForStudent(_selectedStudentId!);
//     }
//   }
// }
