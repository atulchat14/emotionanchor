import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MoodSelectorWidget extends StatefulWidget {
  final String selectedMood;
  final Function(String) onMoodChanged;

  const MoodSelectorWidget({
    Key? key,
    required this.selectedMood,
    required this.onMoodChanged,
  }) : super(key: key);

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _moods = [
    {
      'id': 'happy',
      'label': 'Happy',
      'emoji': '😊',
      'color': const Color(0xFFFFD700),
    },
    {
      'id': 'calm',
      'label': 'Calm',
      'emoji': '😌',
      'color': const Color(0xFF98D8C8),
    },
    {
      'id': 'excited',
      'label': 'Excited',
      'emoji': '🤩',
      'color': const Color(0xFFFF9500),
    },
    {
      'id': 'grateful',
      'label': 'Grateful',
      'emoji': '🙏',
      'color': const Color(0xFF2ECC71),
    },
    {
      'id': 'peaceful',
      'label': 'Peaceful',
      'emoji': '😇',
      'color': const Color(0xFF85C1E9),
    },
    {
      'id': 'neutral',
      'label': 'Neutral',
      'emoji': '😐',
      'color': const Color(0xFF95A5A6),
    },
    {
      'id': 'anxious',
      'label': 'Anxious',
      'emoji': '😰',
      'color': const Color(0xFFFF6B6B),
    },
    {
      'id': 'sad',
      'label': 'Sad',
      'emoji': '😢',
      'color': const Color(0xFF4A90E2),
    },
    {
      'id': 'angry',
      'label': 'Angry',
      'emoji': '😠',
      'color': const Color(0xFFE74C3C),
    },
    {
      'id': 'frustrated',
      'label': 'Frustrated',
      'emoji': '😤',
      'color': const Color(0xFFE67E22),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'sentiment_satisfied',
                size: 5.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'How are you feeling?',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Mood Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.8,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.h,
            ),
            itemCount: _moods.length,
            itemBuilder: (context, index) {
              final mood = _moods[index];
              final isSelected = mood['id'] == widget.selectedMood;

              return _buildMoodItem(mood, isSelected);
            },
          ),

          SizedBox(height: 2.h),

          // Selected Mood Display
          if (widget.selectedMood.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Selected: ',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _getMoodEmoji(widget.selectedMood),
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _getMoodLabel(widget.selectedMood),
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getMoodColor(widget.selectedMood),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodItem(Map<String, dynamic> mood, bool isSelected) {
    return GestureDetector(
      onTap: () => _onMoodSelected(mood['id'] as String),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? (mood['color'] as Color).withValues(alpha: 0.2)
                    : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? mood['color'] as Color
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    mood['emoji'] as String,
                    style: TextStyle(
                      fontSize: isSelected ? 24.sp : 20.sp,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Label
                  Text(
                    mood['label'] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? mood['color'] as Color
                          : AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onMoodSelected(String moodId) {
    HapticFeedback.lightImpact();

    if (moodId == widget.selectedMood) {
      // Deselect if same mood is tapped
      widget.onMoodChanged('neutral');
    } else {
      widget.onMoodChanged(moodId);
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  String _getMoodEmoji(String moodId) {
    final mood = _moods.firstWhere(
      (m) => m['id'] == moodId,
      orElse: () => _moods.firstWhere((m) => m['id'] == 'neutral'),
    );
    return mood['emoji'] as String;
  }

  String _getMoodLabel(String moodId) {
    final mood = _moods.firstWhere(
      (m) => m['id'] == moodId,
      orElse: () => _moods.firstWhere((m) => m['id'] == 'neutral'),
    );
    return mood['label'] as String;
  }

  Color _getMoodColor(String moodId) {
    final mood = _moods.firstWhere(
      (m) => m['id'] == moodId,
      orElse: () => _moods.firstWhere((m) => m['id'] == 'neutral'),
    );
    return mood['color'] as Color;
  }
}
