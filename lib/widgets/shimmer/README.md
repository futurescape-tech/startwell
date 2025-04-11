# Shimmer Loading System for StartWell App

This folder contains reusable shimmer loading components for the StartWell Tiffin Service App.

## Overview

The shimmer loading effect provides a placeholder UI during data fetching, initialization, or screen transitions. It creates a smooth animation that mimics the structure of the actual content, enhancing user experience by reducing perceived loading time.

## Components

The shimmer system includes:

1. `shimmer_widgets.dart` - Base reusable components:
   - `ShimmerWidgets.shimmerBox()` - Basic rectangle boxes
   - `ShimmerWidgets.shimmerCircle()` - Circle shapes for avatars/logos
   - `ShimmerWidgets.shimmerCard()` - Card containers
   - `ShimmerWidgets.shimmerTextField()` - Form input field shapes
   - `ShimmerWidgets.shimmerButton()` - Button shapes
   - `ShimmerWidgets.shimmerText()` - Text line placeholders
   - `ShimmerWidgets.shimmerListItem()` - List item with avatar and text

2. Screen-specific shimmer layouts:
   - `launch_shimmer.dart` - Launch screen placeholder
   - `login_shimmer.dart` - Login screen placeholder
   - `signup_shimmer.dart` - Sign up screen placeholder
   - `forgot_password_shimmer.dart` - Forgot password screen placeholder
   - `dashboard_shimmer.dart` - Dashboard screen placeholder

3. `shimmer_exports.dart` - Single import file for all shimmer components

## Usage

### Basic Implementation in a Screen

```dart
import 'package:flutter/material.dart';
import 'package:startwell/widgets/shimmer/shimmer_exports.dart';

class NewScreen extends StatefulWidget {
  @override
  _NewScreenState createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Simulate data loading
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer while loading
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // App bar shimmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ShimmerWidgets.shimmerCircle(size: 40),
                    const SizedBox(width: 16),
                    ShimmerWidgets.shimmerText(width: 150),
                  ],
                ),
              ),
              
              // Content shimmer examples
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ShimmerWidgets.shimmerBox(height: 120),
                        ShimmerWidgets.shimmerListItem(),
                        ShimmerWidgets.shimmerListItem(),
                        ShimmerWidgets.shimmerListItem(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Actual screen content
    return Scaffold(
      // Your actual UI here
    );
  }
}
```

### Creating a Custom Shimmer Widget

For new screens, you can create a dedicated shimmer layout:

1. Create a new file like `new_screen_shimmer.dart`
2. Design the shimmer layout to match the UI structure of the actual screen
3. Add the export to `shimmer_exports.dart`
4. Use it in your screen with a loading state

## Customization

The color and animation timing can be customized in the `shimmer_widgets.dart` file:

- Base color: `AppColors.primary.withOpacity(0.2)`
- Highlight color: `AppColors.primary.withOpacity(0.05)`
- Animation duration: `Duration(milliseconds: 1500)`

## Best Practices

1. Match shimmer shapes and sizes to the actual UI elements they represent
2. Use consistent spacing in shimmer layouts
3. For optimal performance, avoid excessive nesting of shimmer widgets
4. Use shimmer effects only for short loading periods (1-3 seconds) 