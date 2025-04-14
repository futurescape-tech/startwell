import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/utils/ui_components.dart';
import 'package:startwell/widgets/shimmer/launch_shimmer.dart';
import 'package:startwell/screens/login_screen.dart';
import 'package:startwell/screens/signup_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  // Animation states
  bool _showLogo = false;
  bool _showTitle = false;
  bool _showMessage = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    // Trigger animations with staggered delays
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showLogo = true);
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showTitle = true);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showMessage = true);
    });

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _showButtons = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = screenHeight * 0.15; // Responsive logo size

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryToDeepPurple,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.08), // Responsive spacing

                // Logo with animations
                AnimatedOpacity(
                  opacity: _showLogo ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset:
                        _showLogo ? const Offset(0, 0) : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: AnimatedScale(
                      scale: _showLogo ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.purpleToOrange,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]),
                        child: Icon(
                          Icons.lunch_dining,
                          size: logoSize * 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                // App title with animations
                AnimatedOpacity(
                  opacity: _showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset:
                        _showTitle ? const Offset(0, 0) : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.orangeToYellow.createShader(bounds);
                      },
                      child: Text(
                        'StartWell',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Welcome message with animations
                AnimatedOpacity(
                  opacity: _showMessage ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset: _showMessage
                        ? const Offset(0, 0)
                        : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Welcome to StartWell – Smart Tiffin Solutions for Smart Parents!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Login button with animations
                AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset: _showButtons
                        ? const Offset(0, 0)
                        : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: UIComponents.gradientButton(
                      text: 'Login',
                      gradient: AppColors.purpleToOrange,
                      onPressed: () {
                        Navigator.push(
                            context, _createPageRoute(const LoginScreen()));
                      },
                      height: 56,
                      borderRadius: 16,
                      elevated: true,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign up button with animations
                AnimatedOpacity(
                  opacity: _showButtons ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSlide(
                    offset: _showButtons
                        ? const Offset(0, 0)
                        : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    child: UIComponents.gradientButton(
                      text: 'Sign Up',
                      gradient: AppColors.purpleToYellow,
                      onPressed: () {
                        Navigator.push(
                            context, _createPageRoute(const SignupScreen()));
                      },
                      height: 56,
                      borderRadius: 16,
                      elevated: true,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.08),
              ],
            ),
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
