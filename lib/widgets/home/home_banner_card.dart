import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/screens/menu_page.dart';

class HomeBannerCard extends StatefulWidget {
  final VoidCallback onExplorePressed;

  const HomeBannerCard({
    super.key,
    required this.onExplorePressed,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 350;
    final titleFontSize = isSmall ? 16.0 : 22.0;
    final subtitleFontSize = isSmall ? 12.0 : 14.0;
    final padding = isSmall ? 12.0 : 20.0;
    final buttonFontSize = isSmall ? 13.0 : 16.0;
    final buttonHeight = isSmall ? 38.0 : 50.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B008B),
                Color(0xFF8A2BE2),
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
              Text(
                'School meals done right!',
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                'Fresh, nutritious meals delivered daily to your child\'s school',
                style: GoogleFonts.poppins(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, buttonConstraints) {
                  final isVerySmall = buttonConstraints.maxWidth < 300;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Removed the _buildExploreButton to hide Order Meals button
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreButton({double fontSize = 16, double height = 50}) {
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
            padding: EdgeInsets.symmetric(
              horizontal: height * 0.32,
              vertical: height * 0.2,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.orangeToYellow,
              borderRadius: BorderRadius.circular(50),
            ),
            height: height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order Meals',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
