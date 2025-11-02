import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RegistrationFormWidget extends StatefulWidget {
  final Function(String name, String email, String password) onFormSubmit;
  final bool isLoading;

  const RegistrationFormWidget({
    Key? key,
    required this.onFormSubmit,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<RegistrationFormWidget> createState() => _RegistrationFormWidgetState();
}

class _RegistrationFormWidgetState extends State<RegistrationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isTermsAccepted = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text.trim();

    setState(() {
      if (name.isEmpty) {
        _isNameValid = false;
        _nameError = null;
      } else if (name.length < 2) {
        _isNameValid = false;
        _nameError = 'Name must be at least 2 characters';
      } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
        _isNameValid = false;
        _nameError = 'Name can only contain letters and spaces';
      } else {
        _isNameValid = true;
        _nameError = null;
      }
    });
  }

  void _validateEmail() {
    final email = _emailController.text;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    setState(() {
      if (email.isEmpty) {
        _isEmailValid = false;
        _emailError = null;
      } else if (!emailRegex.hasMatch(email)) {
        _isEmailValid = false;
        _emailError = 'Please enter a valid email address';
      } else {
        _isEmailValid = true;
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;

    setState(() {
      if (password.isEmpty) {
        _isPasswordValid = false;
        _passwordError = null;
      } else if (password.length < 8) {
        _isPasswordValid = false;
        _passwordError = 'Password must be at least 8 characters';
      } else if (!RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
      ).hasMatch(password)) {
        _isPasswordValid = false;
        _passwordError =
            'Password must contain uppercase, lowercase, and number';
      } else {
        _isPasswordValid = true;
        _passwordError = null;
      }
    });

    // Re-validate confirm password when password changes
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;

    setState(() {
      if (confirmPassword.isEmpty) {
        _isConfirmPasswordValid = false;
        _confirmPasswordError = null;
      } else if (confirmPassword != password) {
        _isConfirmPasswordValid = false;
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _isConfirmPasswordValid = true;
        _confirmPasswordError = null;
      }
    });
  }

  double _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return 0.0;

    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'\d').hasMatch(password)) strength += 0.25;

    return strength;
  }

  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrength();
    if (strength <= 0.25) return AppTheme.lightTheme.colorScheme.error;
    if (strength <= 0.5) return AppTheme.lightTheme.colorScheme.tertiary;
    if (strength <= 0.75) return Colors.orange;
    return Colors.green;
  }

  String _getPasswordStrengthText() {
    final strength = _getPasswordStrength();
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  bool get _isFormValid =>
      _isNameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _isConfirmPasswordValid &&
      _isTermsAccepted;

  void _submitForm() {
    if (_isFormValid && !widget.isLoading) {
      widget.onFormSubmit(
        _nameController.text.trim(),
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Name',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'person',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: _isNameValid ? 'check_circle' : 'error',
                              color: _isNameValid
                                  ? Colors.green
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          )
                        : null,
                    errorText: _nameError,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Email Field
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'email',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName:
                                  _isEmailValid ? 'check_circle' : 'error',
                              color: _isEmailValid
                                  ? Colors.green
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          )
                        : null,
                    errorText: _emailError,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Password Field
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Create a strong password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: _isPasswordVisible
                              ? 'visibility'
                              : 'visibility_off',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 5.w,
                        ),
                      ),
                    ),
                    errorText: _passwordError,
                  ),
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 0.5.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: AppTheme.lightTheme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _getPasswordStrength(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: _getPasswordStrengthColor(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _getPasswordStrengthText(),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: _getPasswordStrengthColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Confirm Password Field
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Password',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitForm(),
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'lock',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(right: 1.w),
                            child: CustomIconWidget(
                              iconName: _isConfirmPasswordValid
                                  ? 'check_circle'
                                  : 'error',
                              color: _isConfirmPasswordValid
                                  ? Colors.green
                                  : AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: _isConfirmPasswordVisible
                                  ? 'visibility'
                                  : 'visibility_off',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 5.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                    errorText: _confirmPasswordError,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Terms and Privacy Checkbox
          Container(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 6.w,
                  height: 6.w,
                  child: Checkbox(
                    value: _isTermsAccepted,
                    onChanged: (value) =>
                        setState(() => _isTermsAccepted = value ?? false),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Create Account Button
          Container(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isFormValid && !widget.isLoading ? _submitForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline.withValues(
                        alpha: 0.3,
                      ),
                foregroundColor: _isFormValid
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: AppTheme.lightTheme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          SizedBox(height: 2.h),

          // Sign In Button - Prominently displayed below Create Account
          Container(
            width: double.infinity,
            height: 6.h,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login-screen');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Already have an account? Sign In',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
