import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/subscription_model.dart';
import 'dart:developer';

class DeliveredMealsTab extends StatefulWidget {
  final String? studentId;

  const DeliveredMealsTab({
    Key? key,
    this.studentId,
  }) : super(key: key);

  @override
  State<DeliveredMealsTab> createState() => _DeliveredMealsTabState();
}

class _DeliveredMealsTabState extends State<DeliveredMealsTab> {
  List<Map<String, dynamic>> _deliveredMeals = [];
  bool _isLoading = true;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _loadDeliveredMeals();
  }

  Future<void> _loadDeliveredMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would load delivered meals from the service
      // When implemented, uncomment the line below:
      // final deliveredMeals = await _subscriptionService.getDeliveredMeals(widget.studentId);

      // For now, just show empty state
      await Future.delayed(Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _isLoading = false;
          // When implemented, uncomment the line below:
          // _deliveredMeals = deliveredMeals;
        });
      }
    } catch (e) {
      log('Error loading delivered meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_deliveredMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No delivered meals yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your meal delivery history will appear here",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDeliveredMeals,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveredMeals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _deliveredMeals.length,
        itemBuilder: (context, index) {
          final meal = _deliveredMeals[index];
          return _buildDeliveredMealCard(meal);
        },
      ),
    );
  }

  Widget _buildDeliveredMealCard(Map<String, dynamic> meal) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(meal['date']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$formattedDate at ${meal['deliveryTime']}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildReviewBadge(meal['isReviewed']),
              ],
            ),
            const SizedBox(height: 16),
            meal['isReviewed']
                ? _buildRatingDisplay(meal['rating'])
                : _buildReviewButton(meal),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBadge(bool isReviewed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isReviewed ? AppTheme.lightGreen : AppTheme.lightOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isReviewed ? 'Reviewed' : 'Not Reviewed',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isReviewed ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay(int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Rating',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: index < rating ? Colors.amber : Colors.grey,
              size: 24,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReviewButton(Map<String, dynamic> meal) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: () => _showReviewDialog(meal),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Leave Review',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> meal) {
    int selectedRating = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Rate Your Meal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How would you rate your ${meal['title']}?',
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: index < selectedRating
                              ? Colors.amber
                              : Colors.grey,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add optional comments',
                      hintStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedRating > 0) {
                      Navigator.pop(context);
                      _submitReview(meal, selectedRating);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a rating',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Submit',
                    style: GoogleFonts.poppins(
                      color: AppTheme.purple,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitReview(Map<String, dynamic> meal, int rating) {
    setState(() {
      final index = _deliveredMeals.indexOf(meal);
      _deliveredMeals[index]['isReviewed'] = true;
      _deliveredMeals[index]['rating'] = rating;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you for rating ${meal['title']}!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.purple,
      ),
    );
  }
}
