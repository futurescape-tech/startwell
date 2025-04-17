import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:startwell/themes/app_theme.dart';

class ValueCarousel extends StatefulWidget {
  const ValueCarousel({Key? key}) : super(key: key);

  @override
  State<ValueCarousel> createState() => _ValueCarouselState();
}

class _ValueCarouselState extends State<ValueCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'title': 'Natural Ingredients',
      'description':
          'Sustainably sourced whole and fresh ingredients. We eliminate anything artificial or processed.',
      'iconPath': 'assets/icons/Natural Ingredients.png',
      'backgroundImage': 'assets/images/carousel/Natural_ingridents.png',
    },
    {
      'title': 'Designed by Child Nutritionists',
      'description':
          'Holistic meals carefully designed to meet the age-specific Recommended Dietary Allowance (RDA).',
      'iconPath': 'assets/icons/Designed by Child Nutritionists.png',
      'backgroundImage':
          'assets/images/carousel/Designed_by_Child_Nutritionists.png',
    },
    {
      'title': 'Prepared by Chefs & Mothers',
      'description':
          'A team of chefs and mothers working round the clock to ensure a diverse and delightful experience everyday.',
      'iconPath': 'assets/icons/Prepared by Chefs & Mothers.png',
      'backgroundImage': 'assets/images/carousel/prepared_by_chefs&mothers.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: _carouselItems
              .map((item) => _buildCarouselCard(
                    title: item['title'],
                    description: item['description'],
                    iconPath: item['iconPath'],
                    backgroundImage: item['backgroundImage'],
                  ))
              .toList(),
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            aspectRatio: 16 / 12,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          carouselController: _carouselController,
        ),
        const SizedBox(height: 16),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: _carouselItems.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: AppTheme.orange,
            dotColor: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCarouselCard({
    required String title,
    required String description,
    required String iconPath,
    required String backgroundImage,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Gradient overlay for better readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Common header on all cards

                  // const SizedBox(height: 8),
                  // Text(
                  //   'Food parents feel good about and kids absolutely love',
                  //   textAlign: TextAlign.center,
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 14,
                  //     color: Colors.white.withOpacity(0.9),
                  //   ),
                  // ),
                  const SizedBox(height: 24),

                  // Value icon
                  Image.asset(
                    iconPath,
                    width: 80,
                    height: 80,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 18),

                  // Value title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Value description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
