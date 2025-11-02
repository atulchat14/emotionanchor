import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/app_logo_widget.dart';
import './widgets/biometric_prompt_widget.dart';
import './widgets/error_message_widget.dart';
import './widgets/passcode_fallback_widget.dart';
import './widgets/privacy_message_widget.dart';
import './widgets/user_profile_widget.dart';

class BiometricAuthentication extends StatefulWidget {
  const BiometricAuthentication({Key? key}) : super(key: key);

  @override
  State<BiometricAuthentication> createState() =>
      _BiometricAuthenticationState();
}

class _BiometricAuthenticationState extends State<BiometricAuthentication>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  int _attemptsRemaining = 3;
  String _biometricType = 'fingerprint';
  String _userName = 'User'; // Default fallback name

  // Mock user data
  final Map<String, dynamic> _currentUser = {
    "id": 1,
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "avatar": "https://images.unsplash.com/photo-1727784892015-4f4b8d67a083",
    "semanticLabel":
        "Professional headshot of a woman with shoulder-length brown hair wearing a white blazer against a neutral background",
    "initial": "S",
    "biometricEnabled": true,
    "lastLogin": DateTime.now().subtract(Duration(hours: 8)),
  };

  @override
  void initState() {
    super.initState();
    _detectBiometricType();
    _triggerBiometricPrompt();

    // Get user name from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['userName'] != null) {
        setState(() {
          _userName = args['userName'] as String;
        });
      }
    });
  }

  void _detectBiometricType() {
    // Simulate biometric type detection
    setState(() {
      _biometricType = 'fingerprint'; // Default to fingerprint for demo
    });
  }

  Future<void> _triggerBiometricPrompt() async {
    await Future.delayed(Duration(milliseconds: 500));
    _authenticateWithBiometric();
  }

  Future<void> _authenticateWithBiometric() async {
    if (_attemptsRemaining <= 0) {
      _navigateToPasscode();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate biometric authentication
      await Future.delayed(Duration(seconds: 2));

      // Simulate random success/failure for demo
      bool isSuccess = DateTime.now().millisecond % 3 == 0;

      if (isSuccess) {
        _onAuthenticationSuccess();
      } else {
        _onAuthenticationFailure(
          'Biometric authentication failed. Please try again.',
        );
      }
    } catch (e) {
      _onAuthenticationFailure(
        'Authentication error occurred. Please try again.',
      );
    }
  }

  void _onAuthenticationSuccess() {
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Check if this is a first-time login to show subscription screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isFirstTimeLogin = args?['isFirstTimeLogin'] ?? false;

    if (isFirstTimeLogin) {
      // Navigate to subscription screen with first-time user context
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.subscriptionScreen,
        arguments: {
          'isFirstTimeUser': true,
        },
      );
    } else {
      // Navigate to journal dashboard for returning users
      Navigator.pushReplacementNamed(context, AppRoutes.journalDashboard);
    }
  }

  void _onAuthenticationFailure(String error) {
    setState(() {
      _isLoading = false;
      _errorMessage = error;
      _attemptsRemaining--;
    });

    // Provide error haptic feedback
    HapticFeedback.heavyImpact();

    if (_attemptsRemaining <= 0) {
      Future.delayed(Duration(seconds: 2), () {
        _navigateToPasscode();
      });
    }
  }

  void _navigateToPasscode() {
    // Navigate to passcode screen or account recovery
    Navigator.pushReplacementNamed(context, '/account-registration');
  }

  void _retryBiometric() {
    if (_attemptsRemaining > 0) {
      _authenticateWithBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightTheme.colorScheme.surface,
              AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section - App Logo and User Profile
                    Column(
                      children: [
                        SizedBox(height: 8.h),

                        // App Logo
                        AppLogoWidget(),

                        SizedBox(height: 4.h),

                        // User Profile
                        UserProfileWidget(
                          userAvatar: (_currentUser["avatar"] as String?),
                          userInitial: _currentUser["initial"] as String,
                        ),

                        SizedBox(height: 2.h),

                        // Welcome Message
                        Text(
                          'Welcome back, ${(_currentUser["name"] as String).split(' ').first}',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 1.h),

                        Text(
                          'Authenticate to access your wellness journal',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    // Middle Section - Biometric Authentication
                    Column(
                      children: [
                        SizedBox(height: 6.h),

                        // Error Message
                        if (_errorMessage != null && _attemptsRemaining > 0)
                          Column(
                            children: [
                              ErrorMessageWidget(
                                errorMessage: _errorMessage!,
                                attemptsRemaining: _attemptsRemaining,
                                onRetry: _retryBiometric,
                              ),
                              SizedBox(height: 4.h),
                            ],
                          ),

                        // Biometric Prompt
                        BiometricPromptWidget(
                          onBiometricPressed: _authenticateWithBiometric,
                          isLoading: _isLoading,
                          biometricType: _biometricType,
                        ),

                        SizedBox(height: 6.h),

                        // Passcode Fallback
                        if (!_isLoading && _attemptsRemaining > 0)
                          PasscodeFallbackWidget(
                            onPasscodePressed: _navigateToPasscode,
                          ),

                        // Max attempts reached message
                        if (_attemptsRemaining <= 0 && !_isLoading)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.error
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                CustomIconWidget(
                                  iconName: 'lock',
                                  color: AppTheme.lightTheme.colorScheme.error,
                                  size: 8.w,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Too Many Failed Attempts',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Redirecting to account recovery...',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Bottom Section - Privacy Message
                    Column(
                      children: [
                        SizedBox(height: 4.h),

                        PrivacyMessageWidget(),

                        SizedBox(height: 4.h),

                        // Exit App Option
                        TextButton(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          child: Text(
                            'Exit App',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
