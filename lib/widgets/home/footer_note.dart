import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FooterNote extends StatelessWidget {
  const FooterNote({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the grey color as specified
    const Color greyColor = Color(0xFF7F8285);
    const Color heartColor = Color(0xFFE63946);

    return Container(
      height: 200,
      alignment: Alignment.center,
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
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 8),
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
          // Third line: Crafted with ❤️ in Navi Mumbai, India - HIDDEN
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Text(
          //       'Crafted with ',
          //       textAlign: TextAlign.center,
          //       style: GoogleFonts.poppins(
          //         fontSize: 14,
          //         fontWeight: FontWeight.normal,
          //         color: greyColor,
          //       ),
          //     ),
          //     const Icon(
          //       Icons.favorite,
          //       color: heartColor,
          //       size: 20,
          //     ),
          //     Text(
          //       ' in Navi Mumbai, India',
          //       textAlign: TextAlign.center,
          //       style: GoogleFonts.poppins(
          //         fontSize: 14,
          //         fontWeight: FontWeight.normal,
          //         color: greyColor,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
