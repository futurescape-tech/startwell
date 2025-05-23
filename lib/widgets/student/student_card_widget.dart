import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/screens/student_detail_page.dart';
import 'package:startwell/themes/app_theme.dart';

class StudentCardWidget extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final Function(Student)? onSelect;
  final Function({Student? student})? onEdit;
  final Function(Student)? onDelete;
  final bool isManagementMode;

  const StudentCardWidget({
    Key? key,
    required this.student,
    this.isSelected = false,
    this.onSelect,
    this.onEdit,
    this.onDelete,
    this.isManagementMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasActivePlan = student.hasActiveBreakfast || student.hasActiveLunch;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.purple : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      elevation: isSelected ? 4 : 2,
      shadowColor: AppTheme.deepPurple.withOpacity(0.15),
      child: InkWell(
        onTap: () {
          if (onSelect != null) {
            onSelect!(student);
          } else {
            // Navigate to detail page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDetailPage(student: student),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.purple.withOpacity(0.1),
        highlightColor: AppTheme.purple.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF7F7F7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator (only in selection mode)
                  if (onSelect != null && !isManagementMode)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppTheme.purple,
                                  AppTheme.deepPurple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Color(0xFFD1D1D1),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.0,
                        child: Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  // Student details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student name with person icon
                        _buildInfoRow(
                          Icons.person,
                          student.name,
                          isTitle: true,
                        ),
                        const SizedBox(height: 12),

                        // School name with school icon
                        _buildInfoRow(
                          Icons.school,
                          student.schoolName,
                        ),
                        const SizedBox(height: 12),

                        // Class info with class icon
                        _buildInfoRow(
                          Icons.class_,
                          'Class ${student.className} - ${student.division}',
                        ),
                        const SizedBox(height: 12),

                        // Floor info with apartment icon
                        _buildInfoRow(
                          Icons.apartment,
                          'Floor: ${student.floor}',
                        ),

                        if (student.allergies.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          // Allergies with healing icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.healing,
                                  size: 16,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Allergies',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      student.allergies,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.red[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Active meal plan tags
                        if (hasActivePlan) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (student.hasActiveBreakfast)
                                _buildMealTag('Breakfast', Icons.ramen_dining),
                              if (student.hasActiveBreakfast &&
                                  student.hasActiveLunch)
                                const SizedBox(width: 12),
                              if (student.hasActiveLunch)
                                _buildMealTag('Lunch', Icons.flatware),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  if (onEdit != null || onDelete != null)
                    Column(
                      children: [
                        if (onEdit != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFFEDE5FB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF8B5CF6).withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onEdit!(student: student),
                                customBorder: CircleBorder(),
                                splashColor: AppTheme.purple.withOpacity(0.2),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: AppTheme.purple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (onDelete != null)
                          student.hasActivePlan
                              ? Tooltip(
                                  message:
                                      'Cannot delete a student with active meal plan',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _confirmDelete(context, student),
                                      customBorder: CircleBorder(),
                                      splashColor: Colors.red.withOpacity(0.2),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a consistent info row with circular icon
  Widget _buildInfoRow(IconData icon, String text, {bool isTitle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFEDE5FB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.purple.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: isTitle ? 18 : 16,
            color: AppTheme.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTitle) ...[
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ] else ...[
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build meal plan tag
  Widget _buildMealTag(String title, IconData icon) {
    Color badgeColor;
    List<Color> gradientColors;
    if (title == 'Breakfast') {
      badgeColor = Colors.pink;
      gradientColors = [
        Colors.pink.withOpacity(0.15),
        Colors.pink.withOpacity(0.15)
      ];
    } else if (title == 'Lunch') {
      badgeColor = Colors.green;
      gradientColors = [
        Colors.green.withOpacity(0.15),
        Colors.green.withOpacity(0.15)
      ];
    } else {
      badgeColor = AppTheme.purple;
      gradientColors = [
        AppTheme.purple.withOpacity(0.2),
        AppTheme.deepPurple.withOpacity(0.1)
      ];
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Confirm delete dialog with improved styling
  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Student Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.red[50],
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.warning_amber_rounded,
            //           color: Colors.red[700], size: 24),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Text(
            //           'This action cannot be undone. All data associated with this student will be permanently removed.',
            //           style: GoogleFonts.poppins(
            //             fontSize: 14,
            //             color: Colors.red[700],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete the profile for ${student.name}?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMedium,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete!(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
