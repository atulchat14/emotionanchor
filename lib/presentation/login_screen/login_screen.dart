import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/login_header_widget.dart';
import './widgets/login_footer_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
            _scrollController.position.maxScrollExtent * 0.5,
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

  void _handleCreateAccountPressed() {
    Navigator.pushReplacementNamed(context, '/account-registration');
  }

  Future<void> _handleLoginSubmit(String email, String password) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // Authenticate with Supabase
      final response = await AuthService.instance.signIn(
        email: email.trim(),
        password: password,
      );

      if (response.user != null && response.session != null) {
        // Success - provide haptic feedback
        HapticFeedback.lightImpact();

        // Initialize journal sync service
        await JournalSyncService.instance.initialize();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back! Login successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate to dashboard
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/journal-dashboard');
        }
      } else {
        throw Exception('Authentication failed');
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
              LoginHeaderWidget(onBackPressed: _handleBackPressed),

              // Main content with form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: ClampingScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 60.h),
                    child: Column(
                      children: [
                        // Form section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Focus(
                            focusNode: _focusNode,
                            child: LoginFormWidget(
                              onFormSubmit: _handleLoginSubmit,
                              isLoading: _isLoading,
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Footer section
                        LoginFooterWidget(
                          onCreateAccountPressed: _handleCreateAccountPressed,
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
