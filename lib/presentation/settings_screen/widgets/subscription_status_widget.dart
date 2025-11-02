import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  final String subscriptionType;
  final int? trialDaysRemaining;
  final VoidCallback? onManageSubscription;

  const SubscriptionStatusWidget({
    Key? key,
    required this.subscriptionType,
    this.trialDaysRemaining,
    this.onManageSubscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(),
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: _getStatusIcon(),
                      size: 4.w,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _getStatusTitle(),
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              if (onManageSubscription != null)
                TextButton(
                  onPressed: onManageSubscription,
                  child: Text(
                    _getActionText(),
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            _getStatusDescription(),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          if (subscriptionType == 'trial' && trialDaysRemaining != null) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  size: 4.w,
                  color: Colors.white,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$trialDaysRemaining days remaining',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    switch (subscriptionType) {
      case 'premium':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
        );
      case 'trial':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.tertiary,
            AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.8),
          ],
        );
      default: // free
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.secondary,
            AppTheme.lightTheme.colorScheme.secondaryContainer,
          ],
        );
    }
  }

  String _getStatusIcon() {
    switch (subscriptionType) {
      case 'premium':
        return 'star';
      case 'trial':
        return 'schedule';
      default:
        return 'person';
    }
  }

  String _getStatusTitle() {
    switch (subscriptionType) {
      case 'premium':
        return 'PREMIUM';
      case 'trial':
        return 'FREE TRIAL';
      default:
        return 'FREE PLAN';
    }
  }

  String _getStatusDescription() {
    switch (subscriptionType) {
      case 'premium':
        return 'You have access to all premium features including unlimited entries, advanced AI insights, and priority support.';
      case 'trial':
        return 'You\'re currently on a free trial with access to all premium features. Upgrade to continue after your trial ends.';
      default:
        return 'You\'re using the free version with basic features. Upgrade to premium for unlimited access and advanced insights.';
    }
  }

  String _getActionText() {
    switch (subscriptionType) {
      case 'premium':
        return 'Manage';
      case 'trial':
        return 'Upgrade';
      default:
        return 'Upgrade';
    }
  }
}
