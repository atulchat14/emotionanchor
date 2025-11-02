import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AIInsightsPanelWidget extends StatefulWidget {
  final Map<String, dynamic> entryData;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AIInsightsPanelWidget({
    Key? key,
    required this.entryData,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<AIInsightsPanelWidget> createState() => _AIInsightsPanelWidgetState();
}

class _AIInsightsPanelWidgetState extends State<AIInsightsPanelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _heightAnimation;

  // Mock AI insights data
  final Map<String, dynamic> _aiInsights = {
    'emotionalAnalysis': {
      'primaryEmotion': 'Optimism',
      'secondaryEmotion': 'Gratitude',
      'intensity': 'High',
      'confidence': 0.87,
    },
    'themes': [
      {
        'theme': 'Personal Growth',
        'relevance': 0.92,
        'keywords': ['progress', 'improvement', 'learning'],
      },
      {
        'theme': 'Work-Life Balance',
        'relevance': 0.78,
        'keywords': ['productivity', 'energy', 'focus'],
      },
      {
        'theme': 'Physical Wellness',
        'relevance': 0.65,
        'keywords': ['workout', 'exercise', 'health'],
      },
    ],
    'recommendations': [
      {
        'type': 'Reflection',
        'title': 'Continue Your Momentum',
        'description':
            'Your entry shows strong positive momentum. Consider setting specific goals to maintain this energy.',
        'priority': 'high',
      },
      {
        'type': 'Activity',
        'title': 'Morning Routine',
        'description':
            'Your morning workout seems to be a key driver of your positive mood. Consider making it a consistent habit.',
        'priority': 'medium',
      },
      {
        'type': 'Mindfulness',
        'title': 'Celebrate Small Wins',
        'description':
            'Take time to acknowledge and celebrate the progress you mentioned in your entry.',
        'priority': 'low',
      },
    ],
    'sentimentScore': 0.82,
    'moodTrend': 'Improving',
    'privacyMode': false,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AIInsightsPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'auto_awesome',
                        size: 5.w,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Insights',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            widget.isExpanded
                                ? 'Tap to collapse'
                                : 'Tap to view analysis',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence Score
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 1.5.w,
                            height: 1.5.w,
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${(_aiInsights['emotionalAnalysis']['confidence'] * 100).round()}%',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getConfidenceColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 3.14159,
                          child: CustomIconWidget(
                            iconName: 'expand_more',
                            size: 5.w,
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded Content
          AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                ),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Emotional Analysis
                      _buildEmotionalAnalysis(),
                      SizedBox(height: 3.h),

                      // Detected Themes
                      _buildDetectedThemes(),
                      SizedBox(height: 3.h),

                      // Recommendations
                      _buildRecommendations(),
                      SizedBox(height: 2.h),

                      // Privacy Toggle
                      _buildPrivacyToggle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalAnalysis() {
    final analysis = _aiInsights['emotionalAnalysis'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotional Analysis',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),

        Row(
          children: [
            Expanded(
              child: _buildAnalysisCard(
                'Primary Emotion',
                analysis['primaryEmotion'] as String,
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildAnalysisCard(
                'Secondary',
                analysis['secondaryEmotion'] as String,
                AppTheme.lightTheme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Sentiment Score Bar
        Row(
          children: [
            Text(
              'Overall Sentiment:',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Container(
                height: 1.h,
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _aiInsights['sentimentScore'] as double,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSentimentColor(
                          _aiInsights['sentimentScore'] as double),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '${(_aiInsights['sentimentScore'] * 100).round()}%',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedThemes() {
    final themes = _aiInsights['themes'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Themes',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        ...themes
            .map((theme) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildThemeCard(theme),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme) {
    final relevance = theme['relevance'] as double;
    final keywords = theme['keywords'] as List<String>;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                theme['theme'] as String,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(relevance * 100).round()}%',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _getRelevanceColor(relevance),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 1.h,
            children: keywords
                .map((keyword) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        keyword,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations =
        _aiInsights['recommendations'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Recommendations',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        ...recommendations
            .map((recommendation) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildRecommendationCard(recommendation),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(priority).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomIconWidget(
                  iconName: _getPriorityIcon(priority),
                  size: 3.5.w,
                  color: _getPriorityColor(priority),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  recommendation['title'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(priority),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            recommendation['description'] as String,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'privacy_tip',
            size: 4.w,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Mode',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Disable AI analysis for this entry',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _aiInsights['privacyMode'] as bool,
            onChanged: (value) {
              setState(() {
                _aiInsights['privacyMode'] = value;
              });
            },
            activeColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    final confidence = _aiInsights['emotionalAnalysis']['confidence'] as double;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getSentimentColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.8) return AppTheme.lightTheme.colorScheme.primary;
    if (relevance >= 0.6) return Colors.orange;
    return AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return 'priority_high';
      case 'medium':
        return 'remove';
      case 'low':
      default:
        return 'keyboard_arrow_down';
    }
  }
}
