import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/ai_insights_panel_widget.dart';
import './widgets/entry_content_widget.dart';
import './widgets/entry_metadata_widget.dart';
import './widgets/mood_selector_widget.dart';
import './widgets/share_export_widget.dart';

class JournalEntryDetailView extends StatefulWidget {
  const JournalEntryDetailView({Key? key}) : super(key: key);

  @override
  State<JournalEntryDetailView> createState() => _JournalEntryDetailViewState();
}

class _JournalEntryDetailViewState extends State<JournalEntryDetailView>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  bool _showAIInsights = false;
  late TextEditingController _contentController;
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Entry data
  Map<String, dynamic> _entryData = {};
  String _originalContent = '';
  String _currentMood = '';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntryData();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadEntryData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _entryData = args;
        _originalContent = _entryData['content'] ?? _entryData['preview'] ?? '';
        _contentController.text = _originalContent;
        _currentMood = _entryData['mood'] ?? 'neutral';
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content:
              const Text('Do you want to save your changes before leaving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveEntry();
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _saveEntry() {
    setState(() {
      _entryData['content'] = _contentController.text;
      _entryData['mood'] = _currentMood;
      _entryData['lastModified'] = DateTime.now();
      _originalContent = _contentController.text;
      _hasUnsavedChanges = false;
      _isEditing = false;
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry saved successfully'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      // Focus on text field when entering edit mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus();
      });
    }
  }

  void _onContentChanged(String value) {
    if (!_hasUnsavedChanges && value != _originalContent) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onMoodChanged(String mood) {
    setState(() {
      _currentMood = mood;
      if (!_hasUnsavedChanges) {
        _hasUnsavedChanges = true;
      }
    });
  }

  void _toggleAIInsights() {
    setState(() {
      _showAIInsights = !_showAIInsights;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          title: Text(
            _entryData['date'] != null
                ? _formatDate(_entryData['date'] as DateTime)
                : 'Journal Entry',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (_isEditing) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    _contentController.text = _originalContent;
                    _hasUnsavedChanges = false;
                    _isEditing = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: _saveEntry,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                onPressed: _toggleEditMode,
                icon: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'share',
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        SizedBox(width: 3.w),
                        const Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'download',
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        SizedBox(width: 3.w),
                        const Text('Export'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'delete',
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Entry Content
              SliverToBoxAdapter(
                child: EntryContentWidget(
                  controller: _contentController,
                  isEditing: _isEditing,
                  onChanged: _onContentChanged,
                  entryTitle: _entryData['title'] ?? '',
                ),
              ),

              // Entry Metadata
              SliverToBoxAdapter(
                child: EntryMetadataWidget(
                  entryData: _entryData,
                  currentMood: _currentMood,
                ),
              ),

              // Mood Selector (only in edit mode)
              if (_isEditing)
                SliverToBoxAdapter(
                  child: MoodSelectorWidget(
                    selectedMood: _currentMood,
                    onMoodChanged: _onMoodChanged,
                  ),
                ),

              // AI Insights Panel
              if (_entryData['hasAiInsight'] == true)
                SliverToBoxAdapter(
                  child: AIInsightsPanelWidget(
                    entryData: _entryData,
                    isExpanded: _showAIInsights,
                    onToggle: _toggleAIInsights,
                  ),
                ),

              // Share & Export Options (only in view mode)
              if (!_isEditing)
                SliverToBoxAdapter(
                  child: ShareExportWidget(
                    entryData: _entryData,
                  ),
                ),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareEntry();
        break;
      case 'export':
        _exportEntry();
        break;
      case 'delete':
        _deleteEntry();
        break;
    }
  }

  void _shareEntry() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareExportWidget(
        entryData: _entryData,
        isBottomSheet: true,
      ),
    );
  }

  void _exportEntry() {
    // Export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export feature coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Are you sure you want to delete "${_entryData['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(
                  context, 'deleted'); // Return to dashboard with result
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Entry deleted'),
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
