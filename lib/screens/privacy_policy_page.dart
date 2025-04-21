import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Track expanded state for animation effects
  final Map<int, bool> _isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
                    'StartWell Privacy Notice',
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
                'General Privacy Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Consent and Agreement
            _buildPolicySection(
              index: 1,
              title: 'Consent and Agreement',
              content:
                  'By using the StartWell application and services, you hereby consent to our Privacy Policy and agree to its terms. This Privacy Policy describes our policies and procedures on the collection, use and disclosure of your information when you use our Service and tells you about your privacy rights and how the law protects you.',
            ),

            // Information Collected
            _buildPolicySection(
              index: 2,
              title: 'What Personal Information Does StartWell Collect?',
              content:
                  'We collect information such as your child\'s name, age, school, grade, section, meal preferences, and dietary restrictions. We also collect parent/guardian information including name, email address, phone number, and payment details. Additionally, we may collect usage data, device information, and location data with your explicit permission.',
            ),

            // Usage of Personal Info
            _buildPolicySection(
              index: 3,
              title: 'How We Use Your Information',
              content:
                  'We use the collected information to:\n\n• Provide and maintain our Service\n• Manage your account and subscription\n• Process payments and prevent fraud\n• Deliver meals to your child\'s school\n• Send notifications about meal schedules and changes\n• Improve our services and develop new features\n• Communicate with you about our services\n• Comply with legal obligations',
            ),

            // Cookies
            _buildPolicySection(
              index: 4,
              title: 'Cookies and Tracking Technologies',
              content:
                  'StartWell uses cookies and similar tracking technologies to track activity on our Service and store certain information. Cookies are files with a small amount of data that may include an anonymous unique identifier. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent. However, if you do not accept cookies, you may not be able to use some portions of our Service.',
            ),

            // Section header for data sharing
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
                'Data Sharing & Protection',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Information Sharing
            _buildPolicySection(
              index: 5,
              title: 'Sharing Your Information',
              content:
                  'We may share your personal information in the following situations:\n\n• With Service Providers: We may share your information with service providers to monitor and analyze the use of our Service, to process payments, or to contact you.\n\n• With Your School: We share information with your child\'s school to facilitate meal delivery.\n\n• For Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition.\n\n• With Your Consent: We may disclose your personal information for any other purpose with your consent.',
            ),

            // Security
            _buildPolicySection(
              index: 6,
              title: 'Data Security',
              content:
                  'The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security. We implement a variety of security measures to maintain the safety of your personal information.',
            ),

            // Data Retention
            _buildPolicySection(
              index: 7,
              title: 'Data Retention',
              content:
                  'We will retain your personal information only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use your information to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our legal agreements and policies.',
            ),

            // Section header for user rights
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
                'Your Rights & Children\'s Privacy',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // User Access & Rights
            _buildPolicySection(
              index: 8,
              title: 'Your Rights and Choices',
              content:
                  'You have the right to:\n\n• Access your personal data\n• Correct inaccurate information\n• Request deletion of your data\n• Object to processing of your data\n• Request restriction of processing\n• Data portability\n• Withdraw consent\n\nYou can exercise these rights by contacting us through the contact information provided below.',
            ),

            // Children's Privacy
            _buildPolicySection(
              index: 9,
              title: 'Children\'s Privacy',
              content:
                  'Our Service may be used by parents/guardians to order meals for children. We collect information about children only as provided by parents/guardians and with their explicit consent. If you are a parent/guardian and you are aware that your child has provided us with personal information without your consent, please contact us so that we can take necessary actions.',
            ),

            // Grievance Redressal
            _buildPolicySection(
              index: 10,
              title: 'Grievance Redressal',
              content:
                  'If you have any complaints or concerns about our privacy practices, you can contact our Grievance Officer. We will respond to your concerns within a reasonable timeframe.',
            ),

            // Grievance Officer Info
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.05),
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
                          Icons.support_agent_outlined,
                          color: Color(0xFF8B5CF6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Grievance Officer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                  const SizedBox(height: 16),
                  _buildGrievanceDetail(Icons.person_outline, 'Prithvi Rajput'),
                  _buildGrievanceDetail(
                      Icons.email_outlined, 'prithvi@startwell.in'),
                  _buildGrievanceDetail(Icons.phone_outlined, '+91 9833607011'),
                  _buildGrievanceDetail(Icons.location_on_outlined, 'Kharghar'),
                ],
              ),
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
              child: Text(
                'By using the StartWell app, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy.',
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

  Widget _buildPolicySection(
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
                        Icons.shield_outlined,
                        color: Color(
                            0xFFEC4899), // Privacy Policy color from profile
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
                      color: Color(0xFFEC4899),
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

  Widget _buildGrievanceDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEDE5FB).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
