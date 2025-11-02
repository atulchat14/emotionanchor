import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InsightsTimelineWidget extends StatelessWidget {
  final Map<String, dynamic> insight;
  final VoidCallback? onTap;

  const InsightsTimelineWidget({
    Key? key,
    required this.insight,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineIndicator(),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: _getInsightColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.w),
            border: Border.all(
              color: _getInsightColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: _getInsightIcon(),
              color: _getInsightColor(),
              size: 5.w,
            ),
          ),
        ),
        Container(
          width: 2,
          height: 4.h,
          color: _getInsightColor().withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final DateTime date = insight['date'] as DateTime;
    final String relativeTime = _getRelativeTime(date);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getInsightColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  insight['event'] ?? 'Insight Event',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getInsightColor(),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getInsightColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  relativeTime,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: _getInsightColor(),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            insight['description'] ?? 'No description available',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (insight['confidence'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'analytics',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Confidence: ${((insight['confidence'] as double) * 100).toStringAsFixed(0)}%',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (insight['relatedEntry'] != null)
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'link',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      insight['relatedEntry'],
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (onTap != null) ...[
            SizedBox(height: 2.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 9.sp,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    CustomIconWidget(
                      iconName: 'arrow_forward',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 3.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getInsightColor() {
    switch (insight['type']) {
      case 'positive':
        return Colors.green.shade500;
      case 'insight':
        return Colors.blue.shade500;
      case 'pattern':
        return Colors.orange.shade500;
      case 'warning':
        return Colors.red.shade500;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getInsightIcon() {
    switch (insight['type']) {
      case 'positive':
        return 'trending_up';
      case 'insight':
        return 'lightbulb';
      case 'pattern':
        return 'analytics';
      case 'warning':
        return 'warning';
      default:
        return 'info';
    }
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
