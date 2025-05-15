import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/services/selected_student_service.dart';

class StudentSelectorDropdown extends StatefulWidget {
  final List<Student> students;
  final String selectedStudentId;
  final Function(String) onStudentSelected;
  final bool isLoading;

  const StudentSelectorDropdown({
    Key? key,
    required this.students,
    required this.selectedStudentId,
    required this.onStudentSelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<StudentSelectorDropdown> createState() =>
      _StudentSelectorDropdownState();
}

class _StudentSelectorDropdownState extends State<StudentSelectorDropdown> {
  late String _currentStudentId;

  @override
  void initState() {
    super.initState();
    _currentStudentId = widget.selectedStudentId;
  }

  @override
  void didUpdateWidget(StudentSelectorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStudentId != widget.selectedStudentId) {
      setState(() {
        _currentStudentId = widget.selectedStudentId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there's only one student, no need to show the dropdown
    if (widget.students.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: widget.isLoading ? _buildLoadingDropdown() : _buildDropdown(),
    );
  }

  Widget _buildLoadingDropdown() {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            'Select Student',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMedium,
            ),
          ),
          const Spacer(),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _currentStudentId,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.purple),
        iconSize: 24,
        elevation: 8,
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
        hint: Text(
          'Select Student',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMedium,
          ),
        ),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _currentStudentId = newValue;
            });
            widget.onStudentSelected(newValue);

            // Also update the global selected student
            SelectedStudentService().setSelectedStudent(newValue);
          }
        },
        items: widget.students.map<DropdownMenuItem<String>>((Student student) {
          return DropdownMenuItem<String>(
            value: student.id,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppTheme.purple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
