import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/home/section_title.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orange = AppTheme.orange;
    final purple = AppTheme.purple;
    final peach = AppTheme.lightOrange;
    final white = AppTheme.white;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    // Hardcoded menu data for 21st to 25th April
    final breakfastMenu = [
      [
        _MenuItem('Poha', isMealOfDay: true),
        _MenuItem('Upma'),
        _MenuItem('NEW', isNew: true),
      ],
      [
        _MenuItem('Idli Sambhar'),
        _MenuItem('Pancakes', isMealOfDay: true),
        _MenuItem('Fruit Bowl'),
      ],
      [
        _MenuItem('Aloo Paratha', isMealOfDay: true),
        _MenuItem('Croissant'),
        _MenuItem('Yogurt'),
      ],
      [
        _MenuItem('Dhokla'),
        _MenuItem('Waffles', isMealOfDay: true),
        _MenuItem('NEW', isNew: true),
      ],
      [
        _MenuItem('Thepla', isMealOfDay: true),
        _MenuItem('Bagel'),
        _MenuItem('Granola'),
      ],
    ];
    final lunchMenu = [
      [
        _MenuItem('Dal Rice', isMealOfDay: true),
        _MenuItem('Pasta'),
        _MenuItem('Salad'),
      ],
      [
        _MenuItem('Rajma Chawal'),
        _MenuItem('Pizza', isMealOfDay: true),
        _MenuItem('Soup'),
      ],
      [
        _MenuItem('Paneer Curry', isMealOfDay: true),
        _MenuItem('Burger'),
        _MenuItem('Coleslaw'),
      ],
      [
        _MenuItem('Chole Bhature'),
        _MenuItem('Tacos', isMealOfDay: true),
        _MenuItem('Nachos'),
      ],
      [
        _MenuItem('Veg Biryani', isMealOfDay: true),
        _MenuItem('Quesadilla'),
        _MenuItem('Fruit Cup'),
      ],
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
      backgroundColor: AppTheme.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top card with title and date range
            Container(
              padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 24,
                        color: AppTheme.purple,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Weekly Menu',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppTheme.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '21st to 25th April',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Options in Orange represent meal of the day!',
                            style: GoogleFonts.poppins(
                              color: orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Breakfast Section
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.purple,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.ramen_dining,
                          color: Colors.pink,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Breakfast',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _EnhancedMenuTable(
                      days: days,
                      sectionTitles: const [
                        'Indian Breakfast',
                        'International Breakfast',
                        'Side',
                      ],
                      menu: breakfastMenu,
                      highlightColor: orange,
                    ),
                  ),
                ],
              ),
            ),

            // Lunch Section
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.purple,
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flatware_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Lunch',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _EnhancedMenuTable(
                      days: days,
                      sectionTitles: const [
                        'Indian Lunch',
                        'International Lunch',
                        'Side',
                      ],
                      menu: lunchMenu,
                      highlightColor: orange,
                    ),
                  ),
                ],
              ),
            ),

            // Footer Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.purple.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'JAIN OPTIONS AVAILABLE',
                      style: GoogleFonts.poppins(
                        color: AppTheme.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Both Indian and International meals include the standard side dish',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMedium,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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

// Enhanced Menu Table (now horizontally scrollable)
class _EnhancedMenuTable extends StatelessWidget {
  final List<String> days;
  final List<String> sectionTitles;
  final List<List<_MenuItem>> menu;
  final Color highlightColor;
  const _EnhancedMenuTable({
    required this.days,
    required this.sectionTitles,
    required this.menu,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final cellTextStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: AppTheme.textDark,
      height: 1.3,
    );
    final headerTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      color: AppTheme.purple,
      fontSize: 15,
    );
    final labelTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: AppTheme.purple,
      fontSize: 14,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: {
          0: const FixedColumnWidth(140),
          1: const FixedColumnWidth(120),
          2: const FixedColumnWidth(120),
          3: const FixedColumnWidth(120),
          4: const FixedColumnWidth(120),
          5: const FixedColumnWidth(120),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
          verticalInside: BorderSide(color: Colors.grey.shade100),
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.05),
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Text(
                  'Menu Type',
                  style: headerTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              ...days.map((d) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      d,
                      style: headerTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  )),
            ],
          ),
          ...List.generate(sectionTitles.length, (rowIdx) {
            return TableRow(
              decoration: BoxDecoration(
                color: rowIdx % 2 == 0 ? Colors.white : Colors.grey.shade50,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Text(
                    sectionTitles[rowIdx],
                    style: labelTextStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...List.generate(days.length, (colIdx) {
                  final item = menu[colIdx][rowIdx];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: cellTextStyle.copyWith(
                            fontWeight: item.isMealOfDay
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: item.isMealOfDay
                                ? highlightColor
                                : AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (item.isNew || item.isMealOfDay)
                          const SizedBox(height: 4),
                        if (item.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (item.isMealOfDay)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Meal of the Day',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final bool isMealOfDay;
  final bool isNew;
  _MenuItem(this.name, {this.isMealOfDay = false, this.isNew = false});
}
