import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FooterNote extends StatefulWidget {
  const FooterNote({super.key});

  @override
  State<FooterNote> createState() => _FooterNoteState();
}

class _FooterNoteState extends State<FooterNote>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late final AnimationController _heartController;
  late final Animation<double> _heartAnimation;
  // Unique key for the VisibilityDetector
  final Key _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    // Setup heart beat animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));
  }

  // New method to handle visibility changes
  void _handleVisibilityChanged(VisibilityInfo info) {
    // If at least 30% of the widget is visible
    if (info.visibleFraction >= 0.3) {
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
        });

        // Reset animation state if it was previously invisible
        _restartAnimation();
      }
    } else {
      if (_isVisible) {
        setState(() {
          _isVisible = false;
        });
      }
    }
  }

  // Method to restart the animation
  void _restartAnimation() {
    // First reset the opacity animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _heartController.reset();
        _heartController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the grey color as specified
    const Color greyColor = Color(0xFF7F8285);
    const Color heartColor = Color(0xFFE63946);

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _handleVisibilityChanged,
      child: Container(
        height: 300,
        decoration: const BoxDecoration(
          // color: Colors.red,
          image: DecorationImage(
            image: AssetImage('assets/images/background_footer.png'),
            fit: BoxFit.fitWidth,
            // colorFilter: ColorFilter.mode(
            //   Colors.white.withOpacity(.85),
            //   BlendMode.srcOver,
            // ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 5000),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // First line: Trusted by parents
              Text(
                'Trusted by parents',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: greyColor,
                ),
              ),
              // Second line: Loved by kids!
              Text(
                'Loved by kids!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: greyColor,
                ),
              ),
              const SizedBox(height: 16),
              // Third line: Crafted with ❤️ in Navi Mumbai, India
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Crafted with ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: greyColor,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartAnimation.value,
                        child: const Icon(
                          Icons.favorite,
                          color: heartColor,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  Text(
                    ' in Navi Mumbai, India',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: greyColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
