import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final String userName;
  final VoidCallback? onStartWriting;

  const EmptyStateWidget({
    Key? key,
    required this.userName,
    this.onStartWriting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 40.w,
            height: 40.w,
            child: CustomImageWidget(
              imageUrl:
                  "https://images.unsplash.com/photo-1544027993-37dbfe43562a?w=400",
              semanticLabel:
                  "Person writing in a journal with peaceful expression",
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(height: 4.h),

          // Welcome message with user name
          Text(
            'Welcome to your journal, $userName!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 2.h),

          // Description
          Text(
            'Your personal space for reflection and growth. Start by writing your first entry and discover insights about your emotional journey.',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // Start writing button
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 80.w),
            height: 6.h,
            child: ElevatedButton.icon(
              onPressed: onStartWriting,
              icon: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 5.w,
              ),
              label: Text(
                'Start Your First Entry',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Tips section
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 85.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Quick Tips',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildTip('Write freely about your day or feelings'),
                _buildTip('Use voice-to-text for quick entries'),
                _buildTip('Track your mood patterns over time'),
                _buildTip('Let AI provide insights on your entries'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.w,
            height: 1.w,
            margin: EdgeInsets.only(top: 2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.primary.withValues(
                alpha: 0.6,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}