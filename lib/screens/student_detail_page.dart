import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:intl/intl.dart';
import 'package:startwell/screens/main_screen.dart';

class StudentDetailPage extends StatefulWidget {
  final Student student;

  const StudentDetailPage({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Student Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => MainScreen()),
                (route) => false,
              );
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.purpleToDeepPurple,
            ),
          ),
          elevation: 4,
          shadowColor: AppTheme.deepPurple.withOpacity(0.3),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student profile header with avatar
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Student details card
              _buildDetailsCard(),
              const SizedBox(height: 24),

              // Meal plan information card (if applicable)
              // if (widget.student.hasActivePlan) _buildMealPlanCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF7F7F7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student icon in decorative container
          Center(
            child: Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFEDE5FB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEDE5FB),
                    Color(0xFFE1D3F9),
                  ],
                ),
              ),
              child: Icon(
                Icons.school,
                size: 48,
                color: AppTheme.purple,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Student name
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              widget.student.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // School name
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              widget.student.schoolName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF7F7F7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purple.withOpacity(0.1),
                  AppTheme.deepPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE5FB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Student Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class & Division
                _buildInfoRow(
                  Icons.class_,
                  'Class & Division',
                  'Class ${widget.student.className} - ${widget.student.division}',
                ),
                const SizedBox(height: 16),

                // Floor
                _buildInfoRow(
                  Icons.apartment,
                  'Floor',
                  'Floor: ${widget.student.floor}',
                ),
                const SizedBox(height: 16),

                // Allergies
                _buildInfoRow(
                  Icons.healing,
                  'Allergies',
                  widget.student.allergies.isEmpty
                      ? 'None'
                      : widget.student.allergies,
                  valueColor:
                      widget.student.allergies.isEmpty ? null : Colors.red[700],
                  iconBackground:
                      widget.student.allergies.isEmpty ? null : Colors.red[50],
                  iconColor:
                      widget.student.allergies.isEmpty ? null : Colors.red[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF7F7F7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purple.withOpacity(0.1),
                  AppTheme.deepPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE5FB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: AppTheme.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Meal Plans',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breakfast Plan
                if (widget.student.hasActiveBreakfast) ...[
                  _buildMealPlanSection(
                    'Breakfast Plan',
                    widget.student.breakfastPlanStartDate,
                    widget.student.breakfastPlanEndDate,
                    widget.student.breakfastPreference,
                    widget.student.breakfastSelectedWeekdays,
                    onPreOrder: () => _showPreOrderDialog(context, 'breakfast'),
                  ),
                  const SizedBox(height: 20),
                ],

                // Lunch Plan
                if (widget.student.hasActiveLunch) ...[
                  _buildMealPlanSection(
                    'Lunch Plan',
                    widget.student.lunchPlanStartDate,
                    widget.student.lunchPlanEndDate,
                    widget.student.lunchPreference,
                    widget.student.lunchSelectedWeekdays,
                    onPreOrder: () => _showPreOrderDialog(context, 'lunch'),
                  ),
                ],

                // No active plans message
                if (!widget.student.hasActiveBreakfast &&
                    !widget.student.hasActiveLunch)
                  Center(
                    child: Text(
                      'No active meal plans',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanSection(
    String title,
    DateTime? startDate,
    DateTime? endDate,
    String? preference,
    List<int>? weekdays, {
    required VoidCallback onPreOrder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton.icon(
                onPressed: onPreOrder,
                icon: Icon(Icons.add_circle_outline, size: 20),
                label: Text('Pre-order'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (startDate != null && endDate != null) ...[
            _buildDateRange(startDate, endDate),
            const SizedBox(height: 12),
          ],
          if (preference != null) ...[
            _buildPreferenceInfo(preference),
            const SizedBox(height: 12),
          ],
          if (weekdays != null && weekdays.isNotEmpty)
            _buildWeekdaysInfo(weekdays),
        ],
      ),
    );
  }

  void _showPreOrderDialog(BuildContext context, String planType) {
    final endDate = planType == 'breakfast'
        ? widget.student.breakfastPlanEndDate
        : widget.student.lunchPlanEndDate;

    if (endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active plan found for $planType'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pre-order $planType',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current plan ends on:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMMM d, yyyy').format(endDate),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can place a pre-order for after this date.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription selection screen
              Navigator.pushNamed(
                context,
                '/subscription-selection',
                arguments: {
                  'studentId': widget.student.id,
                  'planType': planType,
                  'isPreOrder': true,
                  'currentEndDate': endDate,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue to Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor, Color? iconBackground, Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBackground ?? Color(0xFFEDE5FB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (iconColor ?? Color(0xFF8B5CF6)).withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppTheme.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: valueColor ?? AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPlanInfo(String planType) {
    DateTime? startDate;
    DateTime? endDate;

    if (planType == 'breakfast') {
      startDate = widget.student.breakfastPlanStartDate;
      endDate = widget.student.breakfastPlanEndDate;
    } else {
      startDate = widget.student.lunchPlanStartDate;
      endDate = widget.student.lunchPlanEndDate;
    }

    if (startDate == null || endDate == null) {
      return 'Active';
    }

    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';

    return 'Active ($startStr - $endStr)';
  }

  Widget _buildDateRange(DateTime startDate, DateTime endDate) {
    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';

    return Text(
      '$startStr - $endStr',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPreferenceInfo(String preference) {
    return Text(
      'Preference: $preference',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildWeekdaysInfo(List<int> weekdays) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = weekdays.map((index) => days[index]).join(', ');

    return Text(
      'Selected Weekdays: $selectedDays',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
