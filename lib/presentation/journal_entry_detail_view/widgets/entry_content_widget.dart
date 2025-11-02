import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EntryContentWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final Function(String) onChanged;
  final String entryTitle;

  const EntryContentWidget({
    Key? key,
    required this.controller,
    required this.isEditing,
    required this.onChanged,
    required this.entryTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entry Title
          if (entryTitle.isNotEmpty) ...[
            Text(
              entryTitle,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              height: 1,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
            SizedBox(height: 2.h),
          ],

          // Entry Content
          if (isEditing)
            _buildEditableContent(context)
          else
            _buildReadOnlyContent(context),
        ],
      ),
    );
  }

  Widget _buildEditableContent(BuildContext context) {
    return Column(
      children: [
        // Formatting Toolbar
        Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFormatButton(
                context,
                icon: 'format_bold',
                onTap: () => _insertFormat('**', '**'),
              ),
              SizedBox(width: 2.w),
              _buildFormatButton(
                context,
                icon: 'format_italic',
                onTap: () => _insertFormat('*', '*'),
              ),
              SizedBox(width: 2.w),
              _buildFormatButton(
                context,
                icon: 'format_list_bulleted',
                onTap: () => _insertFormat('• ', ''),
              ),
              const Spacer(),
              Text(
                '${controller.text.split(' ').length} words',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Text Field
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: null,
          minLines: 10,
          autofocus: true,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            fontSize: 16.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Share your thoughts...',
            hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
              height: 1.6,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reading Stats
        Row(
          children: [
            CustomIconWidget(
              iconName: 'schedule',
              size: 4.w,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
            SizedBox(width: 2.w),
            Text(
              '${_getReadingTime(controller.text)} min read',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            SizedBox(width: 4.w),
            CustomIconWidget(
              iconName: 'text_fields',
              size: 4.w,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
            SizedBox(width: 2.w),
            Text(
              '${controller.text.split(' ').length} words',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        // Content Text
        SelectableText(
          controller.text.isNotEmpty
              ? controller.text
              : 'No content available for this entry.',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            fontSize: 16.sp,
            color: controller.text.isEmpty
                ? AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.5)
                : AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(
    BuildContext context, {
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: CustomIconWidget(
          iconName: icon,
          size: 4.w,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _insertFormat(String before, String after) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$before$selectedText$after',
      );

      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start +
            before.length +
            selectedText.length +
            after.length,
      );
    } else {
      final newText = text + before + after;
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: newText.length - after.length,
      );
    }
  }

  int _getReadingTime(String text) {
    // Average reading speed: 200 words per minute
    final wordCount = text.split(' ').length;
    return (wordCount / 200).ceil();
  }
}
