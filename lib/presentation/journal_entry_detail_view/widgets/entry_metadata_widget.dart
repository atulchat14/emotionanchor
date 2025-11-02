import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EntryMetadataWidget extends StatelessWidget {
  final Map<String, dynamic> entryData;
  final String currentMood;

  const EntryMetadataWidget({
    Key? key,
    required this.entryData,
    required this.currentMood,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Entry Details',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Metadata Items
          _buildMetadataItem(
            context,
            icon: 'calendar_today',
            label: 'Created',
            value: _formatDateTime(entryData['date']),
          ),

          if (entryData['lastModified'] != null) ...[
            SizedBox(height: 2.h),
            _buildMetadataItem(
              context,
              icon: 'edit',
              label: 'Last Modified',
              value: _formatDateTime(entryData['lastModified']),
            ),
          ],

          SizedBox(height: 2.h),
          _buildMetadataItem(
            context,
            icon: 'sentiment_satisfied',
            label: 'Mood',
            value: _getMoodDisplayName(currentMood),
            valueColor: _getMoodColor(currentMood),
            showMoodDot: true,
          ),

          SizedBox(height: 2.h),
          _buildMetadataItem(
            context,
            icon: 'text_fields',
            label: 'Word Count',
            value: '${_getWordCount()} words',
          ),

          if (entryData['writingDuration'] != null) ...[
            SizedBox(height: 2.h),
            _buildMetadataItem(
              context,
              icon: 'timer',
              label: 'Writing Time',
              value: '${entryData['writingDuration']} minutes',
            ),
          ],

          if (entryData['location'] != null) ...[
            SizedBox(height: 2.h),
            _buildMetadataItem(
              context,
              icon: 'location_on',
              label: 'Location',
              value: entryData['location'] as String,
            ),
          ],

          // AI Insight Status
          SizedBox(height: 2.h),
          _buildMetadataItem(
            context,
            icon: 'auto_awesome',
            label: 'AI Insights',
            value: (entryData['hasAiInsight'] == true)
                ? 'Available'
                : 'Not analyzed',
            valueColor: (entryData['hasAiInsight'] == true)
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showMoodDot = false,
  }) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          size: 4.5.w,
          color:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  if (showMoodDot) ...[
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: valueColor ??
                            AppTheme.lightTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],
                  Text(
                    value,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: valueColor ??
                          AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Unknown';

    final DateTime date =
        dateTime is DateTime ? dateTime : DateTime.parse(dateTime.toString());
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getMoodDisplayName(String mood) {
    switch (mood) {
      case 'happy':
        return 'Happy';
      case 'sad':
        return 'Sad';
      case 'anxious':
        return 'Anxious';
      case 'calm':
        return 'Calm';
      case 'excited':
        return 'Excited';
      case 'angry':
        return 'Angry';
      case 'peaceful':
        return 'Peaceful';
      case 'frustrated':
        return 'Frustrated';
      case 'grateful':
        return 'Grateful';
      case 'neutral':
      default:
        return 'Neutral';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return const Color(0xFFFFD700); // Gold
      case 'sad':
        return const Color(0xFF4A90E2); // Blue
      case 'anxious':
        return const Color(0xFFFF6B6B); // Red
      case 'calm':
        return const Color(0xFF98D8C8); // Light Green
      case 'excited':
        return const Color(0xFFFF9500); // Orange
      case 'angry':
        return const Color(0xFFE74C3C); // Dark Red
      case 'peaceful':
        return const Color(0xFF85C1E9); // Light Blue
      case 'frustrated':
        return const Color(0xFFE67E22); // Dark Orange
      case 'grateful':
        return const Color(0xFF2ECC71); // Green
      case 'neutral':
      default:
        return const Color(0xFF95A5A6); // Gray
    }
  }

  int _getWordCount() {
    final content = entryData['content'] ?? entryData['preview'] ?? '';
    if (content.isEmpty) return 0;
    return content.split(' ').where((word) => word.isNotEmpty).length;
  }
}
