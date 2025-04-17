import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              'StartWell Privacy Notice',
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

            // Consent and Agreement
            _buildPolicySection(
              title: 'Consent and Agreement',
              content:
                  'By using the StartWell application and services, you hereby consent to our Privacy Policy and agree to its terms. This Privacy Policy describes our policies and procedures on the collection, use and disclosure of your information when you use our Service and tells you about your privacy rights and how the law protects you.',
            ),

            // Information Collected
            _buildPolicySection(
              title: 'What Personal Information Does StartWell Collect?',
              content:
                  'We collect information such as your child\'s name, age, school, grade, section, meal preferences, and dietary restrictions. We also collect parent/guardian information including name, email address, phone number, and payment details. Additionally, we may collect usage data, device information, and location data with your explicit permission.',
            ),

            // Usage of Personal Info
            _buildPolicySection(
              title: 'How We Use Your Information',
              content:
                  'We use the collected information to:\n\n• Provide and maintain our Service\n• Manage your account and subscription\n• Process payments and prevent fraud\n• Deliver meals to your child\'s school\n• Send notifications about meal schedules and changes\n• Improve our services and develop new features\n• Communicate with you about our services\n• Comply with legal obligations',
            ),

            // Cookies
            _buildPolicySection(
              title: 'Cookies and Tracking Technologies',
              content:
                  'StartWell uses cookies and similar tracking technologies to track activity on our Service and store certain information. Cookies are files with a small amount of data that may include an anonymous unique identifier. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent. However, if you do not accept cookies, you may not be able to use some portions of our Service.',
            ),

            // Information Sharing
            _buildPolicySection(
              title: 'Sharing Your Information',
              content:
                  'We may share your personal information in the following situations:\n\n• With Service Providers: We may share your information with service providers to monitor and analyze the use of our Service, to process payments, or to contact you.\n\n• With Your School: We share information with your child\'s school to facilitate meal delivery.\n\n• For Business Transfers: We may share or transfer your information in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition.\n\n• With Your Consent: We may disclose your personal information for any other purpose with your consent.',
            ),

            // Security
            _buildPolicySection(
              title: 'Data Security',
              content:
                  'The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security. We implement a variety of security measures to maintain the safety of your personal information.',
            ),

            // Data Retention
            _buildPolicySection(
              title: 'Data Retention',
              content:
                  'We will retain your personal information only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use your information to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our legal agreements and policies.',
            ),

            // User Access & Rights
            _buildPolicySection(
              title: 'Your Rights and Choices',
              content:
                  'You have the right to:\n\n• Access your personal data\n• Correct inaccurate information\n• Request deletion of your data\n• Object to processing of your data\n• Request restriction of processing\n• Data portability\n• Withdraw consent\n\nYou can exercise these rights by contacting us through the contact information provided below.',
            ),

            // Children's Privacy
            _buildPolicySection(
              title: 'Children\'s Privacy',
              content:
                  'Our Service may be used by parents/guardians to order meals for children. We collect information about children only as provided by parents/guardians and with their explicit consent. If you are a parent/guardian and you are aware that your child has provided us with personal information without your consent, please contact us so that we can take necessary actions.',
            ),

            // Grievance Redressal
            _buildPolicySection(
              title: 'Grievance Redressal',
              content:
                  'If you have any complaints or concerns about our privacy practices, you can contact our Grievance Officer. We will respond to your concerns within a reasonable timeframe.',
            ),

            // Grievance Officer Info
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 30),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grievance Officer',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGrievanceDetail(Icons.person, 'Prithvi Rajput'),
                  _buildGrievanceDetail(Icons.email, 'prithvi@startwell.in'),
                  _buildGrievanceDetail(Icons.phone, '+91 9833607011'),
                  _buildGrievanceDetail(Icons.location_on, 'Kharghar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
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

  Widget _buildGrievanceDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.purple,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
