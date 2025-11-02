import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UserProfileWidget extends StatelessWidget {
  final String? userAvatar;
  final String userInitial;

  const UserProfileWidget({
    Key? key,
    this.userAvatar,
    required this.userInitial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15.w,
      height: 15.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: userAvatar != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15.w),
              child: CustomImageWidget(
                imageUrl: userAvatar!,
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
                semanticLabel:
                    "User profile avatar showing a person's face for biometric authentication",
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.colorScheme.primary,
                    AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  userInitial.toUpperCase(),
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }
}
