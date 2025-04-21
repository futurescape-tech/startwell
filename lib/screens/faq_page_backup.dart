import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // Track expansion state of sections
  final Map<int, bool> _isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FAQs',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFFEDE5FB),
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
                          Icons.question_answer_outlined,
                          size: 24,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frequently Asked Questions',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find answers to common questions about StartWell',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSectionTitle('Ordering & Delivery'),
                _buildFAQItem(
                  0,
                  'How do I place an order?',
                  'You can place an order by selecting a meal plan, customizing it to your preferences, and proceeding to checkout. Follow the prompts to complete your order.',
                ),
                _buildFAQItem(
                  1,
                  'Can I modify my order after placing it?',
                  'Yes, you can modify your order up to 24 hours before the scheduled delivery time. Go to "My Orders" and select the order you wish to modify.',
                ),
                _buildFAQItem(
                  2,
                  'What is the delivery schedule?',
                  'Deliveries are made Monday through Friday between 10:00 AM and 2:00 PM. You will receive a notification when your order is out for delivery.',
                ),
                _buildSectionTitle('Payments & Subscriptions'),
                _buildFAQItem(
                  3,
                  'What payment methods do you accept?',
                  'We accept all major credit cards, debit cards, UPI, and StartWell Wallet payments. Payment information is securely processed through our payment partners.',
                ),
                _buildFAQItem(
                  4,
                  'How do subscriptions work?',
                  'Subscriptions provide regular meal deliveries based on your chosen plan. You can select weekly, bi-weekly, or monthly subscription options and pause or cancel anytime.',
                ),
                _buildFAQItem(
                  5,
                  'Are there any subscription fees?',
                  'There are no additional subscription fees. You only pay for the meals included in your plan. Subscribers enjoy discounted pricing compared to one-time orders.',
                ),
                _buildSectionTitle('Account & Support'),
                _buildFAQItem(
                  6,
                  'How do I add a student profile?',
                  'Go to "Profile & Settings," select "Student Profiles," and tap "Add New Student." Fill in the required information to create a new student profile.',
                ),
                _buildFAQItem(
                  7,
                  'How can I contact customer support?',
                  'You can reach our customer support team via the in-app chat, email at support@startwell.com, or call us at 1-800-STARTWELL during business hours (9 AM - 6 PM).',
                ),
                _buildFAQItem(
                  8,
                  'Can I suggest new meal options?',
                  'Absolutely! We welcome your feedback and suggestions. Please use the "Feedback" option in the app or email your suggestions to feedback@startwell.com.',
                ),
                _buildContactSupport(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded[index] ?? false,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded[index] = expanded;
            });
          },
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isExpanded[index] == true
                  ? Color(0xFF8B5CF6)
                  : Color(0xFF333333),
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFEDE5FB),
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
              Icons.help_outline,
              size: 24,
              color: Color(0xFF8B5CF6),
            ),
          ),
          trailing: Icon(
            _isExpanded[index] == true
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Color(0xFF8B5CF6),
          ),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      margin: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFEDE5FB),
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
                  Icons.support_agent,
                  size: 24,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Still have questions?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              // TODO: Implement contact support action
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contact support feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: Text(
                  'Contact Support',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
