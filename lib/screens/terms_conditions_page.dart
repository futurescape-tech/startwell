import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  // Track expanded state for animation effects
  final Map<int, bool> _isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
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
            // Title and subtitle with container decoration
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
                    'StartWell Terms of Use',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.textMedium,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last updated: 4 April 2023',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section header
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
                'Terms Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Terms Sections
            _buildTermsSection(
              index: 1,
              title: 'What does StartWell do?',
              content:
                  'StartWell is a platform that connects parents with school meal services. We provide a convenient way for parents to order, schedule, and manage meal deliveries for their children at participating schools. Our service includes meal selection, payment processing, and delivery coordination.',
            ),

            _buildTermsSection(
              index: 2,
              title: 'Ordering',
              content:
                  'Users must provide accurate and complete information when placing orders through our platform. Orders are subject to acceptance by StartWell and participating schools. We reserve the right to reject or cancel any order for any reason, including but not limited to product availability, errors in pricing or description, or concerns about fraudulent activity.',
            ),

            _buildTermsSection(
              index: 3,
              title: 'Payment',
              content:
                  'All payments are processed securely through our platform. By using our service, you agree to pay all charges at the prices then in effect for your orders. You also agree to pay any applicable taxes and delivery fees. Payment must be made at the time of order placement. We accept various payment methods as indicated in the app.',
            ),

            _buildTermsSection(
              index: 4,
              title: 'Delivery',
              content:
                  'Meals will be delivered to the specified school at the designated time. StartWell is not responsible for any delays caused by circumstances beyond our control, including but not limited to traffic, weather conditions, or school schedule changes. We will make reasonable efforts to notify users of any delivery issues.',
            ),

            _buildTermsSection(
              index: 5,
              title: 'Cancellation and Modification',
              content:
                  'Orders may be cancelled or modified up to 24 hours before the scheduled delivery time. After this cutoff period, no cancellations or modifications will be accepted. Refunds for cancelled orders will be processed according to our refund policy.',
            ),

            // Section header for account terms
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
                'Account Terms',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildTermsSection(
              index: 6,
              title: 'User Accounts',
              content:
                  'You are responsible for maintaining the confidentiality of your account information, including your password. You agree to notify StartWell immediately of any unauthorized use of your account. StartWell is not liable for any loss or damage arising from your failure to comply with this responsibility.',
            ),

            _buildTermsSection(
              index: 7,
              title: 'User Conduct',
              content:
                  'When using our service, you agree not to engage in any activity that may interfere with or disrupt the service or servers. You also agree not to attempt to gain unauthorized access to any part of the service or any other accounts, computer systems, or networks connected to the service.',
            ),

            _buildTermsSection(
              index: 8,
              title: 'Data Protection',
              content:
                  'We collect and process personal data in accordance with our Privacy Policy. By using our service, you consent to our data practices as described in the Privacy Policy, including the collection, use, and sharing of your information.',
            ),

            // Section header for legal terms
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
                'Legal Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            _buildTermsSection(
              index: 9,
              title: 'Intellectual Property',
              content:
                  'All content on the StartWell platform, including but not limited to text, graphics, logos, and software, is the property of StartWell or its content suppliers and is protected by copyright and other intellectual property laws. You may not reproduce, distribute, or create derivative works from this content without explicit permission.',
            ),

            _buildTermsSection(
              index: 10,
              title: 'Liability Limitations',
              content:
                  'StartWell is not liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of our service. Our liability is limited to the amount paid by you for the specific order in question.',
            ),

            _buildTermsSection(
              index: 11,
              title: 'Disputes Resolution',
              content:
                  'Any disputes arising from the use of our service shall be resolved through amicable negotiations. If a resolution cannot be reached, the matter shall be submitted to arbitration in accordance with the laws of India.',
            ),

            // Additional terms as a setting item similar to Profile & Settings
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shadowColor: AppTheme.deepPurple.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Full terms document will be available in the next update',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppTheme.purple,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          Icons.description_outlined,
                          color: Color(
                              0xFF8B5CF6), // Terms & Conditions color from profile
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'View Complete Terms Document',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Color(0xFF8B5CF6),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
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
              child: Text(
                'By using the StartWell app, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(
      {required int index, required String title, required String content}) {
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
                        Icons.description_outlined,
                        color: Color(
                            0xFF8B5CF6), // Terms & Conditions color from profile
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Color(0xFF8B5CF6),
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
                      content,
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
