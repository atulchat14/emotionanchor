import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../journal_dashboard/journal_dashboard.dart';
import './widgets/feature_comparison_widget.dart';
import './widgets/pricing_card_widget.dart';
import './widgets/subscription_actions_widget.dart';
import './widgets/subscription_header_widget.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final AuthService _authService = AuthService.instance;

  Map<String, dynamic> _subscriptionStatus = {};
  Map<String, Map<String, dynamic>> _plans = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() => _isLoading = true);

      final status = await _subscriptionService.getSubscriptionStatus();
      final plans = _subscriptionService.getSubscriptionPlans();

      setState(() {
        _subscriptionStatus = status;
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load subscription data: ${e.toString()}');
    }
  }

  Future<void> _handlePlanSelection(String planKey) async {
    if (planKey == 'free') {
      // Navigate back to dashboard for free plan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const JournalDashboard()),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // In a real app, you would integrate with Stripe or another payment provider
      // For now, we'll simulate the upgrade process
      await _simulatePaymentFlow(planKey);

      setState(() => _isProcessing = false);
      _showSuccessDialog(planKey);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Failed to upgrade subscription: ${e.toString()}');
    }
  }

  Future<void> _simulatePaymentFlow(String planKey) async {
    // Simulate payment processing delay
    await Future.delayed(Duration(seconds: 2));

    // In a real implementation, you would:
    // 1. Create Stripe customer
    // 2. Create payment intent
    // 3. Handle payment confirmation
    // 4. Update subscription on success

    // For demo purposes, we'll directly upgrade the subscription
    await _subscriptionService.upgradeToPremium(
      plan: planKey,
      stripeCustomerId: 'demo_customer_id',
      stripeSubscriptionId: 'demo_subscription_id',
    );

    // Record the payment
    final plan = _plans[planKey]!;
    await _subscriptionService.recordPayment(
      subscriptionId: 'demo_subscription_id',
      amount: plan['price'],
      currency: plan['currency'],
      paymentMethod: 'demo_card',
      status: 'paid',
    );
  }

  void _showSuccessDialog(String planKey) {
    final planName = _plans[planKey]?['name'] ?? 'Premium';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Welcome to $planName!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your subscription has been activated successfully.'),
            SizedBox(height: 16),
            Text(
              'You now have access to all premium features:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ..._plans[planKey]!['features']
                .map<Widget>(
                  (feature) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                            child:
                                Text(feature, style: TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const JournalDashboard()),
              );
            },
            child: Text('Start Journaling'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading subscription options...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Choose Your Plan'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subscription Header
                SubscriptionHeaderWidget(
                  subscriptionStatus: _subscriptionStatus,
                  onRefresh: _loadSubscriptionData,
                ),

                SizedBox(height: 24),

                // Pricing Cards
                Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),

                SizedBox(height: 16),

                // Free Plan Card
                PricingCardWidget(
                  planType: _plans['free']!['name'],
                  price: '\$${_plans['free']!['price']}',
                  period: _plans['free']!['period'],
                  features: List<String>.from(_plans['free']!['features']),
                  planKey: 'free',
                  isCurrentPlan: _subscriptionStatus['plan'] == 'free' &&
                      !(_subscriptionStatus['isTrial'] ?? false),
                  isRecommended: false,
                  onSelect: _handlePlanSelection,
                ),

                SizedBox(height: 16),

                // Premium Monthly Plan Card
                PricingCardWidget(
                  planType: _plans['premium_monthly']!['name'],
                  price: '\$${_plans['premium_monthly']!['price']}',
                  period: _plans['premium_monthly']!['period'],
                  features: List<String>.from(_plans['premium_monthly']!['features']),
                  planKey: 'premium_monthly',
                  isCurrentPlan:
                      _subscriptionStatus['plan'] == 'premium_monthly',
                  isRecommended: false,
                  onSelect: _handlePlanSelection,
                ),

                SizedBox(height: 16),

                // Premium Yearly Plan Card (Recommended)
                PricingCardWidget(
                  planType: _plans['premium_yearly']!['name'],
                  price: '\$${_plans['premium_yearly']!['price']}',
                  period: _plans['premium_yearly']!['period'],
                  features: List<String>.from(_plans['premium_yearly']!['features']),
                  planKey: 'premium_yearly',
                  isCurrentPlan:
                      _subscriptionStatus['plan'] == 'premium_yearly',
                  isRecommended: true,
                  onSelect: _handlePlanSelection,
                ),

                SizedBox(height: 24),

                // Feature Comparison
                FeatureComparisonWidget(),

                SizedBox(height: 24),

                // Subscription Actions
                if (_subscriptionStatus['hasSubscription'] == true)
                  SubscriptionActionsWidget(
                    selectedPlan: _subscriptionStatus['plan'] ?? 'free',
                    onCancel: _handleCancelSubscription,
                    onReactivate: _handleReactivateSubscription,
                  ),

                SizedBox(height: 100), // Space for processing overlay
              ],
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing your subscription...',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait while we set up your premium access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel your subscription? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isProcessing = true);
        await _subscriptionService.cancelSubscription();
        await _loadSubscriptionData();
        setState(() => _isProcessing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar('Failed to cancel subscription: ${e.toString()}');
      }
    }
  }

  Future<void> _handleReactivateSubscription() async {
    try {
      setState(() => _isProcessing = true);
      await _subscriptionService.reactivateSubscription();
      await _loadSubscriptionData();
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription reactivated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Failed to reactivate subscription: ${e.toString()}');
    }
  }
}