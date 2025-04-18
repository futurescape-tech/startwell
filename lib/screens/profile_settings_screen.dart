import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/services/user_profile_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:startwell/screens/faq_page.dart';
import 'package:provider/provider.dart';
import 'package:startwell/screens/privacy_policy_page.dart';
import 'package:startwell/screens/terms_conditions_page.dart';
import 'package:startwell/screens/startwell_location_page.dart';
import 'package:startwell/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/utils/routes.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _appVersion = '';
  String? _tempProfileImagePath;

  // Controllers for edit form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = UserProfileService();
      _userProfile = await userProfileService.getCurrentProfile();

      // Create a sample profile if none exists (for demo purposes)
      if (_userProfile == null) {
        _userProfile = await userProfileService.createSampleProfile();
      }

      // Initialize the text controllers
      _nameController.text = _userProfile?.name ?? '';
      _emailController.text = _userProfile?.email ?? '';
      _phoneController.text = _userProfile?.phoneNumber ?? '';
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      setState(() {
        _appVersion = 'Version information unavailable';
      });
    }
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedImage == null) return;

      // Save the image to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = path.join(directory.path, fileName);

      // Copy the file
      final File imageFile = File(pickedImage.path);
      await imageFile.copy(savedImagePath);

      setState(() {
        _tempProfileImagePath = savedImagePath;
      });

      // Update profile with the new image path
      await _userProfileService.updateProfile(
        profileImageUrl: savedImagePath,
      );

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      _showErrorSnackBar('Error updating profile picture: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorSnackBar('Name and email cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _userProfileService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadUserProfile();
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      await _userProfileService.clearProfile();
      // Return to login screen - replace with your login route
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', // Replace with your login route
          (route) => false,
        );
      }
    }
  }

  Future<void> _showTermsAndConditions() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsPage()),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  void _showEditProfileForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateProfile();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _navigateToFAQPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQPage()),
    );
  }

  void _navigateToLocationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StartwellLocationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile & Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
          backgroundColor: AppTheme.purple,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),

            // Settings Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings List
                  _buildSettingsItem(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    onTap: _showTermsAndConditions,
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: _showPrivacyPolicy,
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.question_answer,
                    title: 'FAQs',
                    onTap: _navigateToFAQPage,
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.location_on,
                    title: 'Startwell Location',
                    onTap: _navigateToLocationPage,
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    trailing: Text(
                      _appVersion,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    onTap: null,
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Connect With Us",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.purple,
                            )),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: FaIcon(
                                  FontAwesomeIcons.instagram,
                                  color: const Color(0xFFE1306C),
                                  size: 24,
                                ),
                                title: Text(
                                  "Instagram",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () => _launchURL(
                                    'https://www.instagram.com/startwell.official/'),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: FaIcon(
                                  FontAwesomeIcons.facebook,
                                  color: const Color(0xFF1877F2),
                                  size: 24,
                                ),
                                title: Text(
                                  "Facebook",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () => _launchURL(
                                    'https://business.facebook.com/business/loginpage/?next=https%3A%2F%2Fbusiness.facebook.com%2F%3Fnav_ref%3Dbiz_unified_f3_login_page_to_mbs&login_options%5B0%5D=FB&login_options%5B1%5D=IG&login_options%5B2%5D=SSO&config_ref=biz_login_tool_flavor_mbs'),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: FaIcon(
                                  FontAwesomeIcons.linkedin,
                                  color: const Color(0xFF0077B5),
                                  size: 24,
                                ),
                                title: Text(
                                  "LinkedIn",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () => _launchURL(
                                    'https://www.linkedin.com/company/startwellindia'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildSettingsItem(
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    textColor: AppTheme.error,
                    onTap: _showLogoutConfirmation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ProfileAvatar(
            userProfile: _userProfile,
            radius: 35,
            showEditIcon: true,
            onEditTap: _selectImage,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?.name ?? 'User Name',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?.email ?? 'user@example.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _userProfile?.phoneNumber ?? '+1234567890',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.purple),
            onPressed: _showEditProfileForm,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.purple,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }
}
