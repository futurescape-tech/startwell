import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/screens/order_summary_screen.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:intl/intl.dart';

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
  final _schoolAddressController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // For editing an existing student
  bool _isEditing = false;
  int _editingStudentIndex = -1;

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
    _schoolAddressController.dispose();
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
      _editingStudentIndex =
          _studentProfiles.indexWhere((s) => s.id == student!.id);
      _schoolNameController.text = student!.schoolName;
      _studentNameController.text = student.name;
      _classController.text = student.className;
      _divisionController.text = student.division;
      _floorController.text = student.floor;
      _allergiesController.text = student.allergies;
      _schoolAddressController.text = student.schoolAddress;
    } else {
      // Clear the form for a new student
      _schoolNameController.clear();
      _studentNameController.clear();
      _classController.clear();
      _divisionController.clear();
      _floorController.clear();
      _allergiesController.clear();
      _schoolAddressController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing
                          ? 'Edit Student Profile'
                          : 'Create Student Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // School Name
                TextFormField(
                  controller: _schoolNameController,
                  decoration: InputDecoration(
                    labelText: 'School Name',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter school name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Student Name
                TextFormField(
                  controller: _studentNameController,
                  decoration: InputDecoration(
                    labelText: 'Student Name',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Class
                TextFormField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter class';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Division
                TextFormField(
                  controller: _divisionController,
                  decoration: InputDecoration(
                    labelText: 'Division',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter division';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Floor
                TextFormField(
                  controller: _floorController,
                  decoration: InputDecoration(
                    labelText: 'Floor',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter floor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Medical Allergies (optional)
                TextFormField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Medical Allergies (Optional)',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // School Address
                TextFormField(
                  controller: _schoolAddressController,
                  decoration: InputDecoration(
                    labelText: 'School Address',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter school address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveStudentProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
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
        schoolAddress: _schoolAddressController.text,
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
        _profileService
            .updateStudentProfile(_studentProfiles[_editingStudentIndex]);
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
      _classController.clear();
      _divisionController.clear();
      _floorController.clear();
      _allergiesController.clear();
      _schoolAddressController.clear();
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
      final String? validationError =
          MealPlanValidator.validateMealPlan(student, planType);

      if (validationError != null) {
        // Show error message
        _showValidationErrorDialog(validationError);
        return;
      }
    }

    setState(() {
      if (_selectedStudent?.id == student.id) {
        _selectedStudent = null;
      } else {
        _selectedStudent = student;
      }
    });
  }

  // Show validation error dialog
  void _showValidationErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cannot Select This Student',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppTheme.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to order summary
  void _proceedToOrderSummary() {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a student profile to continue',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          planType: widget.planType!,
          isCustomPlan: widget.isCustomPlan!,
          selectedWeekdays: widget.selectedWeekdays!,
          startDate: widget.startDate!,
          endDate: widget.endDate!,
          mealDates: widget.mealDates!,
          totalAmount: widget.totalAmount!,
          selectedMeals: widget.selectedMeals!,
          isExpressOrder: widget.isExpressOrder!,
          selectedStudent: _selectedStudent!,
          mealType: widget.mealType,
        ),
      ),
    );
  }

  // Confirm and delete student profile
  void _confirmDeleteStudentProfile(Student student) {
    if (student.hasActivePlan) {
      // Show message that profile cannot be deleted while having active plans
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete ${student.name}\'s profile while they have active meal plans',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${student.name}\'s profile?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _deleteStudentProfile(student);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpressOrder = widget.isExpressOrder ?? false;
    final bool isWithinExpressWindow =
        isExpressOrder ? MealPlanValidator.isWithinExpressWindow() : true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isManagementMode
              ? 'Student Profiles'
              : 'Select Student Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
                        ? "Manage Profiles"
                        : "Student Profile",
                    message: widget.isManagementMode
                        ? "View, create, edit, or delete student profiles."
                        : "Please select or create a student profile to continue with your subscription.",
                    type: InfoBannerType.info,
                  ),

                  const SizedBox(height: 24),

                  // Student profiles list
                  Expanded(
                    child: _studentProfiles.isEmpty
                        ? _buildEmptyState()
                        : _buildStudentsList(),
                  ),

                  // Create new profile button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStudentForm(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.purple),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_selectedStudent != null &&
                                (!isExpressOrder || isWithinExpressWindow))
                            ? _proceedToOrderSummary
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isExpressOrder ? Colors.orange : AppTheme.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                      Center(
                        child: Text(
                          'Express ordering is currently unavailable',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No student profile found.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isManagementMode
                ? 'Create a profile to manage your students.'
                : 'Please create one to continue your subscription.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showStudentForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Student Profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Student profiles list
  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _studentProfiles.length,
      itemBuilder: (context, index) {
        final student = _studentProfiles[index];
        final isSelected = _selectedStudent?.id == student.id;
        final hasActivePlan =
            student.hasActiveBreakfast || student.hasActiveLunch;

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
            onTap: () => _selectStudent(student),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selection indicator (only in selection mode)
                      if (!widget.isManagementMode)
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _selectStudent(student),
                            activeColor: AppTheme.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      if (!widget.isManagementMode) const SizedBox(width: 8),

                      // Student details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.schoolName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class ${student.className}, Division ${student.division}, Floor ${student.floor}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            if (student.allergies.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Allergies: ${student.allergies}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Actions
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showStudentForm(student: student),
                            tooltip: 'Edit',
                          ),
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
                                  onPressed: () =>
                                      _confirmDeleteStudentProfile(student),
                                  tooltip: 'Delete student profile',
                                ),
                        ],
                      ),
                    ],
                  ),

                  // Active meal plan information
                  if (hasActivePlan && !widget.isManagementMode) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: student.hasActiveBreakfast &&
                                  student.hasActiveLunch
                              ? Colors.orange
                              : AppTheme.purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            MealPlanValidator.getActivePlanLabel(student),
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
      },
    );
  }
}
