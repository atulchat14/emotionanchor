import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MoodTrendChartWidget extends StatelessWidget {
  final List<FlSpot> moodData;
  final String timeframe;
  final Function(FlSpot)? onDataPointTap;

  const MoodTrendChartWidget({
    Key? key,
    required this.moodData,
    required this.timeframe,
    this.onDataPointTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emotional Patterns',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeframe,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getAverageMoodColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: _getAverageMoodIcon(),
                      color: _getAverageMoodColor(),
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _getAverageMoodScore(),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: _getAverageMoodColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getMoodLabel(value),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 8.sp,
                          ),
                        );
                      },
                      reservedSize: 8.w,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getTimeLabel(value.toInt()),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 8.sp,
                          ),
                        );
                      },
                      reservedSize: 4.h,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: moodData.length.toDouble() - 1,
                minY: 1,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: moodData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.8),
                        AppTheme.lightTheme.colorScheme.secondary
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getMoodColor(spot.y),
                          strokeWidth: 2,
                          strokeColor: AppTheme.lightTheme.colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.2),
                          AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, touchResponse) {
                    if (event is FlTapUpEvent &&
                        touchResponse?.lineBarSpots?.isNotEmpty == true &&
                        onDataPointTap != null) {
                      final spot = touchResponse!.lineBarSpots!.first;
                      onDataPointTap!(FlSpot(spot.x, spot.y));
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor:
                        AppTheme.lightTheme.colorScheme.surface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${_getMoodEmoji(spot.y)} ${spot.y.toStringAsFixed(1)}',
                          AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildMoodLegend(),
        ],
      ),
    );
  }

  Widget _buildMoodLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('😔', 'Low', Colors.red.shade300),
        _buildLegendItem('😐', 'Fair', Colors.orange.shade300),
        _buildLegendItem('🙂', 'Good', Colors.yellow.shade600),
        _buildLegendItem('😊', 'Great', Colors.lightGreen.shade400),
        _buildLegendItem('😄', 'Excellent', Colors.green.shade500),
      ],
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 12.sp)),
        SizedBox(width: 1.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
            fontSize: 8.sp,
          ),
        ),
      ],
    );
  }

  String _getMoodLabel(double value) {
    switch (value.toInt()) {
      case 1:
        return 'Low';
      case 2:
        return 'Fair';
      case 3:
        return 'OK';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '';
    }
  }

  String _getTimeLabel(int index) {
    switch (timeframe) {
      case 'This Week':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return index < days.length ? days[index] : '';
      case 'This Month':
        return 'W${index + 1}';
      case 'Last 3 Months':
        const months = ['3mo', '2mo', '1mo', 'Now'];
        return index < months.length ? months[index] : '';
      default:
        return '$index';
    }
  }

  Color _getMoodColor(double mood) {
    if (mood >= 4.5) return Colors.green.shade500;
    if (mood >= 4.0) return Colors.lightGreen.shade400;
    if (mood >= 3.0) return Colors.yellow.shade600;
    if (mood >= 2.0) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  String _getMoodEmoji(double mood) {
    if (mood >= 4.5) return '😄';
    if (mood >= 4.0) return '😊';
    if (mood >= 3.0) return '🙂';
    if (mood >= 2.0) return '😐';
    return '😔';
  }

  Color _getAverageMoodColor() {
    if (moodData.isEmpty) return AppTheme.lightTheme.colorScheme.primary;
    final average =
        moodData.map((e) => e.y).reduce((a, b) => a + b) / moodData.length;
    return _getMoodColor(average);
  }

  String _getAverageMoodIcon() {
    if (moodData.isEmpty) return 'sentiment_neutral';
    final average =
        moodData.map((e) => e.y).reduce((a, b) => a + b) / moodData.length;
    if (average >= 4.5) return 'sentiment_very_satisfied';
    if (average >= 4.0) return 'sentiment_satisfied';
    if (average >= 3.0) return 'sentiment_neutral';
    if (average >= 2.0) return 'sentiment_dissatisfied';
    return 'sentiment_very_dissatisfied';
  }

  String _getAverageMoodScore() {
    if (moodData.isEmpty) return '0.0';
    final average =
        moodData.map((e) => e.y).reduce((a, b) => a + b) / moodData.length;
    return average.toStringAsFixed(1);
  }
}