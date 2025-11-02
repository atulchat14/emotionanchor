import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import '../../services/subscription_service.dart';
import '../subscription_screen/subscription_screen.dart';
import './widgets/app_version_widget.dart';
import './widgets/profile_section_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/subscription_status_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService.instance;
  final JournalSyncService _journalService = JournalSyncService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  Map<String, dynamic> _subscriptionStatus = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load subscription status: ${e.toString()}';
        });
      }
    }
  }

  // Helper method to safely extract string from user metadata
  String _safeGetUserName() {
    try {
      final user = _authService.currentUser;
      if (user?.userMetadata != null) {
        final fullName = user!.userMetadata!['full_name'];
        if (fullName != null && fullName is String && fullName.isNotEmpty) {
          return fullName;
        }
      }
      final email = user?.email;
      if (email != null && email.isNotEmpty) {
        return email.split('@')[0];
      }
      return 'User';
    } catch (e) {
      return 'User';
    }
  }

  String _safeGetUserEmail() {
    try {
      return _authService.currentUser?.email ?? '';
    } catch (e) {
      return '';
    }
  }

  String? _safeGetAvatarUrl() {
    try {
      final user = _authService.currentUser;
      if (user?.userMetadata != null) {
        final avatarUrl = user!.userMetadata!['avatar_url'];
        if (avatarUrl != null && avatarUrl is String && avatarUrl.isNotEmpty) {
          return avatarUrl;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  DateTime _safeGetMemberSince() {
    try {
      final user = _authService.currentUser;
      if (user?.createdAt != null) {
        return DateTime.parse(user!.createdAt);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if there's an error
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('Settings'),
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Settings Error',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadSubscriptionStatus();
                  },
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  ProfileSectionWidget(
                    name: _safeGetUserName(),
                    email: _safeGetUserEmail(),
                    avatar: _safeGetAvatarUrl(),
                    memberSince: _safeGetMemberSince(),
                    onEditProfile: _handleEditProfile,
                  ),

                  SizedBox(height: 24),

                  // Subscription Status
                  SubscriptionStatusWidget(
                    subscriptionType:
                        _subscriptionStatus['type']?.toString() ?? 'free',
                    trialDaysRemaining:
                        _subscriptionStatus['trialDaysRemaining'] as int?,
                    onManageSubscription: _handleManageSubscription,
                  ),

                  SizedBox(height: 24),

                  // Settings Sections
                  SettingsSectionWidget(
                    title: 'Journal',
                    items: [
                      {
                        'title': 'Sync Now',
                        'subtitle': 'Manually sync your journal entries',
                        'icon': Icons.sync,
                        'onTap': _handleSyncNow,
                      },
                      {
                        'title': 'Export Data',
                        'subtitle': 'Download your journal entries',
                        'icon': Icons.download,
                        'onTap': _handleExportData,
                      },
                      {
                        'title': 'Clear Local Data',
                        'subtitle': 'Remove all local journal entries',
                        'icon': Icons.delete_sweep,
                        'onTap': _handleClearData,
                        'isDestructive': true,
                      },
                    ],
                  ),

                  SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: 'Privacy & Security',
                    items: [
                      {
                        'title': 'Biometric Lock',
                        'subtitle': 'Secure your journal with biometrics',
                        'icon': Icons.fingerprint,
                        'onTap': _handleBiometricSettings,
                      },
                      {
                        'title': 'Privacy Policy',
                        'subtitle': 'Read our privacy policy',
                        'icon': Icons.privacy_tip,
                        'onTap': _handlePrivacyPolicy,
                      },
                      {
                        'title': 'Terms of Service',
                        'subtitle': 'View terms and conditions',
                        'icon': Icons.description,
                        'onTap': _handleTermsOfService,
                      },
                    ],
                  ),

                  SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: 'Notifications',
                    items: [
                      {
                        'title': 'Daily Reminders',
                        'subtitle': 'Get reminded to write in your journal',
                        'icon': Icons.notifications,
                        'onTap': _handleNotificationSettings,
                      },
                      {
                        'title': 'Insights Notifications',
                        'subtitle': 'Receive notifications for AI insights',
                        'icon': Icons.lightbulb,
                        'onTap': _handleInsightsNotifications,
                      },
                    ],
                  ),

                  SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: 'Support',
                    items: [
                      {
                        'title': 'Help Center',
                        'subtitle': 'Get help and find answers',
                        'icon': Icons.help,
                        'onTap': _handleHelpCenter,
                      },
                      {
                        'title': 'Contact Support',
                        'subtitle': 'Reach out to our support team',
                        'icon': Icons.support_agent,
                        'onTap': _handleContactSupport,
                      },
                      {
                        'title': 'Rate App',
                        'subtitle': 'Share your feedback',
                        'icon': Icons.star_rate,
                        'onTap': _handleRateApp,
                      },
                      {
                        'title': 'Send Feedback',
                        'subtitle': 'Help us improve the app',
                        'icon': Icons.feedback,
                        'onTap': _handleSendFeedback,
                      },
                    ],
                  ),

                  SizedBox(height: 24),

                  SettingsSectionWidget(
                    title: 'Account',
                    items: [
                      {
                        'title': 'Change Password',
                        'subtitle': 'Update your account password',
                        'icon': Icons.lock,
                        'onTap': _handleChangePassword,
                      },
                      {
                        'title': 'Delete Account',
                        'subtitle': 'Permanently delete your account',
                        'icon': Icons.delete_forever,
                        'onTap': _handleDeleteAccount,
                        'isDestructive': true,
                      },
                      {
                        'title': 'Logout',
                        'subtitle': 'Sign out of your account',
                        'icon': Icons.logout,
                        'onTap': _handleSignOut,
                        'isDestructive': true,
                      },
                    ],
                  ),

                  SizedBox(height: 24),

                  // App Version
                  AppVersionWidget(),

                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  void _handleEditProfile() {
    // TODO: Implement profile editing
    _showComingSoonDialog('Profile Editing');
  }

  void _handleManageSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    ).then((_) => _loadSubscriptionStatus());
  }

  Future<void> _handleSyncNow() async {
    try {
      await _journalService.forceSyncNow();
      _showSuccessSnackBar('Sync completed successfully');
    } catch (e) {
      _showErrorSnackBar('Sync failed: ${e.toString()}');
    }
  }

  void _handleExportData() {
    // TODO: Implement data export
    _showComingSoonDialog('Data Export');
  }

  Future<void> _handleClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Local Data'),
        content: Text(
          'This will remove all journal entries from this device. Your data will still be available in the cloud and other devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _journalService.clearAllData();
        _showSuccessSnackBar('Local data cleared successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to clear data: ${e.toString()}');
      }
    }
  }

  void _handleBiometricSettings() {
    // TODO: Implement biometric settings
    _showComingSoonDialog('Biometric Settings');
  }

  void _handlePrivacyPolicy() {
    // TODO: Open privacy policy URL
    _showComingSoonDialog('Privacy Policy');
  }

  void _handleTermsOfService() {
    // TODO: Open terms of service URL
    _showComingSoonDialog('Terms of Service');
  }

  void _handleNotificationSettings() {
    // TODO: Implement notification settings
    _showComingSoonDialog('Notification Settings');
  }

  void _handleInsightsNotifications() {
    // TODO: Implement insights notification settings
    _showComingSoonDialog('Insights Notifications');
  }

  void _handleHelpCenter() {
    // TODO: Open help center
    _showComingSoonDialog('Help Center');
  }

  void _handleContactSupport() {
    // TODO: Open contact support
    _showComingSoonDialog('Contact Support');
  }

  void _handleRateApp() {
    // TODO: Open app store rating
    _showComingSoonDialog('Rate App');
  }

  void _handleSendFeedback() {
    // TODO: Implement feedback form
    _showComingSoonDialog('Send Feedback');
  }

  void _handleChangePassword() {
    // TODO: Implement password change
    _showComingSoonDialog('Change Password');
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement account deletion
      _showComingSoonDialog('Account Deletion');
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        await _journalService.clearAllData();
        if (mounted) {
          _showSuccessSnackBar('Successfully logged out');
        }
        // Navigation will be handled by auth state listener in main navigation
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to logout: ${e.toString()}');
        }
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
