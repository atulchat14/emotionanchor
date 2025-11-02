import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/account_registration/account_registration.dart';
import '../presentation/biometric_authentication/biometric_authentication.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/journal_writing_interface/journal_writing_interface.dart';
import '../presentation/journal_entry_detail_view/journal_entry_detail_view.dart';
import '../presentation/ai_insights_dashboard/ai_insights_dashboard.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/subscription_screen/subscription_screen.dart';
import '../presentation/main_navigation/main_navigation.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String accountRegistration = '/account-registration';
  static const String biometricAuthentication = '/biometric-authentication';
  static const String onboardingFlow = '/onboarding-flow';
  static const String journalWritingInterface = '/journal-writing-interface';
  static const String journalDashboard = '/journal-dashboard';
  static const String mainNavigation = '/main-navigation';
  static const String journalEntryDetailView = '/journal-entry-detail-view';
  static const String aiInsightsDashboard = '/ai-insights-dashboard';
  static const String settingsScreen = '/settings-screen';
  static const String subscriptionScreen = '/subscription-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    accountRegistration: (context) => const AccountRegistration(),
    biometricAuthentication: (context) => const BiometricAuthentication(),
    onboardingFlow: (context) => const OnboardingFlow(),
    journalWritingInterface: (context) => const JournalWritingInterface(),
    journalDashboard: (context) => const MainNavigation(),
    mainNavigation: (context) => const MainNavigation(),
    journalEntryDetailView: (context) => const JournalEntryDetailView(),
    aiInsightsDashboard: (context) => const AIInsightsDashboard(),
    settingsScreen: (context) => const SettingsScreen(),
    subscriptionScreen: (context) => const SubscriptionScreen(),
    // TODO: Add your other routes here
  };
}
