import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/profile_avatar.dart';

class StudentDetailPage extends StatelessWidget {
  final Student student;

  const StudentDetailPage({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            if (student.hasActivePlan) _buildMealPlanCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Profile avatar
          ProfileAvatar(
            userProfile: null,
            radius: 50,
            initialsColor: Colors.white,
            backgroundColor: AppTheme.purple,
          ),
          const SizedBox(height: 16),

          // Student name
          Text(
            student.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),

          // School name
          Text(
            student.schoolName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Class & Division
            _buildInfoRow(
              Icons.class_,
              'Class & Division',
              'Class ${student.className} - ${student.division}',
            ),
            const SizedBox(height: 12),

            // Floor
            _buildInfoRow(
              Icons.apartment,
              'Floor',
              'Floor: ${student.floor}',
            ),
            const SizedBox(height: 12),

            // School Address
            _buildInfoRow(
              Icons.location_on,
              'School Address',
              student.schoolAddress,
            ),
            const SizedBox(height: 12),

            // Allergies
            _buildInfoRow(
              Icons.healing,
              'Allergies',
              student.allergies.isEmpty ? 'None' : student.allergies,
              valueColor: student.allergies.isEmpty ? null : Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanCard() {
    final hasBreakfast = student.hasActiveBreakfast;
    final hasLunch = student.hasActiveLunch;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Plan Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            if (hasBreakfast) ...[
              _buildInfoRow(
                Icons.breakfast_dining,
                'Breakfast Plan',
                _formatPlanInfo('breakfast'),
                valueColor: AppTheme.purple,
              ),
              const SizedBox(height: 12),
            ],
            if (hasLunch) ...[
              _buildInfoRow(
                Icons.lunch_dining,
                'Lunch Plan',
                _formatPlanInfo('lunch'),
                valueColor: AppTheme.purple,
              ),
              const SizedBox(height: 12),
            ],
            if (hasBreakfast && student.breakfastPreference != null) ...[
              _buildInfoRow(
                Icons.restaurant_menu,
                'Breakfast Preference',
                student.breakfastPreference!,
              ),
              const SizedBox(height: 12),
            ],
            if (hasLunch && student.lunchPreference != null) ...[
              _buildInfoRow(
                Icons.restaurant_menu,
                'Lunch Preference',
                student.lunchPreference!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: AppTheme.purple,
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
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
      startDate = student.breakfastPlanStartDate;
      endDate = student.breakfastPlanEndDate;
    } else {
      startDate = student.lunchPlanStartDate;
      endDate = student.lunchPlanEndDate;
    }

    if (startDate == null || endDate == null) {
      return 'Active';
    }

    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';

    return 'Active ($startStr - $endStr)';
  }
}
