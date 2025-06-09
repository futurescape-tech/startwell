import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/home/section_title.dart';

class MenuPage extends StatelessWidget {
  final bool isDialogMode;
  const MenuPage({Key? key, this.isDialogMode = false}) : super(key: key);

  // Static method to show the menu as a dialog
  static void showAsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Weekly Menu',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: MenuPage(isDialogMode: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
        _MenuItem('NEW'),
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
        _MenuItem('NEW'),
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

    // Build the content widget
    Widget contentWidget = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date display
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.purple.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppTheme.purple,
                ),
                const SizedBox(width: 10),
                Text(
                  '21st to 25th April',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.purple,
                  ),
                ),
              ],
            ),
          ),

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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _EnhancedMenuTable(
                  days: days,
                  sectionTitles: const [
                    'Indian Breakfast',
                    'International Breakfast',
                    'Side',
                  ],
                  menu: breakfastMenu,
                  highlightColor: orange,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _EnhancedMenuTable(
                  days: days,
                  sectionTitles: const [
                    'Indian Lunch',
                    'International Lunch',
                    'Side',
                  ],
                  menu: lunchMenu,
                  highlightColor: orange,
                ),
              ],
            ),
          ),

          // Jain Menu Section
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
                        Icons.spa_outlined,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Jain Menu',
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
                _EnhancedMenuTable(
                  days: days,
                  sectionTitles: const [
                    'Jain Breakfast',
                    'Jain Lunch',
                    'Side',
                  ],
                  menu: [
                    [
                      _MenuItem('Jain Poha', isMealOfDay: true),
                      _MenuItem('Jain Dal Rice'),
                      _MenuItem('Fruit'),
                    ],
                    [
                      _MenuItem('Idli'),
                      _MenuItem('Jain Rajma', isMealOfDay: true),
                      _MenuItem('Salad'),
                    ],
                    [
                      _MenuItem('Plain Paratha', isMealOfDay: true),
                      _MenuItem('Jain Paneer'),
                      _MenuItem('Yogurt'),
                    ],
                    [
                      _MenuItem('Jain Dhokla'),
                      _MenuItem('Jain Chole', isMealOfDay: true),
                      _MenuItem('Fruit Salad'),
                    ],
                    [
                      _MenuItem('Thepla', isMealOfDay: true),
                      _MenuItem('Jain Biryani'),
                      _MenuItem('Fresh Juice'),
                    ],
                  ],
                  highlightColor: AppTheme.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // If in dialog mode, just return the content widget
    if (isDialogMode) {
      return contentWidget;
    }

    // Otherwise, return the full page
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Menu',
          style: GoogleFonts.poppins(
            fontSize: 18,
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
      body: contentWidget,
    );
  }
}

// Enhanced Menu Table (with fixed first column)
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
      fontSize: 12,
      color: AppTheme.textDark,
      height: 1.3,
    );
    final headerTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      color: AppTheme.purple,
      fontSize: 13,
    );
    final labelTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: AppTheme.purple,
      fontSize: 12,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed First Column (Menu Types)
          Container(
            width: 140,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 53, // Match the height defined for days header
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Menu Type',
                    style: headerTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Section titles
                ...List.generate(sectionTitles.length, (rowIdx) {
                  final rowHeight =
                      100.0; // Increase height to better fit content
                  return Container(
                    height: rowHeight, // Fixed height to match content rows
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          rowIdx % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: rowIdx == sectionTitles.length - 1
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sectionTitles[rowIdx],
                      style: labelTextStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: days.length * 120, // Each day column is 120 wide
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header Row with days
                    Container(
                      height: 53, // Match the height of the Menu Type header
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: days
                            .map((day) => Container(
                                  width: 120,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: Text(
                                    day,
                                    style: headerTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Menu content rows
                    ...List.generate(sectionTitles.length, (rowIdx) {
                      final rowHeight =
                          100.0; // Increase height to better fit content
                      return Container(
                        height: rowHeight,
                        decoration: BoxDecoration(
                          color: rowIdx % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(
                              color: rowIdx == sectionTitles.length - 1
                                  ? Colors.transparent
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: List.generate(days.length, (colIdx) {
                            final item = menu[colIdx][rowIdx];
                            return Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final bool isMealOfDay;
  _MenuItem(this.name, {this.isMealOfDay = false});
}
