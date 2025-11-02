import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/onboarding_navigation_widget.dart';
import './widgets/onboarding_page_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;
  final int _totalPages = 3;

  // Onboarding data
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Private AI Journaling',
      'description':
          'Your thoughts are safe with end-to-end encryption. Write freely knowing your personal reflections remain completely private and secure.',
      'iconName': 'lock',
      'iconColor': AppTheme.primaryLight,
    },
    {
      'title': 'Emotional Insights',
      'description':
          'Discover patterns in your emotions with AI-powered analysis. Track your mood journey and gain deeper self-awareness through intelligent insights.',
      'iconName': 'psychology',
      'iconColor': AppTheme.accentLight,
    },
    {
      'title': 'Stress Relief Tools',
      'description':
          'Access guided prompts and personalized reflection suggestions. Transform daily stress into meaningful growth with AI-enhanced wellness support.',
      'iconName': 'spa',
      'iconColor': AppTheme.successLight,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Haptic feedback for page changes
    HapticFeedback.lightImpact();

    // Animation for smooth transitions
    _animationController.forward().then((_) {
      _animationController.reset();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToRegistration();
    }
  }

  void _skipOnboarding() {
    _navigateToRegistration();
  }

  void _navigateToRegistration() {
    Navigator.pushReplacementNamed(context, '/account-registration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Main content area with PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                final data = _onboardingData[index];
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.8,
                        end: 1.0,
                      ).animate(_animationController),
                      child: OnboardingPageWidget(
                        title: data['title'] as String,
                        description: data['description'] as String,
                        iconName: data['iconName'] as String,
                        iconColor: data['iconColor'] as Color,
                        isLastPage: index == _totalPages - 1,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom navigation area
          OnboardingNavigationWidget(
            onSkip: _skipOnboarding,
            onNext: _nextPage,
            isLastPage: _currentPage == _totalPages - 1,
            currentPage: _currentPage,
            totalPages: _totalPages,
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
