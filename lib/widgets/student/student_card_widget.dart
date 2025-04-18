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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.purple : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: isSelected ? 2 : 0,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator (only in selection mode)
                  if (onSelect != null && !isManagementMode)
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onSelect!(student),
                        activeColor: AppTheme.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (onSelect != null && !isManagementMode)
                    const SizedBox(width: 8),

                  // Student details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student name with person icon
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 18, color: AppTheme.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                student.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // School name with school icon
                        Row(
                          children: [
                            const Icon(Icons.school,
                                size: 18, color: AppTheme.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                student.schoolName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Class info with class icon
                        Row(
                          children: [
                            const Icon(Icons.class_,
                                size: 18, color: AppTheme.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Class ${student.className} - ${student.division}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Floor info with apartment icon
                        Row(
                          children: [
                            const Icon(Icons.apartment,
                                size: 18, color: AppTheme.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Floor: ${student.floor}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (student.allergies.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          // Allergies with healing icon
                          Row(
                            children: [
                              Icon(Icons.healing,
                                  size: 18, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Allergies: ${student.allergies}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
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
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => onEdit!(student: student),
                            tooltip: 'Edit',
                          ),
                        if (onDelete != null)
                          student.hasActivePlan
                              ? Tooltip(
                                  message:
                                      'Student has active meal plans and cannot be deleted',
                                  child: IconButton(
                                    icon: const Icon(Icons.no_accounts,
                                        color: Colors.grey),
                                    onPressed: null, // Disabled
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => onDelete!(student),
                                  tooltip: 'Delete student profile',
                                ),
                      ],
                    ),
                ],
              ),

              // Active meal plan information
              if (hasActivePlan && !isManagementMode) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16,
                      color:
                          student.hasActiveBreakfast && student.hasActiveLunch
                              ? Colors.orange
                              : AppTheme.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getActivePlanLabel(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: student.hasActiveBreakfast &&
                                  student.hasActiveLunch
                              ? Colors.orange
                              : AppTheme.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getActivePlanLabel() {
    if (student.hasActiveBreakfast && student.hasActiveLunch) {
      return 'Active Plans: Breakfast & Lunch';
    } else if (student.hasActiveBreakfast) {
      return 'Active Plan: Breakfast';
    } else if (student.hasActiveLunch) {
      return 'Active Plan: Lunch';
    }
    return 'No active meal plans';
  }
}
