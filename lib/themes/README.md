# StartWell App Theme System

This document explains how to use the StartWell app's centralized theming system to ensure consistency across all screens.

## Theme Architecture

The theming system is organized as follows:

1. **AppTheme** (`app_theme.dart`) - The centralized theme definition with all colors, gradients, and ThemeData
2. **AppColors** (`app_colors.dart`) - Legacy colors class that references AppTheme (for backward compatibility)
3. **UIComponents** (`ui_components.dart`) - Reusable UI components that follow the theme

## Color Palette

Our app uses a consistent color palette:

### Primary & Secondary Colors

- 🟣 **Purple** (`#8E44AD`) - Primary brand color for buttons, app bars, titles, icons
- 🔵 **Deep Purple** (`#5D3D9C`) - Used in gradients, CTA highlights, shadows
- 🟠 **Orange** (`#F39C12`) - For accent areas like tags, highlights, illustrations  
- 🟡 **Yellow** (`#F1C40F`) - Used in cards, badges, onboarding screens, highlights
- ⚪ **White & Off-White** - Used as background/base layer

### Using Colors

Always use the colors from the centralized theme:

```dart
// Good - use theme colors
Container(
  color: AppTheme.purple,
  child: Text('Hello'),
)

// Bad - hardcoded colors
Container(
  color: Color(0xFF8E44AD),
  child: Text('Hello'),
)
```

## Gradients

The theme system provides commonly used gradients:

- `AppTheme.purpleToDeepPurple` - Purple to Deep Purple
- `AppTheme.purpleToOrange` - Purple to Orange
- `AppTheme.deepPurpleToYellow` - Deep Purple to Yellow
- `AppTheme.orangeToYellow` - Orange to Yellow

Usage example:

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.purpleToOrange,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text('Gradient Background'),
)
```

## Reusable UI Components

The `UIComponents` class provides pre-styled components:

### Gradient Button

```dart
UIComponents.gradientButton(
  text: 'Sign Up',
  onPressed: () => {},
  gradient: AppTheme.purpleToOrange, // Optional custom gradient
)
```

### Custom Card

```dart
UIComponents.customCard(
  child: Column(
    children: [
      Text('Card Title'),
      Text('Card content goes here'),
    ],
  ),
  gradient: AppTheme.orangeToYellow, // Optional
  elevated: true, // Optional drop shadow
)
```

### Custom Text Field

```dart
final controller = TextEditingController();

UIComponents.customTextField(
  label: 'Email Address',
  controller: controller,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.email, color: AppTheme.purple),
)
```

### Section Title

```dart
UIComponents.sectionTitle(
  title: 'Popular Meals',
  gradient: AppTheme.purpleToOrange, // Optional gradient text
)
```

### Badge

```dart
UIComponents.badge(
  text: 'New',
  gradient: AppTheme.orangeToYellow,
)
```

### Gradient Avatar

```dart
UIComponents.gradientAvatar(
  size: 60,
  child: Icon(Icons.person, color: Colors.white, size: 36),
)
```

## Design Guidelines

When building new screens:

1. Use `AppTheme.purple` for primary actions, app bars, and key UI elements
2. Use gradients for visual interest on buttons, cards, and backgrounds
3. Use off-white (`AppTheme.offWhite`) for card backgrounds and sections
4. Use pure white (`AppTheme.white`) for page backgrounds
5. Use `AppTheme.orange` and `AppTheme.yellow` as accent colors for attention-grabbing elements

## Using ThemeData

The app's ThemeData is auto-applied to Material widgets. For example:

```dart
// These will automatically use themed styles
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),
)

AppBar(
  title: Text('Screen Title'),
)

TextField(
  decoration: InputDecoration(
    labelText: 'Input Field',
  ),
)
```

## AppBar Styling

StartWell app features beautifully styled AppBars with rounded bottom corners for a modern look:

### Standard AppBar
The default AppBar theme includes:
- Purple background color
- White text with Poppins font
- Rounded bottom corners (16px radius)
- Proper elevation for subtle shadows
- Centered title by default

```dart
AppBar(
  title: Text('Screen Title'),
  // All styling is automatically applied through the theme
)
```

### Gradient AppBar
For screens that need more visual appeal, use the GradientAppBar:

```dart
GradientAppBar(
  titleText: 'Screen Title',
  // Optional custom gradient
  customGradient: AppTheme.orangeToYellow,
  // Optional custom elevation
  elevation: 3,
)
```

### Helper Methods
You can also use the UIComponents helper for quick implementation:

```dart
UIComponents.gradientAppBar(
  title: 'Screen Title',
  context: context,
  // Optional parameters
  actions: [IconButton(...)],
  customGradient: AppTheme.deepPurpleToYellow,
  elevation: 2,
)
```

## Shadows

The theme provides consistent shadow styles:

```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppTheme.softShadow, // Light shadow
    // or
    // boxShadow: AppTheme.mediumShadow, // Stronger shadow
  ),
)
```

## Text Styles

Use the theme's text styles for consistent typography:

```dart
Text(
  'Heading Text',
  style: Theme.of(context).textTheme.headlineMedium,
)

Text(
  'Body Text',
  style: Theme.of(context).textTheme.bodyMedium,
)
```

## Future Screens

When creating new screens, ensure they follow the theme conventions:
- App bars in Purple
- White/Off-White backgrounds
- Cards & Containers in Off-White with light shadows
- Buttons in Purple with purple/orange gradients
- Highlight texts/icons using Orange or Yellow when needed 