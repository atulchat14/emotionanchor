import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MoodSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyMoodData;
  final VoidCallback? onViewDetails;

  const MoodSummaryWidget({
    Key? key,
    required this.weeklyMoodData,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'mood',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Weekly Mood Pattern',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewDetails,
                    child: Text(
                      'View Details',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Container(
                height: 20.h,
                child: Semantics(
                  label:
                      "Weekly mood pattern line chart showing emotional trends over the past 7 days",
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateMoodSpots(),
                          isCurved: true,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.lightTheme.colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor:
                                    AppTheme.lightTheme.colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 6,
                      minY: 1,
                      maxY: 5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMoodIndicator(
                      'Most Common',
                      _getMostCommonMood(),
                      _getMoodColor(_getMostCommonMood()),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildMoodIndicator(
                      'Today',
                      _getTodayMood(),
                      _getMoodColor(_getTodayMood()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateMoodSpots() {
    if (weeklyMoodData.isEmpty) {
      return [
        const FlSpot(0, 3),
        const FlSpot(1, 3.5),
        const FlSpot(2, 3.2),
        const FlSpot(3, 4.1),
        const FlSpot(4, 3.8),
        const FlSpot(5, 4.2),
        const FlSpot(6, 3.9),
      ];
    }

    return weeklyMoodData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final moodValue = _moodToValue((data['mood'] as String?) ?? 'neutral');
      return FlSpot(index.toDouble(), moodValue);
    }).toList();
  }

  double _moodToValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'very_happy':
      case 'joyful':
      case 'excited':
        return 5.0;
      case 'happy':
      case 'content':
        return 4.0;
      case 'neutral':
      case 'okay':
        return 3.0;
      case 'sad':
      case 'down':
        return 2.0;
      case 'very_sad':
      case 'depressed':
        return 1.0;
      default:
        return 3.0;
    }
  }

  String _getMostCommonMood() {
    if (weeklyMoodData.isEmpty) return 'Neutral';

    final moodCounts = <String, int>{};
    for (final data in weeklyMoodData) {
      final mood = (data['mood'] as String?) ?? 'neutral';
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    String mostCommon = 'neutral';
    int maxCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = mood;
      }
    });

    return _formatMoodName(mostCommon);
  }

  String _getTodayMood() {
    if (weeklyMoodData.isEmpty) return 'Neutral';

    final today = DateTime.now();
    for (final data in weeklyMoodData) {
      final date = data['date'] as DateTime?;
      if (date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return _formatMoodName((data['mood'] as String?) ?? 'neutral');
      }
    }

    return 'No Entry';
  }

  String _formatMoodName(String mood) {
    switch (mood.toLowerCase()) {
      case 'very_happy':
        return 'Very Happy';
      case 'happy':
        return 'Happy';
      case 'neutral':
        return 'Neutral';
      case 'sad':
        return 'Sad';
      case 'very_sad':
        return 'Very Sad';
      case 'anxious':
        return 'Anxious';
      case 'calm':
        return 'Calm';
      case 'excited':
        return 'Excited';
      case 'frustrated':
        return 'Frustrated';
      default:
        return 'Unknown';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'very happy':
      case 'happy':
      case 'excited':
        return Colors.green;
      case 'sad':
      case 'very sad':
        return Colors.blue;
      case 'anxious':
      case 'frustrated':
        return Colors.orange;
      case 'calm':
        return Colors.teal;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  Widget _buildMoodIndicator(String label, String mood, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Flexible(
                child: Text(
                  mood,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
