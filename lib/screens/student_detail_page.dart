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
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
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
            if (student.hasActivePlan) _buildMealPlanCard(),
          ],
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
              student.name,
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
              student.schoolName,
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
                  'Class ${student.className} - ${student.division}',
                ),
                const SizedBox(height: 16),

                // Floor
                _buildInfoRow(
                  Icons.apartment,
                  'Floor',
                  'Floor: ${student.floor}',
                ),
                const SizedBox(height: 16),

                // School Address
                _buildInfoRow(
                  Icons.location_on,
                  'School Address',
                  student.schoolAddress,
                ),
                const SizedBox(height: 16),

                // Allergies
                _buildInfoRow(
                  Icons.healing,
                  'Allergies',
                  student.allergies.isEmpty ? 'None' : student.allergies,
                  valueColor:
                      student.allergies.isEmpty ? null : Colors.red[700],
                  iconBackground:
                      student.allergies.isEmpty ? null : Colors.red[50],
                  iconColor: student.allergies.isEmpty ? null : Colors.red[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard() {
    final hasBreakfast = student.hasActiveBreakfast;
    final hasLunch = student.hasActiveLunch;

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
                begin: Alignment.topLeft,
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
                    Icons.restaurant,
                    color: AppTheme.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Meal Plan Information',
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
                if (hasBreakfast) ...[
                  _buildInfoRow(
                    Icons.ramen_dining,
                    'Breakfast Plan',
                    _formatPlanInfo('breakfast'),
                    valueColor: AppTheme.purple,
                  ),
                  const SizedBox(height: 16),
                ],
                if (hasLunch) ...[
                  _buildInfoRow(
                    Icons.lunch_dining,
                    'Lunch Plan',
                    _formatPlanInfo('lunch'),
                    valueColor: AppTheme.purple,
                  ),
                  const SizedBox(height: 16),
                ],
                if (hasBreakfast && student.breakfastPreference != null) ...[
                  _buildInfoRow(
                    Icons.restaurant_menu,
                    'Breakfast Preference',
                    student.breakfastPreference!,
                  ),
                  const SizedBox(height: 16),
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
