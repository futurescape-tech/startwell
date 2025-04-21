import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';

class HomeBannerCard extends StatefulWidget {
  final VoidCallback onExplorePressed;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onSignupPressed;

  const HomeBannerCard({
    super.key,
    required this.onExplorePressed,
    this.onLoginPressed,
    this.onSignupPressed,
  });

  @override
  State<HomeBannerCard> createState() => _HomeBannerCardState();
}

class _HomeBannerCardState extends State<HomeBannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Trigger bounce-in effect after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B008B), // Darker lavender (from B39DDB → 9575CD)
            Color(0xFF8A2BE2), // Deeper purple (from 8C52FF → 6A1B9A)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'School meals done right!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.onLoginPressed != null &&
                  widget.onSignupPressed != null)
                Row(
                  children: [
                    _buildAuthButton('Login', widget.onLoginPressed!),
                    const SizedBox(width: 10),
                    _buildAuthButton('Sign Up', widget.onSignupPressed!),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fresh, nutritious meals delivered daily to your child\'s school',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: _buildExploreButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.purpleToDeepPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleToDeepPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                text == 'Login' ? Icons.login : Icons.person_add,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreButton() {
    // Bounce-in animation with glow effect
    return AnimatedScale(
      scale: _isVisible ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 100),
      curve: Curves.elasticOut,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.orange.withOpacity(0.1),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 30,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: InkWell(
          onTap: widget.onExplorePressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppTheme.orangeToYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Meal Plans',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppTheme.textDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
