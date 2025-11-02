import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AiAnalysisPanel extends StatefulWidget {
  final String journalText;
  final bool isVisible;
  final VoidCallback onToggle;

  const AiAnalysisPanel({
    Key? key,
    required this.journalText,
    required this.isVisible,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<AiAnalysisPanel> createState() => _AiAnalysisPanelState();
}

class _AiAnalysisPanelState extends State<AiAnalysisPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AiAnalysisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
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

  List<Map<String, dynamic>> _generateAiInsights() {
    if (widget.journalText.isEmpty) {
      return [
        {
          "type": "waiting",
          "title": "Start Writing",
          "description": "Begin writing to see AI emotional insights",
          "icon": "edit",
          "color": AppTheme.lightTheme.colorScheme.secondary,
        }
      ];
    }

    // Mock AI analysis based on text content
    List<Map<String, dynamic>> insights = [];
    String text = widget.journalText.toLowerCase();

    if (text.contains(RegExp(r'\b(stressed|anxious|worried|overwhelmed)\b'))) {
      insights.add({
        "type": "emotion",
        "title": "Stress Detected",
        "description": "Consider taking deep breaths or a short break",
        "icon": "psychology",
        "color": AppTheme.lightTheme.colorScheme.error,
      });
    }

    if (text.contains(RegExp(r'\b(happy|excited|grateful|joy)\b'))) {
      insights.add({
        "type": "emotion",
        "title": "Positive Emotions",
        "description": "Great to see you're feeling positive today",
        "icon": "sentiment_very_satisfied",
        "color": AppTheme.lightTheme.colorScheme.tertiary,
      });
    }

    if (text.contains(RegExp(r'\b(work|job|meeting|deadline)\b'))) {
      insights.add({
        "type": "theme",
        "title": "Work-Related Content",
        "description": "Reflecting on work experiences can help process stress",
        "icon": "work",
        "color": AppTheme.lightTheme.colorScheme.primary,
      });
    }

    if (insights.isEmpty) {
      insights.add({
        "type": "general",
        "title": "Keep Writing",
        "description": "Continue expressing your thoughts for deeper insights",
        "icon": "lightbulb",
        "color": AppTheme.lightTheme.colorScheme.secondary,
      });
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 30.h),
          child: Container(
            height: 30.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar and header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    children: [
                      Container(
                        width: 10.w,
                        height: 0.5.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4.w),
                            child: Text(
                              'AI Emotional Insights',
                              style: AppTheme.lightTheme.textTheme.titleMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onToggle,
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              margin: EdgeInsets.only(right: 4.w),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomIconWidget(
                                iconName: 'keyboard_arrow_down',
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Insights content
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _generateAiInsights().length,
                    itemBuilder: (context, index) {
                      final insight = _generateAiInsights()[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: insight["color"].withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: insight["color"].withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomIconWidget(
                                iconName: insight["icon"],
                                color: insight["color"],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insight["title"],
                                    style: AppTheme
                                        .lightTheme.textTheme.titleSmall
                                        ?.copyWith(
                                      color: insight["color"],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    insight["description"],
                                    style:
                                        AppTheme.lightTheme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
