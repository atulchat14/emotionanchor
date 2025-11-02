import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class SubscriptionService {
  static SubscriptionService? _instance;
  static SubscriptionService get instance =>
      _instance ??= SubscriptionService._();

  SubscriptionService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Get current user's subscription details
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final response = await _client
          .rpc('get_user_subscription', params: {'user_uuid': currentUser.id});

      if (response != null && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user subscription: $e');
      rethrow;
    }
  }

  // Check if user has active subscription or trial
  Future<bool> hasActiveSubscription() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _client.rpc('has_active_subscription',
          params: {'user_uuid': currentUser.id});

      return response == true;
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      return false;
    }
  }

  // Get subscription status with details
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final subscription = await getUserSubscription();
      final hasActive = await hasActiveSubscription();

      if (subscription == null) {
        return {
          'hasSubscription': false,
          'isActive': false,
          'plan': 'none',
          'status': 'none',
          'daysRemaining': 0,
          'isTrial': false,
        };
      }

      return {
        'hasSubscription': true,
        'isActive': hasActive,
        'subscriptionId': subscription['subscription_id'],
        'plan': subscription['plan'] ?? 'free',
        'status': subscription['status'] ?? 'none',
        'daysRemaining': subscription['days_remaining'] ?? 0,
        'isTrial': subscription['is_trial'] ?? false,
        'trialEndDate': subscription['trial_end_date'],
        'subscriptionEndDate': subscription['subscription_end_date'],
      };
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      return {
        'hasSubscription': false,
        'isActive': false,
        'plan': 'none',
        'status': 'error',
        'daysRemaining': 0,
        'isTrial': false,
        'error': e.toString(),
      };
    }
  }

  // Create trial subscription for user (called during onboarding)
  Future<String?> createTrialSubscription() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final response = await _client.rpc('create_trial_subscription',
          params: {'user_uuid': currentUser.id});

      if (response != null) {
        debugPrint('Trial subscription created: $response');
        return response.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error creating trial subscription: $e');
      rethrow;
    }
  }

  // Upgrade to premium subscription
  Future<Map<String, dynamic>> upgradeToPremium({
    required String plan, // 'premium_monthly' or 'premium_yearly'
    String? stripeCustomerId,
    String? stripeSubscriptionId,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final subscriptionData = {
        'user_id': currentUser.id,
        'plan': plan,
        'status': 'active',
        'subscription_start_date': DateTime.now().toIso8601String(),
        'subscription_end_date': plan == 'premium_monthly'
            ? DateTime.now().add(Duration(days: 30)).toIso8601String()
            : DateTime.now().add(Duration(days: 365)).toIso8601String(),
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
        'is_auto_renew': true,
      };

      // Update existing subscription or insert new one
      final response = await _client
          .from('subscriptions')
          .upsert(subscriptionData)
          .select()
          .single();

      // Update user profile to premium
      await _client.from('user_profiles').update({
        'is_premium': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', currentUser.id);

      debugPrint('Successfully upgraded to premium: $plan');
      return response;
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      rethrow;
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _client.from('subscriptions').update({
        'status': 'cancelled',
        'is_auto_renew': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUser.id);

      debugPrint('Subscription cancelled successfully');
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  // Reactivate subscription
  Future<void> reactivateSubscription() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _client.from('subscriptions').update({
        'status': 'active',
        'is_auto_renew': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUser.id);

      debugPrint('Subscription reactivated successfully');
    } catch (e) {
      debugPrint('Error reactivating subscription: $e');
      rethrow;
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final response = await _client
          .from('payment_history')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  // Record payment
  Future<void> recordPayment({
    required String subscriptionId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String? stripePaymentIntentId,
    String status = 'paid',
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _client.from('payment_history').insert({
        'user_id': currentUser.id,
        'subscription_id': subscriptionId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'stripe_payment_intent_id': stripePaymentIntentId,
        'payment_status': status,
        'payment_date': DateTime.now().toIso8601String(),
      });

      debugPrint('Payment recorded successfully');
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  // Check if user can access premium features
  Future<bool> canAccessPremiumFeatures() async {
    try {
      final status = await getSubscriptionStatus();
      return status['isActive'] == true;
    } catch (e) {
      debugPrint('Error checking premium access: $e');
      return false;
    }
  }

  // Get trial days remaining
  Future<int> getTrialDaysRemaining() async {
    try {
      final subscription = await getUserSubscription();
      if (subscription != null && subscription['is_trial'] == true) {
        return subscription['days_remaining'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting trial days remaining: $e');
      return 0;
    }
  }

  // Check if trial is about to expire (3 days or less)
  Future<bool> isTrialExpiringSoon() async {
    try {
      final daysRemaining = await getTrialDaysRemaining();
      return daysRemaining <= 3 && daysRemaining > 0;
    } catch (e) {
      debugPrint('Error checking trial expiry: $e');
      return false;
    }
  }

  // Get subscription pricing info (static data for display)
  Map<String, Map<String, dynamic>> getSubscriptionPlans() {
    return {
      'free': {
        'name': 'Free',
        'price': 0.0,
        'currency': 'USD',
        'interval': 'forever',
        'features': [
          'Basic journal entries',
          'Local storage',
          'Simple mood tracking',
        ],
      },
      'premium_monthly': {
        'name': 'Premium Monthly',
        'price': 9.99,
        'currency': 'USD',
        'interval': 'month',
        'features': [
          'Unlimited journal entries',
          'AI-powered insights',
          'Advanced mood analytics',
          'Cloud sync across devices',
          'Export capabilities',
          'Priority support',
        ],
      },
      'premium_yearly': {
        'name': 'Premium Yearly',
        'price': 99.99,
        'currency': 'USD',
        'interval': 'year',
        'originalPrice': 119.88,
        'savings': '17%',
        'features': [
          'Everything in Premium Monthly',
          'Annual billing discount',
          'Priority feature requests',
          'Extended AI insights',
        ],
      },
    };
  }

  // Format subscription status for display
  String formatSubscriptionStatus(Map<String, dynamic> status) {
    if (!status['hasSubscription']) {
      return 'No subscription';
    }

    final isTrial = status['isTrial'] == true;
    final daysRemaining = status['daysRemaining'] ?? 0;
    final plan = status['plan'] ?? 'Unknown';

    if (isTrial) {
      if (daysRemaining > 0) {
        return 'Free Trial - $daysRemaining days remaining';
      } else {
        return 'Trial Expired';
      }
    } else {
      switch (status['status']) {
        case 'active':
          return 'Active - ${plan.replaceAll('_', ' ').toUpperCase()}';
        case 'cancelled':
          return 'Cancelled - Access until ${_formatDate(status['subscriptionEndDate'])}';
        case 'expired':
          return 'Expired';
        default:
          return 'Status: ${status['status']}';
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
