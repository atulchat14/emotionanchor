import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WritingToolbar extends StatefulWidget {
  final Function(String) onFormatAction;
  final Function(String) onMoodTag;

  const WritingToolbar({
    Key? key,
    required this.onFormatAction,
    required this.onMoodTag,
  }) : super(key: key);

  @override
  State<WritingToolbar> createState() => _WritingToolbarState();
}

class _WritingToolbarState extends State<WritingToolbar> {
  bool _isBoldActive = false;
  bool _isItalicActive = false;
  bool _isBulletActive = false;

  final List<Map<String, dynamic>> moodTags = [
    {"emoji": "💪", "tag": "#motivated", "color": Color(0xFF4CAF50)},
    {"emoji": "😰", "tag": "#stressed", "color": Color(0xFFFF9800)},
    {"emoji": "🎯", "tag": "#focused", "color": Color(0xFF2196F3)},
    {"emoji": "😴", "tag": "#tired", "color": Color(0xFF9C27B0)},
    {"emoji": "🙏", "tag": "#grateful", "color": Color(0xFF009688)},
    {"emoji": "😤", "tag": "#frustrated", "color": Color(0xFFF44336)},
  ];

  void _handleFormatAction(String action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'bold':
        setState(() => _isBoldActive = !_isBoldActive);
        break;
      case 'italic':
        setState(() => _isItalicActive = !_isItalicActive);
        break;
      case 'bullet':
        setState(() => _isBulletActive = !_isBulletActive);
        break;
    }

    widget.onFormatAction(action);
  }

  void _handleMoodTag(String tag) {
    HapticFeedback.lightImpact();
    widget.onMoodTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Formatting tools
          Row(
            children: [
              Text(
                'Format:',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 3.w),
              _buildFormatButton(
                icon: 'format_bold',
                action: 'bold',
                isActive: _isBoldActive,
              ),
              SizedBox(width: 2.w),
              _buildFormatButton(
                icon: 'format_italic',
                action: 'italic',
                isActive: _isItalicActive,
              ),
              SizedBox(width: 2.w),
              _buildFormatButton(
                icon: 'format_list_bulleted',
                action: 'bullet',
                isActive: _isBulletActive,
              ),
              Spacer(),
              Text(
                'Quick Tags:',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          // Mood tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: moodTags.map((moodTag) {
                return GestureDetector(
                  onTap: () => _handleMoodTag(moodTag["tag"]),
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: moodTag["color"].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: moodTag["color"].withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          moodTag["emoji"],
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          moodTag["tag"],
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: moodTag["color"],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required String icon,
    required String action,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _handleFormatAction(action),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: isActive
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurface,
          size: 18,
        ),
      ),
    );
  }
}
