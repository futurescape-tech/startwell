import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/ui_components.dart';
import 'package:startwell/screens/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isCodeSent = false;
  bool _isVerified = false;

  // Animation states
  bool _showHeader = false;
  bool _showCard = false;
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showFields = false;
  bool _showButton = false;
  bool _showFooter = false;

  // Add controllers for the additional fields
  final _verificationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Trigger animations with staggered delays
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showHeader = true);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showCard = true);
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showLogo = true);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showTitle = true);
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showFields = true);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showButton = true);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showFooter = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isCodeSent = true;
      });
    }
  }

  void _verifyCode() {
    setState(() {
      _isVerified = true;
    });
  }

  void _resetPassword() {
    // In a real app, we'd submit the new password to the backend
    // For now, just navigate back to the login screen
    Navigator.pushReplacement(
      context,
      _createPageRoute(const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepPurple,
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar with animation
              AnimatedSlide(
                offset:
                    _showHeader ? const Offset(0, 0) : const Offset(0, -0.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _showHeader ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.orangeToYellow.createShader(bounds),
                              child: Text(
                                'Reset Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content with animation
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedOpacity(
                    opacity: _showCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset:
                          _showCard ? const Offset(0, 0) : const Offset(0, 0.2),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: UIComponents.customCard(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 24,
                          elevated: true,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo with animation
                                AnimatedOpacity(
                                  opacity: _showLogo ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedScale(
                                    scale: _showLogo ? 1.0 : 0.8,
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Center(
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppTheme.purpleToDeepPurple,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.lock_reset,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title with animation
                                AnimatedOpacity(
                                  opacity: _showTitle ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedSlide(
                                    offset: _showTitle
                                        ? const Offset(0, 0)
                                        : const Offset(0, 0.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Column(
                                      children: [
                                        // Title
                                        ShaderMask(
                                          shaderCallback: (bounds) => AppColors
                                              .purpleToOrange
                                              .createShader(bounds),
                                          child: Text(
                                            !_isVerified
                                                ? (!_isCodeSent
                                                    ? 'Forgot Password?'
                                                    : 'Verify Code')
                                                : 'Set New Password',
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Subtitle
                                        Text(
                                          !_isVerified
                                              ? (!_isCodeSent
                                                  ? "Don't worry! It happens. Please enter the email associated with your account."
                                                  : "We've sent a verification code to your email. Please enter it below.")
                                              : "Please enter your new password.",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Form fields with animation
                                AnimatedOpacity(
                                  opacity: _showFields ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedSlide(
                                    offset: _showFields
                                        ? const Offset(0, 0)
                                        : const Offset(0, 0.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Column(
                                      children: [
                                        if (!_isCodeSent)
                                          // Email field
                                          UIComponents.customTextField(
                                            label: 'Email',
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            prefixIcon: const Icon(Icons.email,
                                                color: AppColors.primary),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your email';
                                              }
                                              // Simple email validation
                                              if (!value.contains('@') ||
                                                  !value.contains('.')) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            },
                                          ),
                                        if (_isCodeSent && !_isVerified)
                                          // Verification code field
                                          UIComponents.customTextField(
                                            label: 'Verification Code',
                                            keyboardType: TextInputType.number,
                                            controller:
                                                _verificationCodeController,
                                            prefixIcon: const Icon(
                                                Icons.security,
                                                color: AppColors.primary),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter the verification code';
                                              }
                                              return null;
                                            },
                                          ),
                                        if (_isVerified) ...[
                                          // New password field
                                          UIComponents.customTextField(
                                            label: 'New Password',
                                            obscureText: true,
                                            controller: _newPasswordController,
                                            prefixIcon: const Icon(Icons.lock,
                                                color: AppColors.primary),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a new password';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          // Confirm new password field
                                          UIComponents.customTextField(
                                            label: 'Confirm New Password',
                                            obscureText: true,
                                            controller:
                                                _confirmPasswordController,
                                            prefixIcon: const Icon(Icons.lock,
                                                color: AppColors.primary),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your new password';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Action button with animation
                                AnimatedOpacity(
                                  opacity: _showButton ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedScale(
                                    scale: _showButton ? 1.0 : 0.95,
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    child: AnimatedSlide(
                                      offset: _showButton
                                          ? const Offset(0, 0)
                                          : const Offset(0, 0.2),
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      curve: Curves.easeOutCubic,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                            begin: 0,
                                            end: _showButton ? 10 : 0),
                                        duration:
                                            const Duration(milliseconds: 1000),
                                        builder: (context, value, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: value,
                                                  spreadRadius: value * 0.3,
                                                )
                                              ],
                                            ),
                                            child: UIComponents.gradientButton(
                                              text: !_isVerified
                                                  ? (!_isCodeSent
                                                      ? 'Send Code'
                                                      : 'Verify')
                                                  : 'Reset Password',
                                              gradient:
                                                  AppTheme.purpleToDeepPurple,
                                              onPressed: !_isVerified
                                                  ? (!_isCodeSent
                                                      ? _sendCode
                                                      : _verifyCode)
                                                  : _resetPassword,
                                              height: 56,
                                              borderRadius: 16,
                                              elevated: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Footer with animation
                                AnimatedOpacity(
                                  opacity: _showFooter ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Remember your password?',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            _createPageRoute(
                                                const LoginScreen()),
                                          );
                                        },
                                        child: Text(
                                          'Login',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    );
  }

  // Custom page route with smooth transition
  PageRouteBuilder _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 800),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeOutCubic;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return FadeTransition(
          opacity: animation.drive(tween),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
