import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import './widgets/registration_form_widget.dart';
import './widgets/registration_header_widget.dart';
import './widgets/registration_footer_widget.dart';

class AccountRegistration extends StatefulWidget {
  const AccountRegistration({Key? key}) : super(key: key);

  @override
  State<AccountRegistration> createState() => _AccountRegistrationState();
}

class _AccountRegistrationState extends State<AccountRegistration> {
  bool _isLoading = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Check if already authenticated
    _checkAuthState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAuthState() {
    if (AuthService.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/journal-dashboard');
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Scroll to ensure the focused field is visible
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.7,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _handleBackPressed() {
    Navigator.pop(context);
  }

  void _handleSignInPressed() {
    Navigator.pushReplacementNamed(context, '/login-screen');
  }

  Future<void> _handleRegistrationSubmit(
    String fullName,
    String email,
    String password,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // Check if email already exists
      final emailExists = await AuthService.instance.emailExists(email.trim());
      if (emailExists) {
        throw Exception('An account with this email already exists');
      }

      // Register with Supabase
      final response = await AuthService.instance.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );

      if (response.user != null) {
        // Success - provide haptic feedback
        HapticFeedback.lightImpact();

        // Initialize journal sync service
        await JournalSyncService.instance.initialize();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account created successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 1.h),
                Text(
                  response.session != null
                      ? 'Welcome to EmotionAnchor!'
                      : 'Please check your email for verification.',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate based on whether email confirmation is needed
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          if (response.session != null) {
            // User is immediately logged in
            Navigator.pushReplacementNamed(context, '/journal-dashboard');
          } else {
            // Email confirmation required
            Navigator.pushReplacementNamed(context, '/login-screen');
          }
        }
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      final errorMessage = AuthService.instance.getAuthErrorMessage(e);

      setState(() {
        _errorMessage = errorMessage;
      });

      // Show error with haptic feedback
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Header
              RegistrationHeaderWidget(onBackPressed: _handleBackPressed),

              // Main content with form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: ClampingScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 65.h),
                    child: Column(
                      children: [
                        // Form section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Focus(
                            focusNode: _focusNode,
                            child: RegistrationFormWidget(
                              onFormSubmit: _handleRegistrationSubmit,
                              isLoading: _isLoading,
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Footer section
                        RegistrationFooterWidget(
                          onSignInPressed: _handleSignInPressed,
                        ),

                        // Bottom padding for keyboard avoidance
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}