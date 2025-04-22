import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/ui_components.dart';
import 'package:startwell/screens/login_screen.dart';
import 'package:startwell/screens/dashboard_screen.dart';
import 'package:startwell/screens/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation states
  bool _showHeader = false;
  bool _showCard = false;
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showFields = false;
  bool _showButton = false;
  bool _showFooter = false;

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

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showButton = true);
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showFooter = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_formKey.currentState?.validate() ?? false) {
      // For now, just navigate to dashboard since this is a mock implementation
      Navigator.pushReplacement(
        context,
        _createPageRoute(const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                                'Sign Up',
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

              // Form content with animation
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
                                // Tiffin logo with animation
                                AnimatedOpacity(
                                  opacity: _showLogo ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedScale(
                                    scale: _showLogo ? 1.0 : 0.8,
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Title and intro with animation
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
                                            'Join StartWell',
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // App one-liner for sign up
                                        Text(
                                          "Create an account and serve a healthy routine!",
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
                                const SizedBox(height: 24),

                                // Form fields with animation
                                AnimatedOpacity(
                                  opacity: _showFields ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedSlide(
                                    offset: _showFields
                                        ? const Offset(0, 0)
                                        : const Offset(0, 0.2),
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    child: Column(
                                      children: [
                                        // Name field
                                        UIComponents.customTextField(
                                          label: 'Name',
                                          controller: _nameController,
                                          prefixIcon: const Icon(Icons.person,
                                              color: AppColors.primary),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

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
                                        const SizedBox(height: 16),

                                        // Mobile number field
                                        UIComponents.customTextField(
                                          label: 'Mobile Number',
                                          controller: _mobileController,
                                          keyboardType: TextInputType.phone,
                                          prefixIcon: const Icon(Icons.phone,
                                              color: AppColors.primary),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your mobile number';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Password field
                                        UIComponents.customTextField(
                                          label: 'Password',
                                          controller: _passwordController,
                                          obscureText: true,
                                          prefixIcon: const Icon(Icons.lock,
                                              color: AppColors.primary),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Confirm password field
                                        UIComponents.customTextField(
                                          label: 'Confirm Password',
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: true,
                                          prefixIcon: const Icon(Icons.lock,
                                              color: AppColors.primary),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value !=
                                                _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Sign up button with animation
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
                                              text: 'Sign Up',
                                              gradient:
                                                  AppTheme.purpleToDeepPurple,
                                              onPressed: _signup,
                                              height: 60,
                                              borderRadius: 50,
                                              elevated: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Login link with animation
                                AnimatedOpacity(
                                  opacity: _showFooter ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
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
