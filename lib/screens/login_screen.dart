import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/utils/ui_components.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/screens/forgot_password_screen.dart';
import 'package:startwell/screens/signup_screen.dart';
import 'package:startwell/screens/dashboard_screen.dart';
import 'package:startwell/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool useMobileLogin = true;

  // Animation states
  bool _showHeader = false;
  bool _showCard = false;
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showToggle = false;
  bool _showFields = false;
  bool _showFooter = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

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
      if (mounted) setState(() => _showToggle = true);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showFields = true);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showFooter = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleLoginMethod() {
    setState(() {
      useMobileLogin = !useMobileLogin;
    });
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushReplacement(
        context,
        _createPageRoute(const MainScreen()),
      );
    }
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
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                                'Login',
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

              // Form content in scrollable area
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
                                // Logo and Welcome text with animation
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
                                          Icons.lunch_dining,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Welcome text with animation
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
                                        ShaderMask(
                                          shaderCallback: (bounds) => AppColors
                                              .purpleToOrange
                                              .createShader(bounds),
                                          child: Text(
                                            'Welcome Back',
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // App one-liner for login
                                        Text(
                                          "Start your day with a click – access your child's nutrition now!",
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

                                // Toggle buttons for login method with animation
                                AnimatedOpacity(
                                  opacity: _showToggle ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedSlide(
                                    offset: _showToggle
                                        ? const Offset(0, 0)
                                        : const Offset(0, 0.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: useMobileLogin
                                                  ? null
                                                  : _toggleLoginMethod,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                decoration: BoxDecoration(
                                                  gradient: useMobileLogin
                                                      ? AppTheme.orangeToYellow
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Mobile + OTP',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: useMobileLogin
                                                          ? Colors.white
                                                          : AppColors
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: useMobileLogin
                                                  ? _toggleLoginMethod
                                                  : null,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                decoration: BoxDecoration(
                                                  gradient: !useMobileLogin
                                                      ? AppTheme.orangeToYellow
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Email + Password',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: !useMobileLogin
                                                          ? Colors.white
                                                          : AppColors
                                                              .textSecondary,
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
                                const SizedBox(height: 30),

                                // Input fields with animation
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
                                        // Mobile/Email input field
                                        useMobileLogin
                                            ? UIComponents.customTextField(
                                                label: 'Mobile Number',
                                                controller: _mobileController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                prefixIcon: const Icon(
                                                    Icons.phone,
                                                    color: AppColors.primary),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter your mobile number';
                                                  }
                                                  return null;
                                                },
                                              )
                                            : UIComponents.customTextField(
                                                label: 'Email',
                                                controller: _emailController,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                prefixIcon: const Icon(
                                                    Icons.email,
                                                    color: AppColors.primary),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter your email';
                                                  }
                                                  return null;
                                                },
                                              ),
                                        const SizedBox(height: 20),

                                        // OTP/Password input field
                                        useMobileLogin
                                            ? UIComponents.customTextField(
                                                label: 'OTP',
                                                controller: _otpController,
                                                keyboardType:
                                                    TextInputType.number,
                                                prefixIcon: const Icon(
                                                    Icons.lock,
                                                    color: AppColors.primary),
                                                obscureText: true,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter OTP';
                                                  }
                                                  return null;
                                                },
                                              )
                                            : UIComponents.customTextField(
                                                label: 'Password',
                                                controller: _passwordController,
                                                prefixIcon: const Icon(
                                                    Icons.lock,
                                                    color: AppColors.primary),
                                                obscureText: true,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter your password';
                                                  }
                                                  return null;
                                                },
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Forgot password link and buttons with animation
                                AnimatedOpacity(
                                  opacity: _showFooter ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedSlide(
                                    offset: _showFooter
                                        ? const Offset(0, 0)
                                        : const Offset(0, 0.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    child: Column(
                                      children: [
                                        // Forgot password link
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                _createPageRoute(
                                                    const ForgotPasswordScreen()),
                                              );
                                            },
                                            child: Text(
                                              'Forgot Password?',
                                              style: GoogleFonts.poppins(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30),

                                        // Login button
                                        UIComponents.gradientButton(
                                          text: 'Login',
                                          gradient: AppTheme.purpleToDeepPurple,
                                          onPressed: _login,
                                          height: 56,
                                          borderRadius: 16,
                                          elevated: true,
                                        ),
                                        const SizedBox(height: 30),

                                        // Sign up link
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have an account?",
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
                                                      const SignupScreen()),
                                                );
                                              },
                                              child: Text(
                                                'Sign Up',
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
