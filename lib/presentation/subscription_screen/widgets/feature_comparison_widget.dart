import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FeatureComparisonWidget extends StatelessWidget {
  const FeatureComparisonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Journal Entries',
        'free': '5 per month',
        'premium': 'Unlimited',
        'icon': 'edit_note',
      },
      {
        'title': 'AI Mood Analysis',
        'free': 'Basic insights',
        'premium': 'Advanced patterns',
        'icon': 'psychology',
      },
      {
        'title': 'Data Export',
        'free': false,
        'premium': true,
        'icon': 'file_download',
      },
      {
        'title': 'Cloud Backup',
        'free': false,
        'premium': true,
        'icon': 'cloud_upload',
      },
      {
        'title': 'Priority Support',
        'free': false,
        'premium': true,
        'icon': 'support_agent',
      },
      {
        'title': 'Custom Insights',
        'free': false,
        'premium': true,
        'icon': 'insights',
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Feature Comparison',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'See what\'s included with each plan',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 3.h),

          // Comparison Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Features',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 1.h),

          // Features List
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;

            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
                  child: Row(
                    children: [
                      // Feature Icon and Name
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: feature['icon'] as String,
                                  size: 4.w,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                feature['title'] as String,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Free Plan
                      Expanded(
                        child: _buildFeatureValue(feature['free'], false),
                      ),

                      // Premium Plan
                      Expanded(
                        child: _buildFeatureValue(feature['premium'], true),
                      ),
                    ],
                  ),
                ),

                // Divider (except for last item)
                if (index < features.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppTheme.lightTheme.dividerColor,
                    indent: 3.w,
                    endIndent: 3.w,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureValue(dynamic value, bool isPremium) {
    if (value is bool) {
      return Center(
        child: Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: value
                ? (isPremium
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.tertiary)
                : AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: value ? 'check' : 'close',
              size: 3.w,
              color:
                  value ? Colors.white : AppTheme.lightTheme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        value as String,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: isPremium
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
          fontWeight: isPremium ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
