import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // Track expanded state for animation effects
  final Map<int, bool> _isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQs',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.purpleToDeepPurple,
          ),
        ),
        elevation: 4,
        shadowColor: AppTheme.deepPurple.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to commonly asked questions about StartWell services',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section header for ordering
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.deepPurple,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Ordering & Delivery',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildFAQItem(
              index: 1,
              question: 'How do I place an order?',
              answer:
                  'You can place an order by logging into your account, selecting your child, choosing the meal plan, and following the checkout process. Make sure to review your order before confirming payment.',
            ),
            _buildFAQItem(
              index: 2,
              question: 'Can I modify my order after placing it?',
              answer:
                  'Yes, you can modify your order up to 24 hours before the delivery date. Go to the "Upcoming Meals" section, select the meal you want to change, and choose the "Swap Meal" option.',
            ),
            _buildFAQItem(
              index: 3,
              question: 'What is the cut-off time for meal modifications?',
              answer:
                  'The cut-off time for all meal modifications is 24 hours before the scheduled delivery date. After this time, modifications cannot be made to ensure timely preparation and delivery.',
            ),
            _buildFAQItem(
              index: 4,
              question: 'How do I cancel a meal?',
              answer:
                  'To cancel a meal, go to the "Upcoming Meals" section, select the meal you wish to cancel, and tap the "Cancel Meal" button. Please note that cancellations are subject to the same 24-hour cut-off policy.',
            ),

            // Section header for payments
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.deepPurple,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(top: 20, bottom: 16),
              child: Text(
                'Payments & Subscriptions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildFAQItem(
              index: 5,
              question: 'What payment methods do you accept?',
              answer:
                  'We accept all major credit/debit cards and UPI payments. Payment is processed securely through our payment gateway partners.',
            ),
            _buildFAQItem(
              index: 6,
              question: 'How do I check my remaining meals?',
              answer:
                  'You can check your remaining meals by going to the "My Subscriptions" section and selecting the relevant subscription. You\'ll see a detailed breakdown of consumed and remaining meals.',
            ),
            _buildFAQItem(
              index: 7,
              question:
                  'What happens if I have unused meals at the end of a subscription period?',
              answer:
                  'Unused meals do not carry over to the next subscription period. We encourage you to plan accordingly to maximize the value of your subscription.',
            ),
            _buildFAQItem(
              index: 8,
              question: 'How can I renew my subscription?',
              answer:
                  'You can renew your subscription by going to the "My Subscriptions" section, selecting the expired or about-to-expire subscription, and choosing the "Renew" option. Follow the prompts to complete the renewal process.',
            ),

            // Section header for account
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.deepPurple,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(top: 20, bottom: 16),
              child: Text(
                'Account & Support',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildFAQItem(
              index: 9,
              question: 'How do I add a new student profile?',
              answer:
                  'To add a new student profile, go to the "Profile" section, tap on "Add Student", and fill in the required information including name, class, section, and any dietary preferences or allergies.',
            ),
            _buildFAQItem(
              index: 10,
              question:
                  'Can I have different meal plans for different children?',
              answer:
                  'Yes, you can select different meal plans for each child. Each student profile can have its own subscription with personalized meal choices.',
            ),
            _buildFAQItem(
              index: 11,
              question: 'Are there vegetarian options available?',
              answer:
                  'Yes, we offer a variety of vegetarian options. You can set dietary preferences in each student profile, and our meal selection will adjust accordingly.',
            ),
            _buildFAQItem(
              index: 12,
              question: 'How do I contact customer support?',
              answer:
                  'You can contact our customer support team through the "Help & Support" section in the app, or by emailing support@startwell.com. Our team is available Monday to Friday, 9 AM to 6 PM.',
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.purple.withOpacity(0.05),
                border: Border.all(
                  color: AppTheme.purple.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Still have questions?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team at support@startwell.com',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: AppTheme.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(
      {required int index, required String question, required String answer}) {
    final bool isExpanded = _isExpanded[index] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(isExpanded ? 0.15 : 0.08),
            blurRadius: isExpanded ? 10 : 6,
            offset: Offset(0, isExpanded ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _isExpanded[index] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFEDE5FB), // soft lavender background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8B5CF6).withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF6366F1), // FAQs color from profile
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      answer,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
