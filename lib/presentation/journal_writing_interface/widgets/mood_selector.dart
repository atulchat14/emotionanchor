import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MoodSelector extends StatefulWidget {
  final String? selectedMood;
  final Function(String) onMoodSelected;

  const MoodSelector({
    Key? key,
    this.selectedMood,
    required this.onMoodSelected,
  }) : super(key: key);

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final List<Map<String, dynamic>> moods = [
    {
      "emoji": "😊",
      "label": "Happy",
      "value": "happy",
      "color": Color(0xFFFFD700),
    },
    {
      "emoji": "😌",
      "label": "Calm",
      "value": "calm",
      "color": Color(0xFF98D8C8),
    },
    {
      "emoji": "🤩",
      "label": "Excited",
      "value": "excited",
      "color": Color(0xFFFF9500),
    },
    {
      "emoji": "🙏",
      "label": "Grateful",
      "value": "grateful",
      "color": Color(0xFF2ECC71),
    },
    {
      "emoji": "😇",
      "label": "Peaceful",
      "value": "peaceful",
      "color": Color(0xFF85C1E9),
    },
    {
      "emoji": "😐",
      "label": "Neutral",
      "value": "neutral",
      "color": Color(0xFF95A5A6),
    },
    {
      "emoji": "😰",
      "label": "Anxious",
      "value": "anxious",
      "color": Color(0xFFFF6B6B),
    },
    {
      "emoji": "😢",
      "label": "Sad",
      "value": "sad",
      "color": Color(0xFF4A90E2),
    },
    {
      "emoji": "😠",
      "label": "Angry",
      "value": "angry",
      "color": Color(0xFFE74C3C),
    },
    {
      "emoji": "😤",
      "label": "Frustrated",
      "value": "frustrated",
      "color": Color(0xFFE67E22),
    },
  ];

  void _selectMood(String moodValue) {
    HapticFeedback.lightImpact();
    widget.onMoodSelected(moodValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.8,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 1.5.h,
            ),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = widget.selectedMood == mood["value"];

              return GestureDetector(
                onTap: () => _selectMood(mood["value"]),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? mood["color"].withValues(alpha: 0.15)
                        : AppTheme.lightTheme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? mood["color"]
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood["emoji"],
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        mood["label"],
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? mood["color"]
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 8.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
