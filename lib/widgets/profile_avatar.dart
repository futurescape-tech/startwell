import 'dart:io';
import 'package:flutter/material.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/themes/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final UserProfile? userProfile;
  final double radius;
  final bool showEditIcon;
  final VoidCallback? onEditTap;
  final VoidCallback? onAvatarTap;
  final Color? backgroundColor;
  final Color? initialsColor;

  const ProfileAvatar({
    Key? key,
    this.userProfile,
    this.radius = 20,
    this.showEditIcon = false,
    this.onEditTap,
    this.onAvatarTap,
    this.backgroundColor,
    this.initialsColor,
  }) : super(key: key);

  String _getInitials() {
    if (userProfile == null || userProfile!.name.isEmpty) {
      return '?';
    }

    final nameParts = userProfile!.name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return nameParts[0][0].toUpperCase() + nameParts.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? AppTheme.white;
    final defaultInitialsColor = initialsColor ?? AppTheme.purple;

    Widget avatar;

    // Determine if we have a profile image to display
    if (userProfile?.profileImageUrl != null &&
        userProfile!.profileImageUrl!.isNotEmpty) {
      try {
        // Check if the file exists and is accessible
        final file = File(userProfile!.profileImageUrl!);
        if (file.existsSync()) {
          avatar = CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
            backgroundColor: defaultBackgroundColor,
          );
        } else {
          // Fallback to initials if file doesn't exist
          avatar = _buildInitialsAvatar(
              defaultBackgroundColor, defaultInitialsColor);
        }
      } catch (e) {
        // Handle any exceptions (e.g., file permission issues)
        print('Error loading profile image: $e');
        avatar =
            _buildInitialsAvatar(defaultBackgroundColor, defaultInitialsColor);
      }
    } else {
      // No profile image, display initials
      avatar =
          _buildInitialsAvatar(defaultBackgroundColor, defaultInitialsColor);
    }

    // Wrap with GestureDetector if onAvatarTap is provided
    if (onAvatarTap != null) {
      avatar = GestureDetector(
        onTap: onAvatarTap,
        child: avatar,
      );
    }

    // Add edit icon if requested
    if (showEditIcon) {
      return Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.purple,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  CircleAvatar _buildInitialsAvatar(
      Color backgroundColor, Color initialsColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: initialsColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
