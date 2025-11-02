import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const SettingsSectionWidget({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  State<SettingsSectionWidget> createState() => _SettingsSectionWidgetState();
}

class _SettingsSectionWidgetState extends State<SettingsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding:
                EdgeInsets.only(left: 4.w, right: 4.w, top: 4.w, bottom: 2.h),
            child: Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight.withAlpha(204),
              ),
            ),
          ),

          // Settings Items
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: AppTheme.dividerLight,
              indent: 4.w,
              endIndent: 4.w,
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildSettingsItem(context, item, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, Map<String, dynamic> item, int index) {
    final bool isDestructive = item['isDestructive'] == true;

    return InkWell(
      onTap: () {
        final onTap = item['onTap'];
        if (onTap != null && onTap is Function) {
          try {
            onTap();
          } catch (e) {
            // Handle any errors in onTap callback
            print('Settings item tap error: $e');
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Row(
          children: [
            // Icon
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withAlpha(26)
                    : AppTheme.primaryLight.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  item['icon'] as IconData? ?? Icons.settings,
                  size: 5.w,
                  color: isDestructive ? Colors.red : AppTheme.primaryLight,
                ),
              ),
            ),

            SizedBox(width: 3.w),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? Colors.red
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  if (item['subtitle'] != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      item['subtitle'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: 2.w),

            // Arrow Icon
            Icon(
              Icons.chevron_right,
              size: 5.w,
              color: AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}