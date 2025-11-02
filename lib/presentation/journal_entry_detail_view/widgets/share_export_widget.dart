import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ShareExportWidget extends StatelessWidget {
  final Map<String, dynamic> entryData;
  final bool isBottomSheet;

  const ShareExportWidget({
    Key? key,
    required this.entryData,
    this.isBottomSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isBottomSheet) {
      return _buildBottomSheetContent(context);
    }

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
          Text(
            'Share & Export',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.h),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 3.h),

          Text(
            'Share Entry',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),

          Text(
            'Choose how you\'d like to share this journal entry',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),

          _buildActionButtons(context),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: 'content_copy',
                label: 'Copy Text',
                color: AppTheme.lightTheme.colorScheme.primary,
                onTap: () => _copyToClipboard(context),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildActionButton(
                context,
                icon: 'share',
                label: 'Share',
                color: AppTheme.lightTheme.colorScheme.secondary,
                onTap: () => _shareEntry(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: 'picture_as_pdf',
                label: 'Export PDF',
                color: Colors.red,
                onTap: () => _exportAsPdf(context),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildActionButton(
                context,
                icon: 'text_snippet',
                label: 'Export Text',
                color: Colors.green,
                onTap: () => _exportAsText(context),
              ),
            ),
          ],
        ),
        if (!isBottomSheet) ...[
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            height: 1,
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          SizedBox(height: 3.h),
          _buildQuickActions(context),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 2.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  size: 6.w,
                  color: color,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildQuickActionItem(
          context,
          icon: 'bookmark',
          title: 'Save as Favorite',
          subtitle: 'Add to your favorite entries',
          onTap: () => _saveAsFavorite(context),
        ),
        SizedBox(height: 1.5.h),
        _buildQuickActionItem(
          context,
          icon: 'link',
          title: 'Generate Shareable Link',
          subtitle: 'Create a secure link to this entry',
          onTap: () => _generateShareableLink(context),
        ),
        SizedBox(height: 1.5.h),
        _buildQuickActionItem(
          context,
          icon: 'print',
          title: 'Print Entry',
          subtitle: 'Print a physical copy',
          onTap: () => _printEntry(context),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                size: 5.w,
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                size: 4.w,
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final content = _formatEntryForSharing();
    Clipboard.setData(ClipboardData(text: content));

    HapticFeedback.lightImpact();
    if (isBottomSheet) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry copied to clipboard'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareEntry(BuildContext context) {
    // In a real app, this would use the share package
    HapticFeedback.mediumImpact();
    if (isBottomSheet) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportAsPdf(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (isBottomSheet) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF export functionality coming soon'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportAsText(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (isBottomSheet) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text export functionality coming soon'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveAsFavorite(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved as favorite'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _generateShareableLink(BuildContext context) {
    // Generate a mock shareable link
    final link = 'https://emotionanchor.app/entry/${entryData['id']}';
    Clipboard.setData(ClipboardData(text: link));

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shareable link copied to clipboard'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _printEntry(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Print functionality coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatEntryForSharing() {
    final title = entryData['title'] ?? 'My Journal Entry';
    final content = entryData['content'] ?? entryData['preview'] ?? '';
    final mood = entryData['mood'] ?? 'neutral';
    final date = entryData['date'] ?? DateTime.now();

    return '''
$title

Date: ${_formatDate(date)}
Mood: ${_formatMood(mood)}

$content

---
Shared from EmotionAnchor Journal App
''';
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  String _formatMood(String mood) {
    return mood.substring(0, 1).toUpperCase() + mood.substring(1);
  }
}
