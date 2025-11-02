import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../models/journal_entry_model.dart';
import '../../services/auth_service.dart';
import '../../services/journal_sync_service.dart';
import '../../theme/app_theme.dart';
import './widgets/export_insights_widget.dart';
import './widgets/insights_summary_card_widget.dart';
import './widgets/insights_timeline_widget.dart';
import './widgets/mood_trend_chart_widget.dart';
import './widgets/recommendation_card_widget.dart';

class AIInsightsDashboard extends StatefulWidget {
  const AIInsightsDashboard({Key? key}) : super(key: key);

  @override
  State<AIInsightsDashboard> createState() => _AIInsightsDashboardState();
}

class _AIInsightsDashboardState extends State<AIInsightsDashboard> {
  final AuthService _authService = AuthService.instance;
  final JournalSyncService _journalService = JournalSyncService.instance;

  List<JournalEntryModel> _entries = [];
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load journal entries
      final entries = await _journalService.getJournalEntries();

      // Generate insights from entries
      final insights = _generateInsights(entries);

      setState(() {
        _entries = entries;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load insights: ${e.toString()}');
    }
  }

  Map<String, dynamic> _generateInsights(List<JournalEntryModel> entries) {
    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'avgMood': 'neutral',
        'streak': 0,
        'topMood': 'neutral',
        'weeklyPattern': [],
        'recommendations': [],
      };
    }

    // Calculate mood distribution
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      final mood = entry.mood ?? 'neutral';
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    // Find most common mood
    String topMood = 'neutral';
    int maxCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        topMood = mood;
      }
    });

    // Calculate streak (entries in last 7 days)
    final now = DateTime.now();
    final streak = entries.where((entry) {
      final daysDiff = now.difference(entry.entryDate).inDays;
      return daysDiff <= 7;
    }).length;

    // Generate weekly pattern
    final weeklyPattern = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEntries = entries.where((entry) {
        return entry.entryDate.day == date.day &&
            entry.entryDate.month == date.month &&
            entry.entryDate.year == date.year;
      }).toList();

      weeklyPattern.add({
        'date': date,
        'count': dayEntries.length,
        'mood': dayEntries.isNotEmpty ? dayEntries.first.mood : 'neutral',
      });
    }

    // Generate recommendations
    final recommendations = _generateRecommendations(entries, topMood);

    return {
      'totalEntries': entries.length,
      'avgMood': topMood,
      'streak': streak,
      'topMood': topMood,
      'weeklyPattern': weeklyPattern,
      'recommendations': recommendations,
      'moodCounts': moodCounts,
    };
  }

  List<Map<String, dynamic>> _generateRecommendations(
      List<JournalEntryModel> entries, String topMood) {
    final recommendations = <Map<String, dynamic>>[];

    // Based on mood patterns
    if (topMood == 'happy' || topMood == 'excited') {
      recommendations.add({
        'title': 'Maintain Your Positive Energy',
        'description':
            'Your mood has been great! Consider sharing your positivity with others.',
        'type': 'positive',
        'icon': Icons.sentiment_very_satisfied,
      });
    } else if (topMood == 'sad' || topMood == 'angry') {
      recommendations.add({
        'title': 'Self-Care Reminder',
        'description': 'Take time for activities that bring you joy and peace.',
        'type': 'self-care',
        'icon': Icons.self_improvement,
      });
    }

    // Based on entry frequency
    if (entries.length < 3) {
      recommendations.add({
        'title': 'Build a Writing Habit',
        'description':
            'Try writing a little bit each day to track your emotional journey.',
        'type': 'habit',
        'icon': Icons.edit_note,
      });
    } else {
      recommendations.add({
        'title': 'Great Progress!',
        'description':
            'You\'re building a wonderful journaling habit. Keep it up!',
        'type': 'encouragement',
        'icon': Icons.trending_up,
      });
    }

    // Content-based recommendations
    final recentEntries = entries.take(5).toList();
    bool hasGoals = recentEntries.any((entry) =>
        entry.content.toLowerCase().contains('goal') ||
        entry.content.toLowerCase().contains('want to') ||
        entry.content.toLowerCase().contains('plan to'));

    if (hasGoals) {
      recommendations.add({
        'title': 'Goal Setting',
        'description':
            'You mentioned goals in recent entries. Consider breaking them into smaller steps.',
        'type': 'growth',
        'icon': Icons.flag,
      });
    }

    return recommendations.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Insights'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Insights',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your journal entries...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _entries.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Cards
                          InsightsSummaryCardWidget(
                            title: 'Total Entries',
                            value: '${_insights['totalEntries'] ?? 0}',
                            icon: 'edit_note',
                            color: AppTheme.primaryLight,
                          ),

                          SizedBox(height: 24),

                          // Mood Trend Chart
                          MoodTrendChartWidget(
                            moodData: (_insights['weeklyPattern']
                                        as List<dynamic>?)
                                    ?.asMap()
                                    .entries
                                    .map((entry) => FlSpot(
                                        entry.key.toDouble(),
                                        _moodToValue(
                                            entry.value['mood'] ?? 'neutral')))
                                    .toList() ??
                                <FlSpot>[],
                            timeframe: 'This Week',
                          ),

                          SizedBox(height: 24),

                          // Recommendations
                          Text(
                            'Recommendations',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),

                          ...(_insights['recommendations']
                                  as List<Map<String, dynamic>>)
                              .map((recommendation) => Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: RecommendationCardWidget(
                                      recommendation: recommendation,
                                    ),
                                  )),

                          SizedBox(height: 24),

                          // Insights Timeline
                          InsightsTimelineWidget(
                            insight: {
                              'date': DateTime.now(),
                              'event': 'Journal Insights',
                              'description':
                                  'You have ${_entries.length} entries',
                              'type': 'insight',
                            },
                          ),

                          SizedBox(height: 24),

                          // Export Options
                          ExportInsightsWidget(
                            onExportPDF: () {},
                            onExportCSV: () {},
                            onShareInsights: () {},
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: AppTheme.textDisabledLight,
            ),
            SizedBox(height: 24),
            Text(
              'No Insights Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
            ),
            SizedBox(height: 16),
            Text(
              'Start writing journal entries to see personalized insights about your emotional journey.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // User can use the Write tab
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Use the Write tab to create your first entry'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.edit),
              label: Text('Start Writing'),
            ),
          ],
        ),
      ),
    );
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

  double _moodToValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return 5.0;
      case 'good':
        return 4.0;
      case 'neutral':
      case 'ok':
        return 3.0;
      case 'sad':
        return 2.0;
      case 'angry':
        return 1.0;
      default:
        return 3.0;
    }
  }
}
