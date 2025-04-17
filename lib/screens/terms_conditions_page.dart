import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StartWell Terms of Use',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.purple,
              ),
            ),
            Text(
              'Last updated: 4 April 2023',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 20),

            // Terms Sections
            _buildTermsSection(
              title: '1. What does StartWell do?',
              content:
                  'StartWell is a platform that connects parents with school meal services. We provide a convenient way for parents to order, schedule, and manage meal deliveries for their children at participating schools. Our service includes meal selection, payment processing, and delivery coordination.',
            ),

            _buildTermsSection(
              title: '2. Ordering',
              content:
                  'Users must provide accurate and complete information when placing orders through our platform. Orders are subject to acceptance by StartWell and participating schools. We reserve the right to reject or cancel any order for any reason, including but not limited to product availability, errors in pricing or description, or concerns about fraudulent activity.',
            ),

            _buildTermsSection(
              title: '3. Payment',
              content:
                  'All payments are processed securely through our platform. By using our service, you agree to pay all charges at the prices then in effect for your orders. You also agree to pay any applicable taxes and delivery fees. Payment must be made at the time of order placement. We accept various payment methods as indicated in the app.',
            ),

            _buildTermsSection(
              title: '4. Delivery',
              content:
                  'Meals will be delivered to the specified school at the designated time. StartWell is not responsible for any delays caused by circumstances beyond our control, including but not limited to traffic, weather conditions, or school schedule changes. We will make reasonable efforts to notify users of any delivery issues.',
            ),

            _buildTermsSection(
              title: '5. Cancellation and Modification',
              content:
                  'Orders may be cancelled or modified up to 24 hours before the scheduled delivery time. After this cutoff period, no cancellations or modifications will be accepted. Refunds for cancelled orders will be processed according to our refund policy.',
            ),

            _buildTermsSection(
              title: '6. User Accounts',
              content:
                  'You are responsible for maintaining the confidentiality of your account information, including your password. You agree to notify StartWell immediately of any unauthorized use of your account. StartWell is not liable for any loss or damage arising from your failure to comply with this responsibility.',
            ),

            _buildTermsSection(
              title: '7. User Conduct',
              content:
                  'When using our service, you agree not to engage in any activity that may interfere with or disrupt the service or servers. You also agree not to attempt to gain unauthorized access to any part of the service or any other accounts, computer systems, or networks connected to the service.',
            ),

            _buildTermsSection(
              title: '8. Data Protection',
              content:
                  'We collect and process personal data in accordance with our Privacy Policy. By using our service, you consent to our data practices as described in the Privacy Policy, including the collection, use, and sharing of your information.',
            ),

            _buildTermsSection(
              title: '9. Intellectual Property',
              content:
                  'All content on the StartWell platform, including but not limited to text, graphics, logos, and software, is the property of StartWell or its content suppliers and is protected by copyright and other intellectual property laws. You may not reproduce, distribute, or create derivative works from this content without explicit permission.',
            ),

            _buildTermsSection(
              title: '10. Liability Limitations',
              content:
                  'StartWell is not liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of our service. Our liability is limited to the amount paid by you for the specific order in question.',
            ),

            _buildTermsSection(
              title: '11. Disputes Resolution',
              content:
                  'Any disputes arising from the use of our service shall be resolved through amicable negotiations. If a resolution cannot be reached, the matter shall be submitted to arbitration in accordance with the laws of India.',
            ),

            _buildTermsSection(
              title: '12. Service Availability',
              content:
                  'We strive to ensure that our service is available at all times. However, we do not guarantee uninterrupted access to our platform and reserve the right to suspend or terminate the service temporarily for maintenance or updates.',
            ),

            _buildTermsSection(
              title: '13. Changes to Terms',
              content:
                  'StartWell reserves the right to modify these Terms at any time. We will provide notice of significant changes by updating the "Last Updated" date. Your continued use of the service after such changes constitutes acceptance of the new Terms.',
            ),

            _buildTermsSection(
              title: '14. Termination',
              content:
                  'We may terminate or suspend your account and access to our service immediately, without prior notice or liability, for any reason, including but not limited to a breach of these Terms. Upon termination, your right to use the service will cease immediately.',
            ),

            _buildTermsSection(
              title: '15. Feedback',
              content:
                  'Any feedback, comments, or suggestions you provide regarding our service is entirely voluntary, and we are free to use such feedback, comments, or suggestions without any obligation to you.',
            ),

            _buildTermsSection(
              title: '16. Pricing and Subscription',
              content:
                  'Meal prices and subscription fees are subject to change. We will provide notice of any price changes before they take effect. Subscription plans are billed in advance according to the billing cycle you select.',
            ),

            _buildTermsSection(
              title: '17. Refunds',
              content:
                  'Refunds are processed according to our refund policy. Generally, refunds are provided for cancelled orders that meet our cancellation timeframe requirements. No refunds will be issued for consumed meals or cancellations made after the cutoff period.',
            ),

            _buildTermsSection(
              title: '18. Communications',
              content:
                  'By creating an account, you agree to receive communications from StartWell, including order confirmations, delivery updates, and service announcements. You can opt out of promotional communications, but operational communications are essential to our service.',
            ),

            _buildTermsSection(
              title: '19. Allergies and Dietary Restrictions',
              content:
                  'While we make efforts to accommodate allergies and dietary restrictions, we cannot guarantee that meals are free from specific allergens. It is the user\'s responsibility to check meal ingredients and notify us of any allergies or restrictions.',
            ),

            _buildTermsSection(
              title: '20. Meal Quality',
              content:
                  'We strive to ensure high-quality meals. However, we are not liable for variations in taste, appearance, or portion size. If you receive a meal that does not meet our quality standards, please contact our customer service within 24 hours.',
            ),

            _buildTermsSection(
              title: '21. Third-Party Services',
              content:
                  'Our service may include or link to third-party services. We are not responsible for the content, privacy policies, or practices of these third parties. Your interactions with these third parties are solely between you and them.',
            ),

            _buildTermsSection(
              title: '22. Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
            ),

            _buildTermsSection(
              title: '23. Severability',
              content:
                  'If any provision of these Terms is held to be invalid or unenforceable, such provision shall be struck and the remaining provisions shall be enforced to the fullest extent under law.',
            ),

            _buildTermsSection(
              title: '24. Entire Agreement',
              content:
                  'These Terms, together with our Privacy Policy, constitute the entire agreement between you and StartWell regarding our service and supersede all prior agreements and understandings.',
            ),

            _buildTermsSection(
              title: '25. Assignment',
              content:
                  'You may not assign these Terms without the prior written consent of StartWell. StartWell may assign these Terms without restriction.',
            ),

            _buildTermsSection(
              title: '26. Force Majeure',
              content:
                  'StartWell shall not be liable for any failure to perform its obligations where such failure is a result of acts of nature, government actions, or other factors beyond its reasonable control.',
            ),

            _buildTermsSection(
              title: '27. Waiver',
              content:
                  'The failure of StartWell to enforce any right or provision of these Terms will not be considered a waiver of those rights. The waiver of any such right will not be deemed a waiver of any other right.',
            ),

            _buildTermsSection(
              title: '28. User Representations',
              content:
                  'By using our service, you represent and warrant that you are at least 18 years of age and have the legal capacity to enter into these Terms.',
            ),

            _buildTermsSection(
              title: '29. Promotions',
              content:
                  'Any contests, sweepstakes, or other promotions offered through our service may be governed by separate rules. By participating in any such promotion, you agree to be subject to those rules.',
            ),

            _buildTermsSection(
              title: '30. School Policies',
              content:
                  'Users must comply with all applicable school policies regarding meal delivery and consumption. StartWell is not responsible for any conflicts between our service and school policies.',
            ),

            _buildTermsSection(
              title: '31. Meal Consumption',
              content:
                  'StartWell is not responsible for how meals are consumed or handled after delivery. Parents and schools are responsible for ensuring proper food handling and consumption.',
            ),

            _buildTermsSection(
              title: '32. Customer Support',
              content:
                  'We provide customer support through various channels as specified in the app. Response times may vary based on the nature of the inquiry and volume of requests.',
            ),

            _buildTermsSection(
              title: '33. Contact Information',
              content:
                  'For questions about these Terms, please contact us at support@startwell.in or through the contact information provided in the app.',
            ),

            const SizedBox(height: 20),
            Text(
              'By using the StartWell app, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection({required String title, required String content}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: const Icon(
          Icons.article_outlined,
          color: AppTheme.purple,
        ),
        title: Text(
          title,
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
            content,
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
