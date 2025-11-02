import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/journal_entry_model.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import '../../services/subscription_service.dart';
import '../subscription_screen/subscription_screen.dart';
import './widgets/empty_state_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/journal_entry_card.dart';
import './widgets/mood_summary_widget.dart';

class JournalDashboard extends StatefulWidget {
  const JournalDashboard({Key? key}) : super(key: key);

  @override
  State<JournalDashboard> createState() => _JournalDashboardState();
}

class _JournalDashboardState extends State<JournalDashboard> {
  final AuthService _authService = AuthService.instance;
  final JournalSyncService _journalService = JournalSyncService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  List<JournalEntryModel> _entries = [];
  bool _isLoading = true;
  String _syncMessage = '';
  bool _isSyncing = false;
  Map<String, dynamic> _subscriptionStatus = {};
  bool _showTrialBanner = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
  }

  void _initializeServices() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((AuthState data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.loginScreen,
          (route) => false,
        );
      }
    });

    // Listen to sync status
    _journalService.syncMessageStream.listen((message) {
      if (mounted) {
        setState(() => _syncMessage = message);
      }
    });

    _journalService.isSyncingStream.listen((syncing) {
      if (mounted) {
        setState(() => _isSyncing = syncing);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load journal entries
      final entries = await _journalService.getJournalEntries();

      // Load subscription status
      final subscriptionStatus =
          await _subscriptionService.getSubscriptionStatus();

      // Check if trial is expiring soon
      final isTrialExpiring = await _subscriptionService.isTrialExpiringSoon();

      setState(() {
        _entries = entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _subscriptionStatus = subscriptionStatus;
        _showTrialBanner = isTrialExpiring;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _journalService.forceSyncNow();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Timeline'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Subscription status indicator
          if (_subscriptionStatus['isTrial'] == true)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Trial: ${_subscriptionStatus['daysRemaining'] ?? 0}d',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Sync status indicator
          if (_isSyncing)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),

          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'subscription',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Subscription'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Sync Now'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Trial expiring banner
            if (_showTrialBanner)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        color: Colors.orange.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trial ending in ${_subscriptionStatus['daysRemaining'] ?? 0} days. Upgrade to keep premium features!',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      child: Text('Upgrade'),
                    ),
                  ],
                ),
              ),

            // Sync status message
            if (_syncMessage.isNotEmpty)
              Container(
                width: double.infinity,
                color: _syncMessage.contains('failed')
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _syncMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _syncMessage.contains('failed')
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading your journal...'),
                        ],
                      ),
                    )
                  : _entries.isEmpty
                      ? EmptyStateWidget(
                          userName:
                              _authService.currentUser?.email?.split('@')[0] ??
                                  'User',
                          onStartWriting: _navigateToWriting,
                        )
                      : Column(
                          children: [
                            // Greeting Header
                            GreetingHeaderWidget(
                              userName: _authService.currentUser?.email
                                      ?.split('@')[0] ??
                                  'User',
                              isPremium:
                                  _subscriptionStatus['isActive'] ?? false,
                            ),

                            // Mood Summary
                            if (_entries.isNotEmpty)
                              MoodSummaryWidget(
                                weeklyMoodData: _entries
                                    .map((entry) => {
                                          'mood': entry.mood ?? 'neutral',
                                          'date': entry.entryDate,
                                        })
                                    .toList(),
                              ),

                            // Journal Entries List
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _entries.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: JournalEntryCard(
                                      entry: _entries[index].toJson(),
                                      onTap: () =>
                                          _navigateToEntry(_entries[index]),
                                      onDelete: () =>
                                          _deleteEntry(_entries[index].id),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        ).then((_) => _loadData()); // Refresh data when returning
        break;
      case 'sync':
        _handleRefresh();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        await _journalService.clearAllData();
      } catch (e) {
        _showErrorSnackBar('Failed to sign out: ${e.toString()}');
      }
    }
  }

  void _navigateToWriting() {
    // Since we're in a tab navigation, we don't need to navigate
    // The user can use the Write tab
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Use the Write tab to create new entries'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEntry(JournalEntryModel entry) {
    Navigator.pushNamed(
      context,
      AppRoutes.journalEntryDetailView,
      arguments: entry.id,
    ).then((_) => _loadData());
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text(
            'Are you sure you want to delete this journal entry? This action cannot be undone.'),
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
      try {
        await _journalService.deleteJournalEntry(entryId);
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Failed to delete entry: ${e.toString()}');
      }
    }
  }
}
