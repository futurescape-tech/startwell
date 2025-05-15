import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/screens/order_summary_screen.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:startwell/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/widgets/student/student_card_widget.dart';

class ManageStudentProfileScreen extends StatefulWidget {
  final String? planType;
  final bool? isCustomPlan;
  final List<bool>? selectedWeekdays;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime>? mealDates;
  final double? totalAmount;
  final List<Meal>? selectedMeals;
  final bool? isExpressOrder;
  final bool isManagementMode;
  final String? mealType;
  final UserProfile? userProfile;

  const ManageStudentProfileScreen({
    Key? key,
    this.planType,
    this.isCustomPlan,
    this.selectedWeekdays,
    this.startDate,
    this.endDate,
    this.mealDates,
    this.totalAmount,
    this.selectedMeals,
    this.isExpressOrder,
    this.isManagementMode = false,
    this.mealType,
    this.userProfile,
  }) : super(key: key);

  @override
  State<ManageStudentProfileScreen> createState() =>
      _ManageStudentProfileScreenState();
}

class _ManageStudentProfileScreenState
    extends State<ManageStudentProfileScreen> {
  // Use the StudentProfileService for persistence
  final StudentProfileService _profileService = StudentProfileService();

  // Student profiles list
  List<Student> _studentProfiles = [];

  // Currently selected student
  Student? _selectedStudent;

  // Loading state
  bool _isLoading = true;

  // Form controllers
  final _schoolNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _classController = TextEditingController();
  final _divisionController = TextEditingController();
  final _floorController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // For editing an existing student
  bool _isEditing = false;
  int _editingStudentIndex = -1;

  // Dummy list of schools
  final List<String> dummySchools = [
    'StartWell International School',
    'Springfield Public School',
    'Maple Leaf Academy',
    'Navi Mumbai High School',
    'Green Valley Convent'
  ];
  String? selectedSchool; // Add this in your State

  @override
  void initState() {
    super.initState();
    // Load student profiles from persistent storage
    _loadStudentProfiles();
  }

  @override
  void dispose() {
    // Dispose of controllers when the screen is disposed
    _schoolNameController.dispose();
    _studentNameController.dispose();
    _classController.dispose();
    _divisionController.dispose();
    _floorController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  // Method to refresh student profiles from storage
  Future<void> _refreshStudentProfiles() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final profiles = await _profileService.loadStudentProfiles();

      if (!mounted) return;

      setState(() {
        _studentProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error refreshing student profiles: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to refresh student profiles',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load student profiles from service
  Future<void> _loadStudentProfiles() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if the service is already initialized
      if (_profileService.isInitialized) {
        // Get profiles using the async method
        final profiles = await _profileService.getStudentProfiles();

        if (mounted) {
          setState(() {
            _studentProfiles = profiles;
            _isLoading = false;
          });
        }
      } else {
        // Otherwise, load from persistent storage
        final profiles = await _profileService.loadStudentProfiles();

        if (mounted) {
          setState(() {
            _studentProfiles = profiles;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading student profiles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load student profiles',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show form to create or edit a student profile
  void _showStudentForm({Student? student}) {
    // If editing, pre-fill the form
    _isEditing = student != null;
    if (_isEditing) {
      _editingStudentIndex = _studentProfiles.indexWhere(
        (s) => s.id == student!.id,
      );
      _schoolNameController.text = student!.schoolName;
      if (dummySchools.contains(student.schoolName)) {
        selectedSchool = student.schoolName;
      } else {
        selectedSchool = null; // Or handle as an "Other" case if desired
      }
      _studentNameController.text = student.name;
      _classController.text = student.className;
      _divisionController.text = student.division;
      _floorController.text = student.floor;
      _allergiesController.text = student.allergies;
    } else {
      // Clear the form for a new student
      _schoolNameController.clear();
      selectedSchool = null;
      _studentNameController.clear();
      _classController.clear();
      _divisionController.clear();
      _floorController.clear();
      _allergiesController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          color: Color(0xFFF8F8F8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepPurple.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar at the top
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.purple.withOpacity(0.2),
                            AppTheme.deepPurple.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.purple.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
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
                            child: Icon(
                              _isEditing ? Icons.edit : Icons.person_add_alt_1,
                              size: 16,
                              color: AppTheme.purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing
                                ? 'Edit Student Profile'
                                : 'Create Student Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: Colors.red.shade700),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // School Name Dropdown
                DropdownButtonFormField<String>(
                  value: selectedSchool,
                  decoration: InputDecoration(
                    labelText: 'Select School Name',
                    prefixIcon: Icon(Icons.school,
                        color: AppTheme.purple.withOpacity(0.7), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppTheme.purple, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16), // Adjusted padding
                  ),
                  items: dummySchools.map((school) {
                    return DropdownMenuItem<String>(
                      value: school,
                      child: Text(school,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppTheme.textDark)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSchool = value;
                      _schoolNameController.text = value ?? '';
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a school' : null,
                  style: GoogleFonts.poppins(
                    // Added style for selected item text
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                // Student Name
                _buildFormField(
                  controller: _studentNameController,
                  labelText: 'Student Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Class
                _buildFormField(
                  controller: _classController,
                  labelText: 'Class',
                  icon: Icons.class_,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter class';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Division
                _buildFormField(
                  controller: _divisionController,
                  labelText: 'Division',
                  icon: Icons.dashboard_customize,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter division';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Floor
                _buildFormField(
                  controller: _floorController,
                  labelText: 'Floor',
                  icon: Icons.apartment,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter floor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Medical Allergies (optional)
                _buildFormField(
                  controller: _allergiesController,
                  labelText: 'Medical Allergies (Optional)',
                  icon: Icons.healing,
                  isOptional: true,
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveStudentProfile,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 2,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleToDeepPurple,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          _isEditing ? 'Update Profile' : 'Create Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0), // Added bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build form fields with consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(
            color: AppTheme.textMedium,
            fontSize: 14,
          ),
          prefixIcon:
              Icon(icon, color: AppTheme.purple.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.purple, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          suffixIcon: isOptional
              ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    'Optional',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  // Save or update student profile
  void _saveStudentProfile() {
    if (_formKey.currentState!.validate()) {
      final newStudent = Student(
        id: _isEditing
            ? _studentProfiles[_editingStudentIndex].id
            : DateTime.now().toString(),
        name: _studentNameController.text,
        schoolName: _schoolNameController.text,
        className: _classController.text,
        division: _divisionController.text,
        floor: _floorController.text,
        allergies: _allergiesController.text,
        grade: _classController.text, // Using className as grade
        section: _divisionController.text, // Using division as section
        profileImageUrl: '', // Default empty profile image URL
      );

      if (_isEditing) {
        // Update existing student
        setState(() {
          _studentProfiles[_editingStudentIndex] = newStudent.copyWith(
            hasActiveBreakfast:
                _studentProfiles[_editingStudentIndex].hasActiveBreakfast,
            hasActiveLunch:
                _studentProfiles[_editingStudentIndex].hasActiveLunch,
            breakfastPlanEndDate:
                _studentProfiles[_editingStudentIndex].breakfastPlanEndDate,
            lunchPlanEndDate:
                _studentProfiles[_editingStudentIndex].lunchPlanEndDate,
          );
        });
        _profileService.updateStudentProfile(
          _studentProfiles[_editingStudentIndex],
        );
      } else {
        // Add new student
        setState(() {
          _studentProfiles.add(newStudent);
        });
        _profileService.addStudentProfile(newStudent);
      }

      // Close the dialog
      Navigator.of(context).pop();
      _clearForm();
    }
  }

  // Clear all form fields and reset state
  void _clearForm() {
    setState(() {
      _studentNameController.clear();
      _schoolNameController.clear();
      selectedSchool = null;
      _classController.clear();
      _divisionController.clear();
      _floorController.clear();
      _allergiesController.clear();
      _isEditing = false;
      _editingStudentIndex = -1;
    });
  }

  // Delete student profile (after confirmation)
  void _deleteStudentProfile(Student student) async {
    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Delete from persistent storage
    final success = await _profileService.deleteStudentProfile(student.id);

    if (success) {
      // Reload profiles from storage to maintain data integrity
      final profiles = await _profileService.loadStudentProfiles();

      setState(() {
        _studentProfiles = profiles;
        // Reset selected student if it was deleted
        if (_selectedStudent?.id == student.id) {
          _selectedStudent = null;
        }
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student profile deleted successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete student profile',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build the list of student profiles
  Widget _buildStudentsList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppTheme.deepPurple,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 10),
            margin: const EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              widget.isManagementMode ? 'Student Profiles' : 'Select a Student',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // List of student profiles with animation
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentProfiles.length,
            itemBuilder: (context, index) {
              final student = _studentProfiles[index];
              final isSelected = _selectedStudent?.id == student.id;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppTheme.purple.withOpacity(0.15)
                          : AppTheme.deepPurple.withOpacity(0.05),
                      blurRadius: isSelected ? 10 : 4,
                      spreadRadius: isSelected ? 1 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: StudentCardWidget(
                  student: student,
                  isSelected: isSelected,
                  onSelect: widget.isManagementMode ? null : _selectStudent,
                  onEdit: _showStudentForm,
                  onDelete: widget.isManagementMode
                      ? student.hasActivePlan
                          ? null
                          : _deleteStudentProfile
                      : null,
                  isManagementMode: widget.isManagementMode,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Build empty state widget
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
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
            color: AppTheme.deepPurple.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFEDE5FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No student profile found.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isManagementMode
                ? 'Create a profile to manage your students.'
                : 'Please create one to continue your subscription.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // SizedBox(
          //   width: 220,
          //   height: 50,
          //   child: ElevatedButton.icon(
          //     onPressed: () => _showStudentForm(),
          //     style: ElevatedButton.styleFrom(
          //       padding: EdgeInsets.zero,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(24),
          //       ),
          //       elevation: 2,
          //     ),
          //     icon: Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: Colors.white.withOpacity(0.2),
          //         shape: BoxShape.circle,
          //       ),
          //       child: const Icon(
          //         Icons.add,
          //         color: Colors.white,
          //         size: 18,
          //       ),
          //     ),
          //     label: Ink(
          //       decoration: BoxDecoration(
          //         gradient: AppTheme.purpleToDeepPurple,
          //         borderRadius: BorderRadius.circular(24),
          //       ),
          //       child: Container(
          //         alignment: Alignment.center,
          //         padding: const EdgeInsets.symmetric(horizontal: 16),
          //         child: Text(
          //           'Create New Profile',
          //           style: GoogleFonts.poppins(
          //             fontSize: 16,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Transition to the order summary screen
  void _proceedToOrderSummary() {
    // Add a small animation before proceeding to the next screen
    if (_selectedStudent != null) {
      ScaffoldMessenger.of(context).clearSnackBars();

      // Apply a scale effect to the selected student card
      setState(() {
        // This triggers the animation in the UI
      });

      // Short delay for the animation
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                OrderSummaryScreen(
              planType: widget.planType ?? '',
              isCustomPlan: widget.isCustomPlan ?? false,
              selectedWeekdays: widget.selectedWeekdays ?? [],
              startDate: widget.startDate ?? DateTime.now(),
              endDate: widget.endDate ?? DateTime.now(),
              mealDates: widget.mealDates ?? [],
              totalAmount: widget.totalAmount ?? 0,
              selectedMeals: widget.selectedMeals ?? [],
              isExpressOrder: widget.isExpressOrder ?? false,
              selectedStudent: _selectedStudent!,
              mealType: widget.mealType,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      });
    }
  }

  // Select a student
  void _selectStudent(Student student) {
    // If in management mode, just return
    if (widget.isManagementMode) {
      return;
    }

    // Check for meal plan restrictions
    if (widget.selectedMeals != null && widget.selectedMeals!.isNotEmpty) {
      // Use the provided mealType parameter for validation if available
      final String planType = widget.mealType ??
          (widget.selectedMeals!.first.categories.first ==
                  MealCategory.breakfast
              ? 'breakfast'
              : widget.selectedMeals!.first.categories.first ==
                      MealCategory.expressOneDay
                  ? 'express'
                  : 'lunch');

      // Validate meal plan assignment
      final String? validationError = MealPlanValidator.validateMealPlan(
        student,
        planType,
      );

      if (validationError != null) {
        // Show error message
        _showValidationErrorDialog(validationError);
        return;
      }
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedStudent?.id == student.id) {
        _selectedStudent = null;
      } else {
        _selectedStudent = student;
      }
    });
  }

  // Show validation error dialog with improved styling
  void _showValidationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cannot Select This Student',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red[100]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.purple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpressOrder = widget.isExpressOrder ?? false;
    final bool isWithinExpressWindow =
        isExpressOrder ? MealPlanValidator.isWithinExpressWindow() : true;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.main, (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isManagementMode ? 'Student' : 'Select Student Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: AppTheme.purpleToDeepPurple),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.main, (route) => false),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: widget.userProfile != null
                  ? ProfileAvatar(
                      userProfile: widget.userProfile,
                      radius: 18,
                      onAvatarTap: () {
                        Navigator.pushNamed(context, Routes.profileSettings);
                      },
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.account_circle,
                        color: AppTheme.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.profileSettings);
                      },
                    ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Express order window banner (only shown for Express orders)
                            if (isExpressOrder) ...[
                              InfoBanner(
                                title: isWithinExpressWindow
                                    ? "Express Order Window: 12:00 AM - 8:00 AM IST"
                                    : "Express Order Window Closed",
                                message: isWithinExpressWindow
                                    ? "You're within the express order window. You can place your order for same-day delivery."
                                    : "Express orders are only available between 12:00 AM and 8:00 AM IST. Please try again during this time window.",
                                type: isWithinExpressWindow
                                    ? InfoBannerType.success
                                    : InfoBannerType.warning,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Instructions
                            InfoBanner(
                              title: widget.isManagementMode
                                  ? "Instructions"
                                  : "Instructions",
                              message: widget.isManagementMode
                                  ? "View, create, edit, or delete student profiles."
                                  : "Please select or create a student profile to continue with your subscription.",
                              type: InfoBannerType.info,
                            ),

                            const SizedBox(height: 24),

                            // Student profiles list
                            _studentProfiles.isEmpty
                                ? _buildEmptyState()
                                : _buildStudentsList(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom buttons in a container with shadow
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Create new profile button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () => _showStudentForm(),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: AppTheme.purple,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  side: BorderSide(color: AppTheme.purple),
                                ),
                                elevation: 0,
                              ),
                              icon: Container(
                                //padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                ),
                              ),
                              label: Text(
                                'Create New Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // Continue button (only shown in selection mode)
                          if (!widget.isManagementMode) ...[
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                gradient: isExpressOrder
                                    ? LinearGradient(
                                        colors: [
                                          Colors.purple,
                                          Colors.deepPurple.shade500,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : AppTheme.purpleToDeepPurple,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: (_selectedStudent != null &&
                                        (!isExpressOrder ||
                                            isWithinExpressWindow))
                                    ? _proceedToOrderSummary
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isExpressOrder
                                      ? Colors.deepPurple
                                      : AppTheme
                                          .deepPurple, // your solid color here
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Continue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // Warning for closed express window
                            if (isExpressOrder && !isWithinExpressWindow) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Express ordering is currently unavailable',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
