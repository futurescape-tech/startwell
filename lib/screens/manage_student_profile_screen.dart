import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/screens/order_summary_screen.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/widgets/bottom_sheets/active_subscription_bottom_sheet.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:startwell/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/widgets/student/student_card_widget.dart';
import 'package:startwell/services/cart_storage_service.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/utils/pre_order_date_calculator.dart';

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

  // Breakfast specific data
  final DateTime? breakfastStartDate;
  final DateTime? breakfastEndDate;
  final List<DateTime>? breakfastMealDates;
  final List<Meal>? breakfastSelectedMeals;
  final double? breakfastAmount;
  final String? breakfastPlanType;
  final List<bool>? breakfastSelectedWeekdays;

  // Lunch specific data
  final DateTime? lunchStartDate;
  final DateTime? lunchEndDate;
  final List<DateTime>? lunchMealDates;
  final List<Meal>? lunchSelectedMeals;
  final double? lunchAmount;
  final String? lunchPlanType;
  final List<bool>? lunchSelectedWeekdays;

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
    // New parameters for breakfast and lunch data
    this.breakfastStartDate,
    this.breakfastEndDate,
    this.breakfastMealDates,
    this.breakfastSelectedMeals,
    this.breakfastAmount,
    this.breakfastPlanType,
    this.breakfastSelectedWeekdays,
    this.lunchStartDate,
    this.lunchEndDate,
    this.lunchMealDates,
    this.lunchSelectedMeals,
    this.lunchAmount,
    this.lunchPlanType,
    this.lunchSelectedWeekdays,
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

  // Flag for testing - set to false to stop injecting a test student
  final bool _isTestingActiveSubscription = false;

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
    'Green Valley Convent',
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

    // Open a full-screen dialog instead of bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? 'Edit Student Profile' : 'Create Student Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.purpleToDeepPurple,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Name Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSchool,
                      decoration: InputDecoration(
                        labelText: 'Select School Name',
                        prefixIcon: Icon(
                          Icons.school,
                          color: AppTheme.purple,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.purple,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: dummySchools.map((school) {
                        return DropdownMenuItem<String>(
                          value: school,
                          child: Text(
                            school,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textDark,
                            ),
                          ),
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
                    // Gradient Create/Update button below the form
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleToDeepPurple,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.deepPurple.withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                final wasEditing =
                                    _isEditing; // Capture before save
                                _saveStudentProfile();
                                if (wasEditing) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'student updated successfully',
                                          style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'student created successfully',
                                          style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  _isEditing ? 'Update' : 'Create',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          prefixIcon: Icon(
            icon,
            color: AppTheme.purple,
            size: 20,
          ),
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
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
      ),
    );
  }

  // Save or update student profile
  void _saveStudentProfile() {
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
          hasActiveLunch: _studentProfiles[_editingStudentIndex].hasActiveLunch,
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

    _clearForm();
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
                left: BorderSide(color: AppTheme.deepPurple, width: 3),
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
          colors: [Colors.white, Color(0xFFF7F7F7)],
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
          //   ),
          // ),
        ],
      ),
    );
  }

  // Select a student
  void _selectStudent(Student student) {
    if (widget.isManagementMode) {
      return;
    }
    HapticFeedback.lightImpact();

    // Set the selected student
    setState(() {
      _selectedStudent = student;
    });

    print('Selected student: ${student.name}');
    print('Has active breakfast: ${student.hasActiveBreakfast}');
    print('Has active lunch: ${student.hasActiveLunch}');

    // Check if student has active subscriptions
    bool hasActiveBreakfast =
        student.hasActiveBreakfast && student.breakfastPlanEndDate != null;
    bool hasActiveLunch =
        student.hasActiveLunch && student.lunchPlanEndDate != null;

    // Determine what meal types are being selected by the parent
    bool isSelectingBreakfast = widget.mealType == 'breakfast' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasBreakfastInCart;
    bool isSelectingLunch = widget.mealType == 'lunch' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasLunchInCart;
    bool isSelectingBoth = isSelectingBreakfast && isSelectingLunch;

    print('DEBUG: Selecting breakfast: $isSelectingBreakfast');
    print('DEBUG: Selecting lunch: $isSelectingLunch');
    print('DEBUG: Selecting both: $isSelectingBoth');
    print('DEBUG: Has active breakfast: $hasActiveBreakfast');
    print('DEBUG: Has active lunch: $hasActiveLunch');

    // Check which scenario applies
    bool shouldShowBottomSheet = false;

    // Always show the bottom sheet if there's an active subscription that matches
    // what the parent is trying to select
    if ((isSelectingBreakfast && hasActiveBreakfast) ||
        (isSelectingLunch && hasActiveLunch)) {
      shouldShowBottomSheet = true;
    }

    if (shouldShowBottomSheet) {
      // Student has relevant active subscriptions, show bottom sheet
      print('Student has relevant active subscriptions, showing bottom sheet');
      _showActiveSubscriptionsBottomSheet(student);
    } else {
      // Student has no relevant active subscriptions, redirect to order summary
      print(
        'Student has no relevant active subscriptions, redirecting to order summary',
      );
      _proceedToOrderSummary();
    }
  }

  // Show bottom sheet with active subscription information
  void _showActiveSubscriptionsBottomSheet(Student student) {
    // Determine what meal types are being selected by the parent
    bool isSelectingBreakfast = widget.mealType == 'breakfast' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasBreakfastInCart;
    bool isSelectingLunch = widget.mealType == 'lunch' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasLunchInCart;
    bool isSelectingBoth = isSelectingBreakfast && isSelectingLunch;

    // Check if student has active subscriptions
    bool hasActiveBreakfast =
        student.hasActiveBreakfast && student.breakfastPlanEndDate != null;
    bool hasActiveLunch =
        student.hasActiveLunch && student.lunchPlanEndDate != null;

    // Variables to track bottom sheet options
    bool showBreakfastPreorder = false;
    bool showLunchPreorder = false;
    String scenarioDescription = "";

    // Determine whether to show pre-order options for each meal type
    // Show breakfast pre-order if parent is selecting breakfast and student has active breakfast plan
    if (isSelectingBreakfast && hasActiveBreakfast) {
      showBreakfastPreorder = true;
    }

    // Show lunch pre-order if parent is selecting lunch and student has active lunch plan
    if (isSelectingLunch && hasActiveLunch) {
      showLunchPreorder = true;
    }

    // Set description based on what's being shown
    if (showBreakfastPreorder && showLunchPreorder) {
      scenarioDescription = "Pre-order available for both breakfast and lunch";
    } else if (showBreakfastPreorder) {
      scenarioDescription = "Pre-order available for breakfast only";
    } else if (showLunchPreorder) {
      scenarioDescription = "Pre-order available for lunch only";
    }

    print('DEBUG: ===== ACTIVE SUBSCRIPTION BOTTOM SHEET SETUP =====');
    print('DEBUG: Active scenario: $scenarioDescription');
    print('DEBUG: Show breakfast preorder: $showBreakfastPreorder');
    print('DEBUG: Show lunch preorder: $showLunchPreorder');

    // Get the proper weekday selections for each meal type
    List<bool>? breakfastSelectedWeekdays;
    List<bool>? lunchSelectedWeekdays;

    // For breakfast, use the specific breakfast weekdays if available
    if (widget.breakfastSelectedWeekdays != null) {
      // Create a completely new array instead of using List.from which can still cause issues
      breakfastSelectedWeekdays = List<bool>.filled(5, false);
      for (int i = 0;
          i < widget.breakfastSelectedWeekdays!.length && i < 5;
          i++) {
        breakfastSelectedWeekdays[i] = widget.breakfastSelectedWeekdays![i];
      }
      print(
          'DEBUG: Using breakfast-specific weekdays: $breakfastSelectedWeekdays');
    } else if (isSelectingBreakfast && widget.selectedWeekdays != null) {
      // Fallback to general weekdays for breakfast if no specific ones
      breakfastSelectedWeekdays = List<bool>.filled(5, false);
      for (int i = 0; i < widget.selectedWeekdays!.length && i < 5; i++) {
        breakfastSelectedWeekdays[i] = widget.selectedWeekdays![i];
      }
      print(
          'DEBUG: Using general weekdays for breakfast: $breakfastSelectedWeekdays');
    } else {
      // Default to Mon-Fri if no weekdays are provided
      breakfastSelectedWeekdays = List.generate(5, (_) => true);
      print('DEBUG: Using default Mon-Fri for breakfast');
    }

    // For lunch, use the specific lunch weekdays if available
    if (widget.lunchSelectedWeekdays != null) {
      // Create a completely new array instead of using List.from which can still cause issues
      lunchSelectedWeekdays = List<bool>.filled(5, false);
      for (int i = 0; i < widget.lunchSelectedWeekdays!.length && i < 5; i++) {
        lunchSelectedWeekdays[i] = widget.lunchSelectedWeekdays![i];
      }
      print('DEBUG: Using lunch-specific weekdays: $lunchSelectedWeekdays');
    } else if (isSelectingLunch && widget.selectedWeekdays != null) {
      // Fallback to general weekdays for lunch if no specific ones
      lunchSelectedWeekdays = List<bool>.filled(5, false);
      for (int i = 0; i < widget.selectedWeekdays!.length && i < 5; i++) {
        lunchSelectedWeekdays[i] = widget.selectedWeekdays![i];
      }
      print('DEBUG: Using general weekdays for lunch: $lunchSelectedWeekdays');
    } else {
      // Default to Mon-Fri if no weekdays are provided
      lunchSelectedWeekdays = List.generate(5, (_) => true);
      print('DEBUG: Using default Mon-Fri for lunch');
    }

    // Print delivery modes for debugging
    if (breakfastSelectedWeekdays != null) {
      String breakfastDeliveryMode =
          PreOrderDateCalculator.getDeliveryModeText(breakfastSelectedWeekdays);
      print(
          'DEBUG: Calculated breakfast delivery mode: $breakfastDeliveryMode');
    }
    if (lunchSelectedWeekdays != null) {
      String lunchDeliveryMode =
          PreOrderDateCalculator.getDeliveryModeText(lunchSelectedWeekdays);
      print('DEBUG: Calculated lunch delivery mode: $lunchDeliveryMode');
    }

    // Get plan types for both meal types
    String? breakfastPlanType = widget.breakfastPlanType ?? widget.planType;
    String? lunchPlanType = widget.lunchPlanType ?? widget.planType;

    print('DEBUG: ==== BEFORE LAUNCHING BOTTOM SHEET ====');
    print('DEBUG: Breakfast selected weekdays: $breakfastSelectedWeekdays');
    print('DEBUG: Lunch selected weekdays: $lunchSelectedWeekdays');
    // Make sure these arrays are different objects in memory
    print(
        'DEBUG: Are weekday arrays the same object? ${identical(breakfastSelectedWeekdays, lunchSelectedWeekdays)}');
    print('DEBUG: =====================================');

    // Show bottom sheet and track when it's closed
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ActiveSubscriptionBottomSheet(
        student: student,
        showBreakfastPreorder: showBreakfastPreorder,
        showLunchPreorder: showLunchPreorder,
        // Pass plan types and independent delivery day arrays to bottom sheet
        breakfastPlanType: breakfastPlanType,
        lunchPlanType: lunchPlanType,
        breakfastSelectedWeekdays: breakfastSelectedWeekdays,
        lunchSelectedWeekdays: lunchSelectedWeekdays,
        onContinue: (
          DateTime? breakfastPreorderDate,
          DateTime? lunchPreorderDate,
          String? breakfastDeliveryMode,
          String? lunchDeliveryMode,
        ) {
          print('DEBUG: ===== RECEIVED FROM BOTTOM SHEET =====');
          print(
              'DEBUG: Selected breakfast preorder date: $breakfastPreorderDate');
          print('DEBUG: Selected lunch preorder date: $lunchPreorderDate');
          print('DEBUG: Final breakfast delivery mode: $breakfastDeliveryMode');
          print('DEBUG: Final lunch delivery mode: $lunchDeliveryMode');
          print('DEBUG: ======================================');

          // Navigate to order summary with pre-order dates and separate delivery modes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSummaryScreen(
                planType: widget.planType ?? 'Single Day',
                isCustomPlan: widget.isCustomPlan ?? false,
                selectedWeekdays:
                    widget.selectedWeekdays ?? List.filled(5, false),
                startDate: widget.startDate ?? DateTime.now(),
                endDate: widget.endDate ?? DateTime.now(),
                mealDates: widget.mealDates ?? [],
                totalAmount: widget.totalAmount ?? 0.0,
                selectedMeals: widget.selectedMeals ?? [],
                isExpressOrder: widget.isExpressOrder ?? false,
                selectedStudent: _selectedStudent,
                mealType: widget.mealType,
                breakfastPreOrderDate: breakfastPreorderDate,
                lunchPreOrderDate: lunchPreorderDate,
                isPreOrder:
                    breakfastPreorderDate != null || lunchPreorderDate != null,
                // Pass specific delivery modes for each meal type
                breakfastDeliveryMode: breakfastDeliveryMode,
                lunchDeliveryMode: lunchDeliveryMode,
                // Pass breakfast and lunch specific data
                breakfastStartDate: widget.breakfastStartDate,
                breakfastEndDate: widget.breakfastEndDate,
                breakfastMealDates: widget.breakfastMealDates,
                breakfastSelectedMeals: widget.breakfastSelectedMeals,
                breakfastAmount: widget.breakfastAmount,
                breakfastPlanType: widget.breakfastPlanType,
                breakfastSelectedWeekdays: breakfastSelectedWeekdays,
                lunchStartDate: widget.lunchStartDate,
                lunchEndDate: widget.lunchEndDate,
                lunchMealDates: widget.lunchMealDates,
                lunchSelectedMeals: widget.lunchSelectedMeals,
                lunchAmount: widget.lunchAmount,
                lunchPlanType: widget.lunchPlanType,
                lunchSelectedWeekdays: lunchSelectedWeekdays,
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // This runs when the bottom sheet is dismissed without pressing continue
      // Check if the user is still on this screen
      if (mounted) {
        // If the user navigated away (like to OrderSummaryScreen), they continued
        // If they didn't, then they dismissed the sheet without continuing
        // We can check for active routes, but a simpler approach:
        // If they're still on this screen and selected a student but didn't proceed,
        // then unselect the student
        if (_selectedStudent?.id == student.id) {
          print(
              'DEBUG: Bottom sheet dismissed without continuing - unselecting student');
          setState(() {
            _selectedStudent = null;
          });
        }
      }
    });
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Navigate to order summary screen with selected student
  void _proceedToOrderSummary() {
    // Check if a student is selected
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a student to continue',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set meal selections based on mealType parameter
    if (widget.mealType == 'breakfast') {
      MealSelectionManager.hasBreakfastInCart = true;
      MealSelectionManager.hasLunchInCart = false;
    } else if (widget.mealType == 'lunch') {
      MealSelectionManager.hasBreakfastInCart = false;
      MealSelectionManager.hasLunchInCart = true;
    } else if (widget.mealType == 'both') {
      MealSelectionManager.hasBreakfastInCart = true;
      MealSelectionManager.hasLunchInCart = true;
    }

    // Check if student has active subscriptions
    bool hasActiveBreakfast = _selectedStudent!.hasActiveBreakfast &&
        _selectedStudent!.breakfastPlanEndDate != null;
    bool hasActiveLunch = _selectedStudent!.hasActiveLunch &&
        _selectedStudent!.lunchPlanEndDate != null;

    // Determine what meal types are being selected by the parent
    bool isSelectingBreakfast = widget.mealType == 'breakfast' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasBreakfastInCart;
    bool isSelectingLunch = widget.mealType == 'lunch' ||
        widget.mealType == 'both' ||
        MealSelectionManager.hasLunchInCart;

    // Debug info
    print('DEBUG: _proceedToOrderSummary - mealType: ${widget.mealType}');
    print(
        'DEBUG: _proceedToOrderSummary - isSelectingBreakfast: $isSelectingBreakfast');
    print(
        'DEBUG: _proceedToOrderSummary - isSelectingLunch: $isSelectingLunch');
    print(
        'DEBUG: _proceedToOrderSummary - hasActiveBreakfast: $hasActiveBreakfast');
    print('DEBUG: _proceedToOrderSummary - hasActiveLunch: $hasActiveLunch');

    // Log weekday selections for debugging
    if (widget.selectedWeekdays != null) {
      print(
          'DEBUG: _proceedToOrderSummary - selectedWeekdays: ${widget.selectedWeekdays}');
    }
    if (widget.breakfastSelectedWeekdays != null) {
      print(
          'DEBUG: _proceedToOrderSummary - breakfastSelectedWeekdays: ${widget.breakfastSelectedWeekdays}');
    }
    if (widget.lunchSelectedWeekdays != null) {
      print(
          'DEBUG: _proceedToOrderSummary - lunchSelectedWeekdays: ${widget.lunchSelectedWeekdays}');
    }

    if (widget.breakfastStartDate != null || widget.lunchStartDate != null) {
      print('DEBUG: Using separate date information for breakfast and lunch');
      print('DEBUG: breakfastStartDate: ${widget.breakfastStartDate}');
      print('DEBUG: breakfastEndDate: ${widget.breakfastEndDate}');
      print('DEBUG: lunchStartDate: ${widget.lunchStartDate}');
      print('DEBUG: lunchEndDate: ${widget.lunchEndDate}');
    }

    // Calculate delivery modes for breakfast and lunch if custom plan
    String? breakfastDeliveryMode;
    String? lunchDeliveryMode;

    if (widget.isCustomPlan == true) {
      // For breakfast, use breakfast-specific weekdays if available, otherwise fallback to general
      if (widget.breakfastSelectedWeekdays != null && isSelectingBreakfast) {
        breakfastDeliveryMode = PreOrderDateCalculator.getDeliveryModeText(
          widget.breakfastSelectedWeekdays!,
        );
        print(
            'DEBUG: Using breakfast-specific weekdays for delivery mode: ${widget.breakfastSelectedWeekdays}');
      } else if (widget.selectedWeekdays != null && isSelectingBreakfast) {
        breakfastDeliveryMode = PreOrderDateCalculator.getDeliveryModeText(
          widget.selectedWeekdays!,
        );
        print(
            'DEBUG: Using general weekdays for breakfast delivery mode: ${widget.selectedWeekdays}');
      }

      // For lunch, use lunch-specific weekdays if available, otherwise fallback to general
      if (widget.lunchSelectedWeekdays != null && isSelectingLunch) {
        lunchDeliveryMode = PreOrderDateCalculator.getDeliveryModeText(
          widget.lunchSelectedWeekdays!,
        );
        print(
            'DEBUG: Using lunch-specific weekdays for delivery mode: ${widget.lunchSelectedWeekdays}');
      } else if (widget.selectedWeekdays != null && isSelectingLunch) {
        lunchDeliveryMode = PreOrderDateCalculator.getDeliveryModeText(
          widget.selectedWeekdays!,
        );
        print(
            'DEBUG: Using general weekdays for lunch delivery mode: ${widget.selectedWeekdays}');
      }
    } else {
      // For regular plans, use Monday to Friday format
      breakfastDeliveryMode = "Monday to Friday";
      lunchDeliveryMode = "Monday to Friday";
      print('DEBUG: Using Monday to Friday for regular plan delivery modes');
    }

    print('DEBUG: Final breakfast delivery mode: $breakfastDeliveryMode');
    print('DEBUG: Final lunch delivery mode: $lunchDeliveryMode');

    // Navigate directly to order summary
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          planType: widget.planType ?? 'Single Day',
          isCustomPlan: widget.isCustomPlan ?? false,
          selectedWeekdays: widget.selectedWeekdays ?? List.filled(5, false),
          startDate: widget.startDate ?? DateTime.now(),
          endDate: widget.endDate ?? DateTime.now(),
          mealDates: widget.mealDates ?? [],
          totalAmount: widget.totalAmount ?? 0.0,
          selectedMeals: widget.selectedMeals ?? [],
          isExpressOrder: widget.isExpressOrder ?? false,
          selectedStudent: _selectedStudent,
          mealType: widget.mealType,
          breakfastPreOrderDate: null,
          lunchPreOrderDate: null,
          isPreOrder: false,
          // Pass specific delivery modes for each meal type
          breakfastDeliveryMode: breakfastDeliveryMode,
          lunchDeliveryMode: lunchDeliveryMode,
          // Pass breakfast and lunch specific data
          breakfastStartDate: widget.breakfastStartDate,
          breakfastEndDate: widget.breakfastEndDate,
          breakfastMealDates: widget.breakfastMealDates,
          breakfastSelectedMeals: widget.breakfastSelectedMeals,
          breakfastAmount: widget.breakfastAmount,
          breakfastPlanType: widget.breakfastPlanType,
          breakfastSelectedWeekdays: widget.breakfastSelectedWeekdays,
          lunchStartDate: widget.lunchStartDate,
          lunchEndDate: widget.lunchEndDate,
          lunchMealDates: widget.lunchMealDates,
          lunchSelectedMeals: widget.lunchSelectedMeals,
          lunchAmount: widget.lunchAmount,
          lunchPlanType: widget.lunchPlanType,
          lunchSelectedWeekdays: widget.lunchSelectedWeekdays,
        ),
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
        // Pop the current screen to return to the previous screen (Cart Screen)
        Navigator.pop(context);
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              // Store the current selection in cart before navigating back
              if (widget.selectedMeals?.isNotEmpty == true) {
                // First, load existing cart items
                final existingCartItems =
                    await CartStorageService.loadCartItems();

                // Create new cart item
                final cartItem = {
                  'planType': widget.planType,
                  'isCustomPlan': widget.isCustomPlan,
                  'selectedWeekdays': widget.selectedWeekdays,
                  'startDate': widget.startDate,
                  'endDate': widget.endDate,
                  'mealDates': widget.mealDates,
                  'totalAmount': widget.totalAmount,
                  'selectedMeals': widget.selectedMeals,
                  'isExpressOrder': widget.isExpressOrder,
                  'mealType': widget.mealType,
                };

                // Check if we already have this meal type in cart
                bool hasMealType = existingCartItems.any(
                  (item) => item['mealType'] == widget.mealType,
                );

                // If we don't have this meal type, add it to existing items
                if (!hasMealType) {
                  existingCartItems.add(cartItem);
                }

                // Save all cart items
                await CartStorageService.saveCartItems(existingCartItems);

                // Update meal selection manager
                if (widget.mealType == 'breakfast') {
                  MealSelectionManager.hasBreakfastInCart = true;
                } else if (widget.mealType == 'lunch') {
                  MealSelectionManager.hasLunchInCart = true;
                }
              }

              // Pop the current screen to return to the previous screen (Cart Screen)
              Navigator.pop(context);
            },
          ),
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
                                child: const Icon(Icons.add, size: 16),
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
                              width: double.infinity,
                              height: 60,
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
                              child: ElevatedButton(
                                onPressed:
                                    (!isExpressOrder || isWithinExpressWindow)
                                        ? _proceedToOrderSummary
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
