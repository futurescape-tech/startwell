import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';

class ExampleAppThemeScreen extends StatefulWidget {
  const ExampleAppThemeScreen({Key? key}) : super(key: key);

  @override
  State<ExampleAppThemeScreen> createState() => _ExampleAppThemeScreenState();
}

class _ExampleAppThemeScreenState extends State<ExampleAppThemeScreen> {
  int _currentIndex = 0;

  final _tabs = [
    _TabInfo(
      title: 'Standard',
      icon: Icons.style,
      description: 'Standard AppBar with purple background',
    ),
    _TabInfo(
      title: 'Gradient',
      icon: Icons.gradient,
      description: 'GradientAppBar with purple-to-deep-purple gradient',
    ),
    _TabInfo(
      title: 'Custom',
      icon: Icons.palette,
      description: 'GradientAppBar with custom orange-to-yellow gradient',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AppBar Theme Examples',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _tabs[_currentIndex].description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildFeatureCard(
              title: 'Rounded Bottom Corners',
              description:
                  'The AppBar has rounded bottom corners for a modern look',
              icon: Icons.rounded_corner,
            ),
            _buildFeatureCard(
              title: 'Consistent Text Style',
              description: 'Typography follows the app theme with Poppins font',
              icon: Icons.text_fields,
            ),
            _buildFeatureCard(
              title: 'Gradient Support',
              description:
                  'Optional gradient background with customizable colors',
              icon: Icons.gradient,
            ),
            _buildFeatureCard(
              title: 'Proper Elevation',
              description: 'Subtle shadow for depth without being too heavy',
              icon: Icons.layers,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Previous Screen'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab.icon),
            label: tab.title,
          );
        }).toList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        // Standard AppBar
        return AppBar(
          title: Text('AppTheme Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ],
        );
      case 1:
        // Gradient AppBar
        return GradientAppBar(
          titleText: 'AppTheme Demo',
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ],
        );
      case 2:
        // Custom Gradient AppBar
        return GradientAppBar(
          titleText: 'AppTheme Demo',
          customGradient: AppTheme.orangeToYellow,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppTheme.textDark),
              onPressed: () {},
            ),
          ],
        );
      default:
        return AppBar(title: Text('AppTheme Demo'));
    }
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textMedium,
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

class _TabInfo {
  final String title;
  final IconData icon;
  final String description;

  _TabInfo({
    required this.title,
    required this.icon,
    required this.description,
  });
}
