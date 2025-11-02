import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './subscription_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null && response.session != null) {
        // User profile and trial subscription are created automatically via trigger
        debugPrint('User signed up successfully with trial subscription');
      }

      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        // Check subscription status after sign in
        await _checkAndUpdateSubscriptionStatus();
      }

      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Check and update subscription status on sign in
  Future<void> _checkAndUpdateSubscriptionStatus() async {
    try {
      final subscriptionService = SubscriptionService.instance;
      final subscriptionStatus =
          await subscriptionService.getSubscriptionStatus();

      debugPrint('User subscription status: $subscriptionStatus');

      // If user doesn't have a subscription, create a trial
      if (!subscriptionStatus['hasSubscription']) {
        await subscriptionService.createTrialSubscription();
        debugPrint('Created trial subscription for existing user');
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      // Don't throw here as auth was successful
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    bool? isPremium,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (isPremium != null) updates['is_premium'] = isPremium;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await _client
            .from('user_profiles')
            .update(updates)
            .eq('id', currentUser!.id);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if user has premium access (includes trial)
  Future<bool> hasPremiumAccess() async {
    if (!isAuthenticated) return false;

    try {
      final subscriptionService = SubscriptionService.instance;
      return await subscriptionService.canAccessPremiumFeatures();
    } catch (e) {
      debugPrint('Error checking premium access: $e');

      // Fallback to user profile is_premium flag
      try {
        final profile = await getUserProfile();
        return profile?['is_premium'] ?? false;
      } catch (fallbackError) {
        debugPrint('Fallback premium check failed: $fallbackError');
        return false;
      }
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false;
    }
  }

  // Get authentication error message
  String getAuthErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('invalid_credentials') ||
        errorStr.contains('invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (errorStr.contains('email_not_confirmed')) {
      return 'Please check your email and click the confirmation link before signing in.';
    } else if (errorStr.contains('too_many_requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    } else if (errorStr.contains('user_not_found')) {
      return 'No account found with this email address.';
    } else if (errorStr.contains('weak_password')) {
      return 'Password is too weak. Please use at least 8 characters with numbers and symbols.';
    } else if (errorStr.contains('email_address_invalid')) {
      return 'Please enter a valid email address.';
    } else if (errorStr.contains('signup_disabled')) {
      return 'Account registration is currently disabled.';
    } else if (errorStr.contains('email_address_not_authorized')) {
      return 'This email address is not authorized to create an account.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }
}
