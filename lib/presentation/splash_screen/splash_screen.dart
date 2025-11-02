import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/animated_logo_widget.dart';
import './widgets/app_title_widget.dart';
import './widgets/gradient_background_widget.dart';
import './widgets/loading_indicator_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late Animation<double> _fadeInAnimation;

  String _loadingText = 'Initializing secure services...';
  bool _isInitialized = false;

  // Mock initialization states
  final List<Map<String, dynamic>> _initializationSteps = [
    {
      'text': 'Initializing secure services...',
      'duration': 800,
    },
    {
      'text': 'Checking authentication status...',
      'duration': 600,
    },
    {
      'text': 'Validating biometric availability...',
      'duration': 700,
    },
    {
      'text': 'Preparing AI services...',
      'duration': 500,
    },
    {
      'text': 'Setting up encryption...',
      'duration': 400,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
    _setSystemUIOverlay();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeIn,
    ));

    _mainAnimationController.forward();
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization process with realistic steps
      for (int i = 0; i < _initializationSteps.length; i++) {
        if (mounted) {
          setState(() {
            _loadingText = _initializationSteps[i]['text'];
          });
        }

        await Future.delayed(
          Duration(milliseconds: _initializationSteps[i]['duration']),
        );
      }

      // Final initialization complete
      if (mounted) {
        setState(() {
          _loadingText = 'Welcome to EmotionAnchor';
          _isInitialized = true;
        });
      }

      // Wait a moment before navigation
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        setState(() {
          _loadingText = 'Preparing your wellness journey...';
        });

        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          _navigateToNextScreen();
        }
      }
    }
  }

  void _navigateToNextScreen() {
    // Mock authentication status check
    final bool isAuthenticated = _checkAuthenticationStatus();
    final bool hasBiometricSetup = _checkBiometricSetup();
    final bool isFirstTime = _checkFirstTimeUser();

    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/onboarding-flow');
    } else if (!isAuthenticated || !hasBiometricSetup) {
      Navigator.pushReplacementNamed(context, '/biometric-authentication');
    } else {
      Navigator.pushReplacementNamed(context, '/journal-dashboard');
    }
  }

  bool _checkAuthenticationStatus() {
    // Mock authentication check
    // In real implementation, this would check secure storage for auth tokens
    return false; // Simulating unauthenticated user
  }

  bool _checkBiometricSetup() {
    // Mock biometric availability check
    // In real implementation, this would check device biometric capabilities
    return true; // Simulating biometric available
  }

  bool _checkFirstTimeUser() {
    // Mock first-time user check
    // In real implementation, this would check shared preferences
    return true; // Simulating first-time user
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundWidget(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SizedBox(
              width: 100.w,
              height: 100.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spacer to push content to center
                  const Spacer(flex: 2),

                  // Animated Logo
                  const AnimatedLogoWidget(),

                  SizedBox(height: 4.h),

                  // App Title with Animation
                  const AppTitleWidget(),

                  // Spacer for loading indicator positioning
                  const Spacer(flex: 2),

                  // Loading Indicator
                  LoadingIndicatorWidget(
                    loadingText: _loadingText,
                  ),

                  SizedBox(height: 6.h),

                  // Privacy and Security Notice
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      'Your privacy and emotional wellness are our priority. All data is encrypted and secure.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
