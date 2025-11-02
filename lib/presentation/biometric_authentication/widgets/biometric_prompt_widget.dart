import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BiometricPromptWidget extends StatefulWidget {
  final VoidCallback onBiometricPressed;
  final bool isLoading;
  final String biometricType;

  const BiometricPromptWidget({
    Key? key,
    required this.onBiometricPressed,
    required this.isLoading,
    required this.biometricType,
  }) : super(key: key);

  @override
  State<BiometricPromptWidget> createState() => _BiometricPromptWidgetState();
}

class _BiometricPromptWidgetState extends State<BiometricPromptWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getBiometricIcon() {
    switch (widget.biometricType.toLowerCase()) {
      case 'face':
        return 'face';
      case 'fingerprint':
        return 'fingerprint';
      default:
        return 'security';
    }
  }

  String _getBiometricText() {
    switch (widget.biometricType.toLowerCase()) {
      case 'face':
        return 'Use Face ID';
      case 'fingerprint':
        return 'Use Fingerprint';
      default:
        return 'Use Biometric';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Biometric Icon with Pulse Animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isLoading ? 1.0 : _pulseAnimation.value,
              child: GestureDetector(
                onTap: widget.isLoading ? null : widget.onBiometricPressed,
                child: Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: widget.isLoading
                      ? Center(
                          child: SizedBox(
                            width: 8.w,
                            height: 8.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: CustomIconWidget(
                            iconName: _getBiometricIcon(),
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 12.w,
                          ),
                        ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 4.h),

        // Biometric Text
        Text(
          widget.isLoading ? 'Verifying...' : _getBiometricText(),
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        // Subtitle
        Text(
          widget.isLoading
              ? 'Please wait while we verify your identity'
              : 'Touch the sensor to access your wellness journal',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
