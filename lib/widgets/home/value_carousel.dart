import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';

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
      'title': 'Special Lunch Deal',
      'description':
          '20% OFF on your first week subscription. Nutritious meals for your kids!',
      'iconPath': 'assets/icons/Natural Ingredients.png',
      'backgroundImage': 'assets/images/carousel/Natural_ingridents.png',
      'badgeText': '20% OFF',
      'offerValidUntil': 'Valid until June 30',
      'buttonText': 'Order Meals',
    },
    {
      'title': 'Nutritionist-Approved Breakfast',
      'description':
          'Try our special breakfast meals designed by child nutritionists. Packed with nutrients!',
      'iconPath': 'assets/icons/Designed by Child Nutritionists.png',
      'backgroundImage':
          'assets/images/carousel/Designed_by_Child_Nutritionists.png',
      'badgeText': 'NEW',
      'offerValidUntil': 'Limited time offer',
      'buttonText': 'Order Meals',
    },
    {
      'title': 'Homestyle Meals',
      'description':
          'Handcrafted meals by expert chefs. Just like mom would make, but delivered to school!',
      'iconPath': 'assets/icons/Prepared by Chefs & Mothers.png',
      'backgroundImage': 'assets/images/carousel/prepared_by_chefs&mothers.png',
      'badgeText': 'POPULAR',
      'offerValidUntil': 'Most ordered meal plan',
      'buttonText': 'Order Meals',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;

    return Column(
      children: [
        const SizedBox(height: 16),
        CarouselSlider(
          items: _carouselItems
              .map((item) => _buildCarouselCard(
                    context: context,
                    title: item['title'],
                    description: item['description'],
                    iconPath: item['iconPath'],
                    backgroundImage: item['backgroundImage'],
                    badgeText: item['badgeText'],
                    offerValidUntil: item['offerValidUntil'],
                    buttonText: 'Order Meals', // Standardized button text
                  ))
              .toList(),
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            viewportFraction:
                isSmallScreen ? 0.95 : 0.92, // Adjust for small screens
            aspectRatio: 16 / 9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          carouselController: _carouselController,
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: _carouselItems.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: AppTheme.orange,
            dotColor: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCarouselCard({
    required BuildContext context,
    required String title,
    required String description,
    required String iconPath,
    required String backgroundImage,
    required String badgeText,
    required String offerValidUntil,
    required String buttonText,
  }) {
    // Get screen dimensions for responsiveness
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isMediumScreen =
        screenSize.width >= 360 && screenSize.width < 600;
    final bool isLargeScreen = screenSize.width >= 600;

    // Responsive font sizes
    final double titleFontSize =
        isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
    final double descriptionFontSize = isSmallScreen ? 12 : 14;
    final double badgeFontSize = isSmallScreen ? 10 : 12;
    final double buttonFontSize = isSmallScreen ? 12 : 14;

    // Responsive padding
    final double cardPadding = isSmallScreen ? 12 : (isMediumScreen ? 16 : 20);

    return Card(
      margin:
          EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 6),
      elevation: 4,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            // Gradient overlay for better readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section with badge and title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer badge with purple-to-orange gradient
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme
                              .purpleToOrange, // Changed to purple-to-orange
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.poppins(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .white, // Changed to white for better contrast
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Title with responsive font size
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),

                      // Description - Trimmed and responsive
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: descriptionFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                  // Bottom section with button - Simplified and responsive
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.mealPlan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: AppTheme.textDark,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 10 : 14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
