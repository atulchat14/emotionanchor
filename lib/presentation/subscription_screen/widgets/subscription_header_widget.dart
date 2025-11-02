import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SubscriptionHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> subscriptionStatus;
  final VoidCallback onRefresh;

  const SubscriptionHeaderWidget({
    Key? key,
    required this.subscriptionStatus,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSubscription = subscriptionStatus['hasSubscription'] ?? false;
    final isTrial = subscriptionStatus['isTrial'] ?? false;
    final isActive = subscriptionStatus['isActive'] ?? false;
    final daysRemaining = subscriptionStatus['daysRemaining'] ?? 0;
    final status = subscriptionStatus['status'] ?? 'none';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTrial
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : isActive
                  ? [AppTheme.primaryLight, AppTheme.accentLight]
                  : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                      _getHeaderTitle(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getHeaderSubtitle(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh subscription status',
              ),
            ],
          ),
          if (isTrial && daysRemaining > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '$daysRemaining days remaining in trial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isTrial && daysRemaining <= 3 && daysRemaining > 0) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(128)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trial ending soon! Upgrade to keep premium features.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'cancelled') ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(128)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subscription cancelled. Access continues until billing period ends.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!hasSubscription || status == 'expired') ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Premium Features:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8),
                  ..._getPremiumFeatures()
                      .map((feature) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 14),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    final hasSubscription = subscriptionStatus['hasSubscription'] ?? false;
    final isTrial = subscriptionStatus['isTrial'] ?? false;
    final isActive = subscriptionStatus['isActive'] ?? false;
    final status = subscriptionStatus['status'] ?? 'none';

    if (!hasSubscription) {
      return 'Start Your Journey';
    } else if (isTrial) {
      return 'Free Trial Active';
    } else if (isActive) {
      final plan = subscriptionStatus['plan'] ?? 'Premium';
      return '${plan.replaceAll('_', ' ').toUpperCase()} Member';
    } else if (status == 'cancelled') {
      return 'Subscription Cancelled';
    } else if (status == 'expired') {
      return 'Subscription Expired';
    } else {
      return 'Subscription Status';
    }
  }

  String _getHeaderSubtitle() {
    final hasSubscription = subscriptionStatus['hasSubscription'] ?? false;
    final isTrial = subscriptionStatus['isTrial'] ?? false;
    final isActive = subscriptionStatus['isActive'] ?? false;
    final status = subscriptionStatus['status'] ?? 'none';

    if (!hasSubscription) {
      return 'Choose a plan to unlock all features and start your premium journaling experience.';
    } else if (isTrial) {
      return 'Enjoy full premium access during your free trial period.';
    } else if (isActive) {
      return 'You have full access to all premium features and cloud sync.';
    } else if (status == 'cancelled') {
      return 'Reactivate anytime to continue with premium features.';
    } else if (status == 'expired') {
      return 'Renew your subscription to regain access to premium features.';
    } else {
      return 'Manage your subscription and billing preferences.';
    }
  }

  List<String> _getPremiumFeatures() {
    return [
      'AI-powered insights and mood analysis',
      'Unlimited cloud storage and sync',
      'Advanced analytics and trends',
      'Export and backup capabilities',
    ];
  }
}