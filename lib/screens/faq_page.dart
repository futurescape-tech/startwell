import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQs',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQItem(
            question: 'How do I place an order?',
            answer:
                'You can place an order by logging into your account, selecting your child, choosing the meal plan, and following the checkout process. Make sure to review your order before confirming payment.',
          ),
          _buildFAQItem(
            question: 'Can I modify my order after placing it?',
            answer:
                'Yes, you can modify your order up to 24 hours before the delivery date. Go to the "Upcoming Meals" section, select the meal you want to change, and choose the "Swap Meal" option.',
          ),
          _buildFAQItem(
            question: 'What is the cut-off time for meal modifications?',
            answer:
                'The cut-off time for all meal modifications is 24 hours before the scheduled delivery date. After this time, modifications cannot be made to ensure timely preparation and delivery.',
          ),
          _buildFAQItem(
            question: 'How do I cancel a meal?',
            answer:
                'To cancel a meal, go to the "Upcoming Meals" section, select the meal you wish to cancel, and tap the "Cancel Meal" button. Please note that cancellations are subject to the same 24-hour cut-off policy.',
          ),
          _buildFAQItem(
            question: 'What payment methods do you accept?',
            answer:
                'We accept all major credit/debit cards and UPI payments. Payment is processed securely through our payment gateway partners.',
          ),
          _buildFAQItem(
            question: 'How do I add a new student profile?',
            answer:
                'To add a new student profile, go to the "Profile" section, tap on "Add Student", and fill in the required information including name, class, section, and any dietary preferences or allergies.',
          ),
          _buildFAQItem(
            question: 'Can I have different meal plans for different children?',
            answer:
                'Yes, you can select different meal plans for each child. Each student profile can have its own subscription with personalized meal choices.',
          ),
          _buildFAQItem(
            question: 'How do I check my remaining meals?',
            answer:
                'You can check your remaining meals by going to the "My Subscriptions" section and selecting the relevant subscription. You\'ll see a detailed breakdown of consumed and remaining meals.',
          ),
          _buildFAQItem(
            question:
                'What happens if I have unused meals at the end of a subscription period?',
            answer:
                'Unused meals do not carry over to the next subscription period. We encourage you to plan accordingly to maximize the value of your subscription.',
          ),
          _buildFAQItem(
            question: 'How can I renew my subscription?',
            answer:
                'You can renew your subscription by going to the "My Subscriptions" section, selecting the expired or about-to-expire subscription, and choosing the "Renew" option. Follow the prompts to complete the renewal process.',
          ),
          _buildFAQItem(
            question: 'Are there vegetarian options available?',
            answer:
                'Yes, we offer a variety of vegetarian options. You can set dietary preferences in each student profile, and our meal selection will adjust accordingly.',
          ),
          _buildFAQItem(
            question: 'How do I contact customer support?',
            answer:
                'You can contact our customer support team through the "Help & Support" section in the app, or by emailing support@startwell.com. Our team is available Monday to Friday, 9 AM to 6 PM.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppTheme.purple,
        textColor: AppTheme.purple,
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
